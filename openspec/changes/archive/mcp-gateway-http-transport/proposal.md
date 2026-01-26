# Proposal: MCP Gateway HTTP Transport

## Summary

Add native MCP HTTP/SSE transport to mcp-gateway, transforming it from a REST-only gateway into a universal protocol bridge. This enables Claude.ai Integrations, Claude Desktop, and any MCP-compatible client to access axios MCP tools alongside existing REST/OpenAPI clients.

## Motivation

### Current State

mcp-gateway currently provides:
- REST/OpenAPI interface for tools (`/tools/{server}/{tool}`)
- Dynamic OpenAPI schema (`/tools/openapi.json`)
- Web-based orchestrator UI

This works for OpenAPI clients like Open WebUI, but:
1. **Claude.ai Integrations** require MCP HTTP transport, not REST
2. **Claude Desktop** can connect to remote MCP servers via HTTP/SSE
3. **Future MCP clients** will expect standard MCP protocol

### The Opportunity

Claude.ai (with Pro/Max subscription) now supports "Integrations" - connecting to remote MCP servers. If mcp-gateway speaks MCP HTTP transport, users can:
- Use Claude.ai web interface with all 86+ axios MCP tools
- Leverage their Max subscription (no API costs)
- Access tools from any device via Tailscale

### Universal Protocol Bridge

With this change, mcp-gateway becomes a true protocol bridge:

```
                    ┌─────────────────────────────────────┐
                    │         mcp-gateway                 │
                    │    (Universal MCP Bridge)           │
                    ├─────────────────────────────────────┤
   MCP Servers      │                                     │
   (stdio)          │  ┌─────────────────────────────┐   │
                    │  │  Server Manager             │   │
   ──────────────►  │  │  - axios-ai-mail            │   │
                    │  │  - mcp-dav                  │   │
                    │  │  - git, github, filesystem  │   │
                    │  └─────────────────────────────┘   │
                    │                 │                   │
                    │     ┌───────────┴───────────┐      │
                    │     ▼                       ▼      │
                    │  ┌──────────┐      ┌────────────┐  │
   Outputs:         │  │ REST/    │      │ MCP HTTP/  │  │
                    │  │ OpenAPI  │      │ SSE        │  │
                    │  └────┬─────┘      └─────┬──────┘  │
                    └───────┼──────────────────┼─────────┘
                            │                  │
              ┌─────────────┴──┐       ┌───────┴─────────────┐
              ▼                ▼       ▼                     ▼
        ┌──────────┐    ┌──────────┐  ┌──────────┐    ┌──────────┐
        │ Open     │    │ Custom   │  │ Claude.ai│    │ Claude   │
        │ WebUI    │    │ REST     │  │ Integr.  │    │ Desktop  │
        │          │    │ Clients  │  │          │    │          │
        └──────────┘    └──────────┘  └──────────┘    └──────────┘
```

## Architecture

### MCP HTTP Transport Specification

MCP defines an HTTP transport using Server-Sent Events (SSE):
- Client connects to SSE endpoint for server-to-client messages
- Client sends requests via HTTP POST
- Messages follow JSON-RPC 2.0 format

Reference: https://spec.modelcontextprotocol.io/specification/basic/transports/#http-with-sse

### New Endpoints

```
/mcp/sse          # SSE endpoint for MCP client connections
/mcp/message      # POST endpoint for client-to-server messages
```

### Message Flow

```
Client (Claude.ai)                    mcp-gateway
       │                                   │
       │──── GET /mcp/sse ────────────────►│  (establish SSE connection)
       │◄─── SSE: endpoint event ──────────│  (provides message endpoint)
       │                                   │
       │──── POST /mcp/message ───────────►│  (initialize request)
       │◄─── SSE: initialize response ─────│
       │                                   │
       │──── POST /mcp/message ───────────►│  (tools/list request)
       │◄─── SSE: tools/list response ─────│  (returns all 86+ tools)
       │                                   │
       │──── POST /mcp/message ───────────►│  (tools/call request)
       │     {tool: "send_email", args}    │
       │◄─── SSE: tools/call response ─────│  (email sent!)
       │                                   │
```

### Implementation Approach

1. **Add MCP message handling** to mcp-gateway
   - Parse JSON-RPC 2.0 messages
   - Map MCP methods to internal server manager calls
   - Return MCP-formatted responses

2. **Implement SSE transport**
   - FastAPI/Starlette SSE support
   - Connection management per client
   - Proper event formatting

3. **Tool aggregation**
   - Aggregate tools from all enabled MCP servers
   - Present as single MCP server to clients
   - Handle tool namespacing (server_id prefix if needed)

### MCP Methods to Implement

| Method | Description |
|--------|-------------|
| `initialize` | Client handshake, capability negotiation |
| `tools/list` | Return all available tools |
| `tools/call` | Execute a tool, return result |
| `ping` | Health check |

### Tool Namespacing

To avoid conflicts between servers, tools will be namespaced:
- Internal: `axios-ai-mail/send_email`
- MCP exposed: `axios_ai_mail__send_email` or configurable

## Configuration

```nix
services.ai.mcpGateway = {
  enable = true;

  # Existing REST/OpenAPI (unchanged)
  port = 8085;

  # New: MCP HTTP transport
  mcp = {
    enable = lib.mkEnableOption "MCP HTTP/SSE transport";
    # Uses same port, different path (/mcp/*)
  };

  # Tailscale exposure (enables remote Claude.ai access)
  tailscaleServe = {
    enable = true;
    httpsPort = 8448;
  };
};
```

## Claude.ai Integration

Once deployed, users connect Claude.ai to mcp-gateway:

1. Go to Claude.ai Settings → Connectors
2. Add custom connector: `https://mcp-gateway.tailnet:8448/mcp/sse`
3. Claude.ai discovers 86+ tools
4. Use tools naturally in conversation

## Security Considerations

1. **Tailscale-only access** - MCP endpoint only accessible via tailnet
2. **No additional auth** - Tailnet membership = authorized
3. **Audit logging** - Log all MCP tool calls
4. **Rate limiting** - Optional per-client limits

## Dependencies

- **Extends**: mcp-gateway (existing)
- **Requires**: Tailscale serve for remote access
- **Enables**: Claude.ai Integrations, Claude Desktop remote

## Future: axios-ai-chat

This proposal enables a future project: **axios-ai-chat** - a purpose-built Claude chat client (separate repo) that:
- Uses Claude Max subscription (via setup-token)
- Connects to mcp-gateway via MCP HTTP
- Replaces Open WebUI wrapper with axios-native experience
- Follows axios-ai-mail / axios-dav pattern

That will be a separate proposal once this foundation is in place.

## Testing Requirements

- [ ] MCP SSE endpoint accepts connections
- [ ] Initialize handshake succeeds
- [ ] tools/list returns all enabled server tools
- [ ] tools/call executes tools correctly
- [ ] Claude.ai Integrations can connect via Tailscale
- [ ] REST/OpenAPI endpoints still work (backward compat)
- [ ] Multiple simultaneous MCP clients supported

## References

- MCP HTTP Transport Spec: https://spec.modelcontextprotocol.io/specification/basic/transports/#http-with-sse
- Claude.ai Integrations: https://docs.anthropic.com/en/docs/claude-ai-integrations
- Existing mcp-gateway proposal: `openspec/changes/mcp-gateway/`
- FastAPI SSE: https://github.com/sysid/sse-starlette
