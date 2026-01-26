"""MCP Server Manager - handles lifecycle and communication with MCP servers."""

import asyncio
import json
import logging
import os
import time
from pathlib import Path
from typing import Any

from .models import ServerConfig, ServerInfo, ServerStatus, ToolSchema

logger = logging.getLogger(__name__)


class MCPServerConnection:
    """Manages connection to a single MCP server via stdio."""

    def __init__(self, server_id: str, config: ServerConfig):
        self.server_id = server_id
        self.config = config
        self.process: asyncio.subprocess.Process | None = None
        self.status = ServerStatus.DISCONNECTED
        self.error: str | None = None
        self.tools: dict[str, ToolSchema] = {}
        self._request_id = 0
        self._pending_requests: dict[int, asyncio.Future] = {}
        self._read_task: asyncio.Task | None = None

    async def connect(self) -> bool:
        """Start the MCP server process and initialize connection."""
        if self.process is not None:
            return True

        self.status = ServerStatus.CONNECTING
        self.error = None

        try:
            # Prepare environment
            env = os.environ.copy()
            env.update(self.config.env)

            # Start the process
            self.process = await asyncio.create_subprocess_exec(
                self.config.command,
                *self.config.args,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=env,
            )

            # Start reading responses
            self._read_task = asyncio.create_task(self._read_responses())

            # Initialize MCP connection
            await self._initialize()

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
        if self._read_task:
            self._read_task.cancel()
            try:
                await self._read_task
            except asyncio.CancelledError:
                pass
            self._read_task = None

        if self.process:
            try:
                self.process.terminate()
                await asyncio.wait_for(self.process.wait(), timeout=5.0)
            except asyncio.TimeoutError:
                self.process.kill()
            except Exception:
                pass
            self.process = None

        self.status = ServerStatus.DISCONNECTED
        self.tools = {}
        self._pending_requests.clear()
        logger.info(f"Disconnected from MCP server: {self.server_id}")

    async def call_tool(self, tool_name: str, arguments: dict[str, Any]) -> Any:
        """Execute a tool and return the result."""
        if self.status != ServerStatus.CONNECTED:
            raise RuntimeError(f"Server {self.server_id} is not connected")

        response = await self._send_request(
            "tools/call",
            {"name": tool_name, "arguments": arguments},
        )

        if "error" in response:
            raise RuntimeError(response["error"].get("message", "Unknown error"))

        return response.get("result", {}).get("content", [])

    async def _initialize(self):
        """Send MCP initialize request."""
        response = await self._send_request(
            "initialize",
            {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "mcp-gateway", "version": "0.1.0"},
            },
        )

        if "error" in response:
            raise RuntimeError(f"Initialize failed: {response['error']}")

        # Send initialized notification
        await self._send_notification("notifications/initialized", {})

    async def _list_tools(self):
        """Fetch available tools from the server."""
        response = await self._send_request("tools/list", {})

        if "error" in response:
            logger.warning(f"Failed to list tools for {self.server_id}: {response['error']}")
            return

        tools = response.get("result", {}).get("tools", [])
        self.tools = {
            tool["name"]: ToolSchema(
                name=tool["name"],
                description=tool.get("description", ""),
                input_schema=tool.get("inputSchema", {}),
            )
            for tool in tools
        }
        logger.info(f"Server {self.server_id} has {len(self.tools)} tools")

    async def _send_request(self, method: str, params: dict[str, Any]) -> dict[str, Any]:
        """Send a JSON-RPC request and wait for response."""
        if not self.process or not self.process.stdin:
            raise RuntimeError("Process not running")

        self._request_id += 1
        request_id = self._request_id

        request = {
            "jsonrpc": "2.0",
            "id": request_id,
            "method": method,
            "params": params,
        }

        # Create future for response
        future: asyncio.Future = asyncio.Future()
        self._pending_requests[request_id] = future

        # Send request
        message = json.dumps(request) + "\n"
        self.process.stdin.write(message.encode())
        await self.process.stdin.drain()

        # Wait for response with timeout
        try:
            return await asyncio.wait_for(future, timeout=30.0)
        except asyncio.TimeoutError:
            self._pending_requests.pop(request_id, None)
            raise RuntimeError(f"Request {method} timed out")

    async def _send_notification(self, method: str, params: dict[str, Any]):
        """Send a JSON-RPC notification (no response expected)."""
        if not self.process or not self.process.stdin:
            raise RuntimeError("Process not running")

        notification = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
        }

        message = json.dumps(notification) + "\n"
        self.process.stdin.write(message.encode())
        await self.process.stdin.drain()

    async def _read_responses(self):
        """Background task to read responses from the server."""
        if not self.process or not self.process.stdout:
            return

        try:
            while True:
                line = await self.process.stdout.readline()
                if not line:
                    break

                try:
                    response = json.loads(line.decode())
                    request_id = response.get("id")
                    if request_id and request_id in self._pending_requests:
                        self._pending_requests.pop(request_id).set_result(response)
                except json.JSONDecodeError:
                    continue

        except asyncio.CancelledError:
            raise
        except Exception as e:
            logger.error(f"Error reading from {self.server_id}: {e}")
            self.status = ServerStatus.ERROR
            self.error = str(e)


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
