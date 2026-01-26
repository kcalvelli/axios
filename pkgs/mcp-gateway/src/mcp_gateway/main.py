"""MCP Gateway - FastAPI application exposing MCP servers via REST."""

import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from .models import (
    ServerInfo,
    ServerToggleRequest,
    ToolCallRequest,
    ToolCallResponse,
    ToolInfo,
    ToolSchema,
)
from .server_manager import MCPServerManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Global server manager
manager: MCPServerManager | None = None

# Background task for auto-enable
_auto_enable_task: asyncio.Task | None = None


async def _auto_enable_servers(server_ids: list[str]):
    """Background task to auto-enable servers without blocking startup."""
    global manager
    if not manager:
        return

    for server_id in server_ids:
        server_id = server_id.strip()
        if server_id and server_id in manager.get_server_ids():
            logger.info(f"Auto-enabling server: {server_id}")
            try:
                await manager.enable_server(server_id)
            except Exception as e:
                logger.error(f"Failed to auto-enable {server_id}: {e}")

    logger.info("Auto-enable complete")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - initialize and cleanup."""
    global manager, _auto_enable_task

    config_path = os.environ.get(
        "MCP_GATEWAY_CONFIG", os.path.expanduser("~/.config/mcp/mcp_servers.json")
    )
    manager = MCPServerManager(config_path)
    await manager.load_config()

    # Auto-enable servers in background (non-blocking)
    auto_enable = os.environ.get("MCP_GATEWAY_AUTO_ENABLE", "").split(",")
    auto_enable = [s.strip() for s in auto_enable if s.strip()]
    if auto_enable:
        logger.info(f"Starting background auto-enable for: {auto_enable}")
        _auto_enable_task = asyncio.create_task(_auto_enable_servers(auto_enable))

    yield

    # Cancel auto-enable task if still running
    if _auto_enable_task and not _auto_enable_task.done():
        _auto_enable_task.cancel()
        try:
            await _auto_enable_task
        except asyncio.CancelledError:
            pass

    # Cleanup
    if manager:
        await manager.shutdown()


app = FastAPI(
    title="MCP Gateway",
    description="REST API gateway for Model Context Protocol servers",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS middleware for Open WebUI and other browser-based clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for local development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Templates directory (will be set by Nix)
templates_dir = Path(__file__).parent / "templates"
if templates_dir.exists():
    templates = Jinja2Templates(directory=str(templates_dir))
else:
    templates = None


# =============================================================================
# API Endpoints
# =============================================================================


@app.get("/api/servers", response_model=list[ServerInfo])
async def list_servers():
    """List all configured MCP servers."""
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")
    return manager.get_all_servers()


@app.get("/api/servers/{server_id}", response_model=ServerInfo)
async def get_server(server_id: str):
    """Get information about a specific server."""
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")

    info = manager.get_server_info(server_id)
    if not info:
        raise HTTPException(status_code=404, detail=f"Server {server_id} not found")
    return info


@app.patch("/api/servers/{server_id}", response_model=ServerInfo)
async def toggle_server(server_id: str, request: ServerToggleRequest):
    """Enable or disable a server."""
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")

    if server_id not in manager.get_server_ids():
        raise HTTPException(status_code=404, detail=f"Server {server_id} not found")

    if request.enabled:
        success = await manager.enable_server(server_id)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to enable server")
    else:
        await manager.disable_server(server_id)

    info = manager.get_server_info(server_id)
    if not info:
        raise HTTPException(status_code=404, detail=f"Server {server_id} not found")
    return info


@app.get("/api/tools", response_model=list[ToolInfo])
async def list_tools(search: str | None = None):
    """List all available tools from enabled servers."""
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")

    tools = []
    for server_id, schema in manager.get_all_tools():
        if search and search.lower() not in schema.name.lower():
            continue
        tools.append(
            ToolInfo(
                server_id=server_id,
                name=schema.name,
                description=schema.description,
            )
        )
    return tools


@app.get("/api/tools/{server_id}/{tool_name}", response_model=ToolSchema)
async def get_tool_schema(server_id: str, tool_name: str):
    """Get the JSON schema for a tool."""
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")

    schema = manager.get_tool_schema(server_id, tool_name)
    if not schema:
        raise HTTPException(
            status_code=404, detail=f"Tool {tool_name} not found on server {server_id}"
        )
    return schema


@app.post("/api/tools/{server_id}/{tool_name}", response_model=ToolCallResponse)
async def call_tool(server_id: str, tool_name: str, request: ToolCallRequest):
    """Execute a tool and return the result."""
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")

    start_time = time.time()

    try:
        result = await manager.call_tool(server_id, tool_name, request.arguments)
        duration_ms = (time.time() - start_time) * 1000

        return ToolCallResponse(
            success=True,
            result=result,
            duration_ms=duration_ms,
        )
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.error(f"Tool call failed: {e}")
        return ToolCallResponse(
            success=False,
            error=str(e),
            duration_ms=duration_ms,
        )


# =============================================================================
# Open WebUI Integration
# =============================================================================


@app.get("/api/openwebui/functions")
async def generate_openwebui_functions():
    """Generate Open WebUI function definitions for all enabled tools."""
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")

    functions = []
    for server_id, schema in manager.get_all_tools():
        func_code = _generate_openwebui_function(server_id, schema)
        functions.append(
            {
                "server_id": server_id,
                "tool_name": schema.name,
                "description": schema.description,
                "python_code": func_code,
            }
        )
    return functions


def _generate_openwebui_function(server_id: str, schema: ToolSchema) -> str:
    """Generate Python code for an Open WebUI function."""
    # Extract parameters from input schema
    properties = schema.input_schema.get("properties", {})
    required = schema.input_schema.get("required", [])

    # Build function signature
    params = []
    for name, prop in properties.items():
        param_type = _json_type_to_python(prop.get("type", "any"))
        if name in required:
            params.append(f"{name}: {param_type}")
        else:
            default = prop.get("default", "None")
            if isinstance(default, str):
                default = f'"{default}"'
            params.append(f"{name}: {param_type} = {default}")

    params_str = ", ".join(params)

    # Build arguments dict
    args_items = [f'"{name}": {name}' for name in properties.keys()]
    args_str = ", ".join(args_items)

    return f'''async def {schema.name}({params_str}) -> str:
    """
    {schema.description}

    Generated by MCP Gateway for server: {server_id}
    """
    import httpx

    gateway_url = "http://localhost:8085"  # Update with your gateway URL

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{{gateway_url}}/api/tools/{server_id}/{schema.name}",
            json={{"arguments": {{{args_str}}}}},
            timeout=30.0,
        )
        data = response.json()

        if data.get("success"):
            return str(data.get("result", ""))
        else:
            return f"Error: {{data.get('error', 'Unknown error')}}"
'''


def _json_type_to_python(json_type: str) -> str:
    """Convert JSON Schema type to Python type hint."""
    type_map = {
        "string": "str",
        "number": "float",
        "integer": "int",
        "boolean": "bool",
        "array": "list",
        "object": "dict",
    }
    return type_map.get(json_type, "Any")


# =============================================================================
# Web UI (Orchestrator)
# =============================================================================


@app.get("/", response_class=HTMLResponse)
async def ui_home(request: Request):
    """Render the orchestrator UI."""
    if not templates:
        return HTMLResponse(
            content="<h1>MCP Gateway</h1><p>Templates not configured. API available at /api/</p>"
        )

    servers = manager.get_all_servers() if manager else []
    tools_count = len(manager.get_all_tools()) if manager else 0

    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "servers": servers,
            "tools_count": tools_count,
        },
    )


@app.get("/servers", response_class=HTMLResponse)
async def ui_servers(request: Request):
    """Render servers management page."""
    if not templates:
        return HTMLResponse(content="Templates not configured")

    servers = manager.get_all_servers() if manager else []
    return templates.TemplateResponse(
        "servers.html",
        {
            "request": request,
            "servers": servers,
        },
    )


@app.get("/tools", response_class=HTMLResponse)
async def ui_tools(request: Request):
    """Render tools browser page."""
    if not templates:
        return HTMLResponse(content="Templates not configured")

    tools = []
    if manager:
        for server_id, schema in manager.get_all_tools():
            tools.append(
                {
                    "server_id": server_id,
                    "name": schema.name,
                    "description": schema.description,
                    "schema": schema.input_schema,
                }
            )

    return templates.TemplateResponse(
        "tools.html",
        {
            "request": request,
            "tools": tools,
        },
    )


# =============================================================================
# Health Check
# =============================================================================


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "servers_configured": len(manager.get_server_ids()) if manager else 0,
        "servers_enabled": len(manager.enabled_servers) if manager else 0,
    }


# =============================================================================
# Dynamic Tool Endpoints (OpenAPI-compatible for Open WebUI)
# =============================================================================


@app.post("/tools/{server_id}/{tool_name}")
async def execute_tool(server_id: str, tool_name: str, request: Request):
    """
    Execute an MCP tool directly.

    This endpoint provides OpenAPI-compatible tool access for Open WebUI
    and other clients that expect individual tool endpoints.
    """
    if not manager:
        raise HTTPException(status_code=503, detail="Server manager not initialized")

    # Parse request body - accept both direct args and wrapped format
    try:
        body = await request.json()
    except Exception:
        body = {}

    # Support both {"arguments": {...}} and direct {...} formats
    if "arguments" in body:
        arguments = body["arguments"]
    else:
        arguments = body

    start_time = time.time()

    try:
        result = await manager.call_tool(server_id, tool_name, arguments)
        duration_ms = (time.time() - start_time) * 1000

        # Return result directly for OpenAPI compatibility
        # Open WebUI expects the result, not a wrapper
        return {"result": result, "success": True, "duration_ms": duration_ms}
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        logger.error(f"Tool call failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Dynamic OpenAPI Schema Generation
# =============================================================================


def _generate_tool_openapi_schema() -> dict:
    """
    Generate a dynamic OpenAPI schema with individual operations for each MCP tool.

    This allows Open WebUI and other OpenAPI clients to discover and call
    each tool as a separate endpoint with proper parameter schemas.
    """
    if not manager:
        return get_openapi(
            title="MCP Gateway",
            version="0.1.0",
            description="REST API gateway for Model Context Protocol servers",
            routes=app.routes,
        )

    # Start with base paths for gateway management
    paths = {
        "/health": {
            "get": {
                "summary": "Health Check",
                "operationId": "health_check",
                "responses": {"200": {"description": "Gateway health status"}},
                "tags": ["Gateway"],
            }
        },
    }

    # Add tool-specific paths
    for server_id, schema in manager.get_all_tools():
        path = f"/tools/{server_id}/{schema.name}"
        operation_id = f"{server_id}_{schema.name}".replace("-", "_")

        # Build request body schema from tool's input schema
        request_schema = {
            "type": "object",
            "properties": schema.input_schema.get("properties", {}),
        }
        if "required" in schema.input_schema:
            request_schema["required"] = schema.input_schema["required"]

        paths[path] = {
            "post": {
                "summary": schema.name.replace("_", " ").title(),
                "description": schema.description,
                "operationId": operation_id,
                "tags": [server_id],
                "requestBody": {
                    "required": bool(schema.input_schema.get("required")),
                    "content": {
                        "application/json": {
                            "schema": request_schema,
                        }
                    },
                },
                "responses": {
                    "200": {
                        "description": "Tool execution result",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "object",
                                    "properties": {
                                        "result": {"description": "Tool output"},
                                        "success": {"type": "boolean"},
                                        "duration_ms": {"type": "number"},
                                    },
                                }
                            }
                        },
                    },
                    "500": {"description": "Tool execution error"},
                },
            }
        }

    return {
        "openapi": "3.1.0",
        "info": {
            "title": "MCP Gateway - Tool API",
            "description": "Dynamic API exposing MCP server tools. Each tool is available as a separate endpoint.",
            "version": "0.1.0",
        },
        "paths": paths,
    }


@app.get("/openapi.json", include_in_schema=False)
async def custom_openapi():
    """Serve dynamic OpenAPI schema with per-tool endpoints."""
    return JSONResponse(content=_generate_tool_openapi_schema())


def main():
    """Run the gateway server."""
    import uvicorn

    host = os.environ.get("MCP_GATEWAY_HOST", "127.0.0.1")
    port = int(os.environ.get("MCP_GATEWAY_PORT", "8085"))

    uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    main()
