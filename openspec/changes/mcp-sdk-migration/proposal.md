# Proposal: MCP SDK Migration

## Summary

Migrate all axios MCP implementations from custom JSON-RPC handling to the official MCP Python SDK (`mcp` package for clients, `fastmcp` for servers).

## Motivation

### Problem Statement

Current axios MCP implementations use hand-rolled JSON-RPC over stdio:

| Project | Role | Current Implementation | Issues |
|---------|------|----------------------|--------|
| mcp-gateway | Client | Custom asyncio stdio | Timeouts with npx servers |
| mcp-dav | Server | Custom request handler | May have protocol gaps |
| axios-ai-mail | Server | Custom implementation | Inconsistent with spec |

This leads to:
1. **Protocol bugs** - Timeouts, connection failures with some MCP servers
2. **Maintenance burden** - Each project reimplements the same protocol
3. **Spec drift** - Custom implementations may not match MCP spec updates

### Solution

Adopt official MCP libraries:
- **Clients** (mcp-gateway): Use `mcp` package (`mcp.client.stdio`)
- **Servers** (mcp-dav, axios-ai-mail): Use `fastmcp` package

## Affected Projects

### 1. mcp-gateway (axios)

**Role**: MCP Client (connects to servers, exposes REST API)

**Current**: `pkgs/mcp-gateway/src/mcp_gateway/server_manager.py`
- Custom `MCPServerConnection` class
- Manual JSON-RPC request/response handling
- Hand-rolled stdio communication

**Target**: Use `mcp` client SDK
```python
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async with stdio_client(StdioServerParameters(command=cmd, args=args)) as (read, write):
    async with ClientSession(read, write) as session:
        await session.initialize()
        tools = await session.list_tools()
        result = await session.call_tool(name, arguments)
```

### 2. mcp-dav (axios-dav)

**Role**: MCP Server (provides calendar/contacts tools)

**Current**: `pkgs/mcp-dav/src/mcp_dav/server.py`
- Custom `MCPServer` class with `handle_request()` method
- Manual stdin/stdout JSON-RPC loop

**Target**: Use `fastmcp` server SDK
```python
from fastmcp import FastMCP

mcp = FastMCP("mcp-dav")

@mcp.tool()
def list_events(start_date: str, end_date: str) -> list[dict]:
    """List calendar events in date range."""
    return calendar.list_events(start_date, end_date)

mcp.run()
```

### 3. axios-ai-mail (axios-ai-mail)

**Role**: MCP Server (provides email tools)

**Current**: Custom MCP implementation in `mcp` subcommand

**Target**: Use `fastmcp` server SDK (same pattern as mcp-dav)

## Implementation Plan

### Phase 1: mcp-gateway (Client Migration)

1. Add `mcp` package to dependencies
2. Refactor `MCPServerConnection` to use `mcp.client.stdio`
3. Update `MCPServerManager` to use new connection class
4. Test with all configured MCP servers
5. Verify npx-based servers work (context7, filesystem, etc.)

### Phase 2: mcp-dav (Server Migration)

1. Add `fastmcp` package to dependencies
2. Rewrite server using `@mcp.tool()` decorators
3. Test with Claude Code and mcp-gateway
4. Update axios-dav flake

### Phase 3: axios-ai-mail (Server Migration)

1. Add `fastmcp` package to dependencies
2. Rewrite MCP mode using `@mcp.tool()` decorators
3. Test with Claude Code and mcp-gateway
4. Update axios-ai-mail flake

## Dependencies

### Python Packages

```toml
# For clients (mcp-gateway)
dependencies = [
    "mcp>=1.0.0",
]

# For servers (mcp-dav, axios-ai-mail)
dependencies = [
    "fastmcp>=0.1.0",
]
```

### Nix Packaging

Both `mcp` and `fastmcp` need to be available in nixpkgs or packaged in axios:
- Check nixpkgs for existing packages
- If not available, add to `pkgs/` or use `python3Packages.buildPythonPackage`

## Benefits

1. **Reliability** - Official SDK handles protocol correctly
2. **Maintainability** - Less custom code to maintain
3. **Compatibility** - Guaranteed spec compliance
4. **Features** - Access to SDK features (streaming, resources, prompts)

## Risks

1. **SDK Stability** - MCP SDK is relatively new, may have breaking changes
2. **Nix Packaging** - May need to package SDK if not in nixpkgs
3. **API Differences** - Migration may require interface changes

## Testing Requirements

- [ ] mcp-gateway connects to all 11 configured servers
- [ ] mcp-gateway handles npx-based servers without timeout
- [ ] mcp-dav tools work from Claude Code
- [ ] mcp-dav tools work from mcp-gateway REST API
- [ ] axios-ai-mail tools work from Claude Code
- [ ] axios-ai-mail tools work from mcp-gateway REST API

## References

- MCP Python SDK: https://github.com/modelcontextprotocol/python-sdk
- FastMCP: https://github.com/jlowin/fastmcp
- MCP Specification: https://modelcontextprotocol.io/
