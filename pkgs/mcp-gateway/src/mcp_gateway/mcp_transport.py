"""MCP Streamable HTTP Transport for mcp-gateway.

Implements the MCP Streamable HTTP transport specification (2025-06-18),
allowing Claude.ai Integrations, Claude Desktop, and other MCP clients
to connect to the gateway.

Reference: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports
"""

import json
import logging
import secrets
import uuid
from dataclasses import dataclass, field
from typing import Any

from fastapi import APIRouter, HTTPException, Request, Response
from fastapi.responses import JSONResponse
from sse_starlette.sse import EventSourceResponse

logger = logging.getLogger(__name__)

# MCP Protocol version we support
MCP_PROTOCOL_VERSION = "2025-06-18"

# Server capabilities we advertise
SERVER_INFO = {
    "name": "mcp-gateway",
    "version": "0.1.0",
}

SERVER_CAPABILITIES = {
    "tools": {},  # We support tools
}


@dataclass
class MCPSession:
    """Represents an active MCP client session."""

    session_id: str
    protocol_version: str = MCP_PROTOCOL_VERSION
    initialized: bool = False


# Active sessions (in production, consider Redis or similar)
_sessions: dict[str, MCPSession] = {}


def create_router(get_manager):
    """
    Create the MCP transport router.

    Args:
        get_manager: Callable that returns the MCPServerManager instance
    """
    router = APIRouter(prefix="/mcp", tags=["MCP Transport"])

    def _get_session(request: Request) -> MCPSession | None:
        """Get session from request headers."""
        session_id = request.headers.get("Mcp-Session-Id")
        if session_id:
            return _sessions.get(session_id)
        return None

    def _create_session() -> MCPSession:
        """Create a new MCP session."""
        session_id = secrets.token_urlsafe(32)
        session = MCPSession(session_id=session_id)
        _sessions[session_id] = session
        return session

    def _jsonrpc_response(id: Any, result: Any) -> dict:
        """Create a JSON-RPC 2.0 response."""
        return {
            "jsonrpc": "2.0",
            "id": id,
            "result": result,
        }

    def _jsonrpc_error(id: Any, code: int, message: str, data: Any = None) -> dict:
        """Create a JSON-RPC 2.0 error response."""
        error = {"code": code, "message": message}
        if data is not None:
            error["data"] = data
        return {
            "jsonrpc": "2.0",
            "id": id,
            "error": error,
        }

    async def _handle_initialize(request_id: Any, params: dict) -> tuple[dict, MCPSession]:
        """Handle initialize request."""
        # Create new session
        session = _create_session()

        # Get client info
        client_info = params.get("clientInfo", {})
        logger.info(f"MCP client connecting: {client_info.get('name', 'unknown')}")

        # Negotiate protocol version
        client_version = params.get("protocolVersion", MCP_PROTOCOL_VERSION)
        # For now, we only support our version
        session.protocol_version = MCP_PROTOCOL_VERSION

        result = {
            "protocolVersion": session.protocol_version,
            "capabilities": SERVER_CAPABILITIES,
            "serverInfo": SERVER_INFO,
        }

        return _jsonrpc_response(request_id, result), session

    async def _handle_initialized(session: MCPSession) -> None:
        """Handle initialized notification."""
        session.initialized = True
        logger.info(f"MCP session initialized: {session.session_id[:8]}...")

    async def _handle_tools_list(request_id: Any) -> dict:
        """Handle tools/list request."""
        manager = get_manager()
        if not manager:
            return _jsonrpc_error(request_id, -32603, "Server manager not initialized")

        tools = []
        for server_id, schema in manager.get_all_tools():
            # Namespace tool name to avoid conflicts
            namespaced_name = f"{server_id}__{schema.name}"

            tool = {
                "name": namespaced_name,
                "description": f"[{server_id}] {schema.description}",
                "inputSchema": schema.input_schema,
            }
            tools.append(tool)

        logger.debug(f"Returning {len(tools)} tools")
        return _jsonrpc_response(request_id, {"tools": tools})

    async def _handle_tools_call(request_id: Any, params: dict) -> dict:
        """Handle tools/call request."""
        manager = get_manager()
        if not manager:
            return _jsonrpc_error(request_id, -32603, "Server manager not initialized")

        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})

        # Parse namespaced tool name (server_id__tool_name)
        if "__" not in tool_name:
            return _jsonrpc_error(
                request_id,
                -32602,
                f"Invalid tool name format: {tool_name}. Expected: server_id__tool_name",
            )

        server_id, actual_tool_name = tool_name.split("__", 1)

        try:
            result = await manager.call_tool(server_id, actual_tool_name, arguments)

            # Format result as MCP content
            content = []
            if isinstance(result, list):
                # Result is already MCP content format
                content = result
            elif isinstance(result, str):
                content = [{"type": "text", "text": result}]
            else:
                content = [{"type": "text", "text": json.dumps(result)}]

            return _jsonrpc_response(request_id, {"content": content})

        except Exception as e:
            logger.error(f"Tool call failed: {e}")
            return _jsonrpc_error(request_id, -32603, str(e))

    async def _handle_ping(request_id: Any) -> dict:
        """Handle ping request."""
        return _jsonrpc_response(request_id, {})

    async def _handle_message(
        message: dict, session: MCPSession | None
    ) -> tuple[dict | None, MCPSession | None, int]:
        """
        Handle a JSON-RPC message.

        Returns:
            Tuple of (response, session, http_status)
        """
        jsonrpc = message.get("jsonrpc")
        if jsonrpc != "2.0":
            return (
                _jsonrpc_error(None, -32600, "Invalid JSON-RPC version"),
                session,
                400,
            )

        method = message.get("method")
        params = message.get("params", {})
        request_id = message.get("id")  # None for notifications

        # Handle notifications (no response expected)
        if request_id is None:
            if method == "notifications/initialized":
                if session:
                    await _handle_initialized(session)
                return None, session, 202
            elif method == "notifications/cancelled":
                logger.debug("Received cancellation notification")
                return None, session, 202
            else:
                logger.debug(f"Received notification: {method}")
                return None, session, 202

        # Handle requests
        if method == "initialize":
            response, new_session = await _handle_initialize(request_id, params)
            return response, new_session, 200

        # All other methods require an initialized session
        if not session:
            return (
                _jsonrpc_error(request_id, -32600, "Session required"),
                None,
                400,
            )

        if method == "ping":
            return await _handle_ping(request_id), session, 200
        elif method == "tools/list":
            return await _handle_tools_list(request_id), session, 200
        elif method == "tools/call":
            return await _handle_tools_call(request_id, params), session, 200
        else:
            return (
                _jsonrpc_error(request_id, -32601, f"Method not found: {method}"),
                session,
                200,
            )

    @router.post("")
    async def mcp_post(request: Request):
        """
        Handle MCP messages via POST.

        This is the main endpoint for client-to-server communication.
        """
        # Validate protocol version header (optional but recommended)
        protocol_version = request.headers.get("MCP-Protocol-Version")
        if protocol_version and protocol_version != MCP_PROTOCOL_VERSION:
            logger.warning(f"Client using protocol version: {protocol_version}")

        # Get existing session
        session = _get_session(request)

        # Parse JSON-RPC message
        try:
            message = await request.json()
        except Exception as e:
            return JSONResponse(
                content=_jsonrpc_error(None, -32700, f"Parse error: {e}"),
                status_code=400,
            )

        # Handle the message
        response, new_session, status = await _handle_message(message, session)

        # Build HTTP response
        if response is None:
            # Notification - return 202 Accepted
            return Response(status_code=status)

        headers = {}

        # Include session ID in response
        if new_session:
            headers["Mcp-Session-Id"] = new_session.session_id
        elif session:
            headers["Mcp-Session-Id"] = session.session_id

        return JSONResponse(content=response, status_code=status, headers=headers)

    @router.get("")
    async def mcp_get(request: Request):
        """
        Handle SSE stream for server-initiated messages.

        This allows the server to send notifications/requests to the client.
        Currently returns 405 as we don't have server-initiated messages.
        """
        # For now, we don't support server-initiated messages
        # This could be extended later for things like progress updates
        raise HTTPException(
            status_code=405,
            detail="Server-initiated SSE stream not supported",
        )

    @router.delete("")
    async def mcp_delete(request: Request):
        """
        Handle session termination.
        """
        session = _get_session(request)
        if session:
            del _sessions[session.session_id]
            logger.info(f"Session terminated: {session.session_id[:8]}...")
            return Response(status_code=204)
        else:
            raise HTTPException(status_code=404, detail="Session not found")

    return router
