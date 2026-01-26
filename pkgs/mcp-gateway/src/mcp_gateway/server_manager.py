"""MCP Server Manager - handles lifecycle and communication with MCP servers.

Uses the official MCP Python SDK for protocol compliance.
"""

import asyncio
import json
import logging
import os
from pathlib import Path
from typing import Any

from mcp import ClientSession
from mcp.client.stdio import StdioServerParameters, stdio_client
from mcp.types import CallToolResult, TextContent

from .models import ServerConfig, ServerInfo, ServerStatus, ToolSchema

logger = logging.getLogger(__name__)


class MCPServerConnection:
    """Manages connection to a single MCP server via stdio using MCP SDK."""

    def __init__(self, server_id: str, config: ServerConfig):
        self.server_id = server_id
        self.config = config
        self.status = ServerStatus.DISCONNECTED
        self.error: str | None = None
        self.tools: dict[str, ToolSchema] = {}
        # SDK context managers
        self._stdio_context: Any = None
        self._session_context: Any = None
        self._session: ClientSession | None = None
        self._read_stream: Any = None
        self._write_stream: Any = None

    async def connect(self) -> bool:
        """Start the MCP server process and initialize connection."""
        if self._session is not None:
            return True

        self.status = ServerStatus.CONNECTING
        self.error = None

        try:
            # Prepare environment - merge with current env
            env = os.environ.copy()
            env.update(self.config.env)

            # Create server parameters
            server_params = StdioServerParameters(
                command=self.config.command,
                args=self.config.args,
                env=env,
            )

            # Enter stdio_client context manager
            self._stdio_context = stdio_client(server_params)
            self._read_stream, self._write_stream = await self._stdio_context.__aenter__()

            # Enter ClientSession context manager
            self._session_context = ClientSession(self._read_stream, self._write_stream)
            self._session = await self._session_context.__aenter__()

            # Initialize MCP connection
            await self._session.initialize()

            # List available tools
            await self._list_tools()

            self.status = ServerStatus.CONNECTED
            logger.info(f"Connected to MCP server: {self.server_id}")
            return True

        except Exception as e:
            self.status = ServerStatus.ERROR
            self.error = str(e)
            logger.error(f"Failed to connect to {self.server_id}: {e}")
            await self.disconnect()
            return False

    async def disconnect(self):
        """Stop the MCP server process."""
        # Exit session context
        if self._session_context:
            try:
                await self._session_context.__aexit__(None, None, None)
            except Exception as e:
                logger.debug(f"Error closing session for {self.server_id}: {e}")
            self._session_context = None
            self._session = None

        # Exit stdio context
        if self._stdio_context:
            try:
                await self._stdio_context.__aexit__(None, None, None)
            except Exception as e:
                logger.debug(f"Error closing stdio for {self.server_id}: {e}")
            self._stdio_context = None
            self._read_stream = None
            self._write_stream = None

        self.status = ServerStatus.DISCONNECTED
        self.tools = {}
        logger.info(f"Disconnected from MCP server: {self.server_id}")

    async def call_tool(self, tool_name: str, arguments: dict[str, Any]) -> Any:
        """Execute a tool and return the result."""
        if self.status != ServerStatus.CONNECTED or self._session is None:
            raise RuntimeError(f"Server {self.server_id} is not connected")

        try:
            result: CallToolResult = await self._session.call_tool(tool_name, arguments)

            # Extract content from result
            content_list = []
            for content in result.content:
                if isinstance(content, TextContent):
                    content_list.append({"type": "text", "text": content.text})
                else:
                    # Handle other content types
                    content_list.append({"type": content.type, "data": str(content)})

            return content_list

        except Exception as e:
            raise RuntimeError(f"Tool call failed: {e}") from e

    async def _list_tools(self):
        """Fetch available tools from the server."""
        if self._session is None:
            return

        try:
            result = await self._session.list_tools()

            self.tools = {
                tool.name: ToolSchema(
                    name=tool.name,
                    description=tool.description or "",
                    input_schema=tool.inputSchema if hasattr(tool, "inputSchema") else {},
                )
                for tool in result.tools
            }
            logger.info(f"Server {self.server_id} has {len(self.tools)} tools")

        except Exception as e:
            logger.warning(f"Failed to list tools for {self.server_id}: {e}")


class MCPServerManager:
    """Manages multiple MCP server connections."""

    def __init__(self, config_path: str | None = None):
        self.servers: dict[str, MCPServerConnection] = {}
        self.enabled_servers: set[str] = set()
        self.config_path = config_path or os.path.expanduser("~/.config/mcp/mcp_servers.json")
        self._configs: dict[str, ServerConfig] = {}

    async def load_config(self):
        """Load MCP server configuration from file."""
        try:
            config_file = Path(self.config_path)
            if not config_file.exists():
                logger.warning(f"Config file not found: {self.config_path}")
                return

            with open(config_file) as f:
                data = json.load(f)

            mcp_servers = data.get("mcpServers", {})
            for server_id, config in mcp_servers.items():
                self._configs[server_id] = ServerConfig(
                    command=config.get("command", ""),
                    args=config.get("args", []),
                    env=config.get("env", {}),
                )

            logger.info(f"Loaded {len(self._configs)} server configurations")

        except Exception as e:
            logger.error(f"Failed to load config: {e}")

    def get_server_ids(self) -> list[str]:
        """Get list of all configured server IDs."""
        return list(self._configs.keys())

    def get_server_info(self, server_id: str) -> ServerInfo | None:
        """Get information about a specific server."""
        if server_id not in self._configs:
            return None

        conn = self.servers.get(server_id)
        return ServerInfo(
            id=server_id,
            name=server_id,
            status=conn.status if conn else ServerStatus.DISCONNECTED,
            enabled=server_id in self.enabled_servers,
            tools=list(conn.tools.keys()) if conn else [],
            error=conn.error if conn else None,
        )

    def get_all_servers(self) -> list[ServerInfo]:
        """Get information about all configured servers."""
        return [
            self.get_server_info(server_id)
            for server_id in self._configs
            if self.get_server_info(server_id) is not None
        ]

    async def enable_server(self, server_id: str) -> bool:
        """Enable and connect to a server."""
        if server_id not in self._configs:
            return False

        if server_id in self.enabled_servers:
            return True

        self.enabled_servers.add(server_id)

        # Create connection if doesn't exist
        if server_id not in self.servers:
            self.servers[server_id] = MCPServerConnection(
                server_id, self._configs[server_id]
            )

        # Connect
        return await self.servers[server_id].connect()

    async def disable_server(self, server_id: str) -> bool:
        """Disable and disconnect from a server."""
        if server_id not in self._configs:
            return False

        self.enabled_servers.discard(server_id)

        if server_id in self.servers:
            await self.servers[server_id].disconnect()

        return True

    def get_all_tools(self) -> list[tuple[str, ToolSchema]]:
        """Get all tools from all enabled servers."""
        tools = []
        for server_id in self.enabled_servers:
            conn = self.servers.get(server_id)
            if conn and conn.status == ServerStatus.CONNECTED:
                for tool in conn.tools.values():
                    tools.append((server_id, tool))
        return tools

    def get_tool_schema(self, server_id: str, tool_name: str) -> ToolSchema | None:
        """Get schema for a specific tool."""
        conn = self.servers.get(server_id)
        if conn and conn.status == ServerStatus.CONNECTED:
            return conn.tools.get(tool_name)
        return None

    async def call_tool(
        self, server_id: str, tool_name: str, arguments: dict[str, Any]
    ) -> Any:
        """Execute a tool on a server."""
        conn = self.servers.get(server_id)
        if not conn:
            raise RuntimeError(f"Server {server_id} not found")
        if conn.status != ServerStatus.CONNECTED:
            raise RuntimeError(f"Server {server_id} is not connected")
        if tool_name not in conn.tools:
            raise RuntimeError(f"Tool {tool_name} not found on server {server_id}")

        return await conn.call_tool(tool_name, arguments)

    async def shutdown(self):
        """Disconnect from all servers."""
        for conn in self.servers.values():
            await conn.disconnect()
        self.servers.clear()
        self.enabled_servers.clear()
