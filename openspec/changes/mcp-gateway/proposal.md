# Proposal: MCP Gateway

## Summary

Create an MCP Gateway service that exposes axios MCP servers via OpenAPI REST endpoints, with a web-based orchestrator UI for enabling/disabling servers. This bridges the gap between the axios MCP ecosystem and tools that don't natively support MCP (Open WebUI, custom apps, mobile clients).

## Architecture Decision

**Location**: Part of axios (not a separate repo)

**Rationale**: Unlike axios-ai-mail and axios-dav which have standalone value, mcp-gateway:
- Is tightly coupled to axios's MCP configuration (`home/ai/mcp.nix`)
- Has no value without axios's MCP server definitions
- Follows the mcp-cli pattern (also in `pkgs/mcp-cli/`)
- Is infrastructure for axios, not a standalone service

**Structure**:
```
axios/
├── modules/ai/mcp-gateway.nix    # NixOS module
├── pkgs/mcp-gateway/             # FastAPI service package
└── home/ai/mcp-gateway.nix       # PWA desktop entry
```

## Motivation

### Problem Statement

The axios MCP ecosystem provides powerful tools (filesystem, git, github, journal, context7, etc.) that work excellently with Claude Code. However:

1. **Open WebUI is isolated** - It can only chat with Ollama; no access to MCP tools
2. **mcp-cli is CLI-only** - Great for Claude Code, not usable by web UIs
3. **No standard interface** - Each MCP server speaks its own stdio protocol
4. **No central management** - MCP servers are configured per-tool, not centrally orchestrated

### Solution

Build an **MCP Gateway** that:

1. **Exposes MCP tools via OpenAPI** - Any HTTP client can call tools
2. **Provides orchestrator UI** - Web interface to enable/disable MCP servers
3. **Uses Tailscale for auth** - No user credentials needed; tailnet membership = authorized
4. **Enables Open WebUI integration** - Via function calling or tool use

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Tailscale Network                        │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Open WebUI    │  │  Mobile Client  │  │   Custom App    │
│   (port 8444)   │  │                 │  │                 │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │       MCP Gateway             │
              │   (Tailscale port 8448)       │
              ├───────────────────────────────┤
              │  ┌─────────────────────────┐  │
              │  │   Orchestrator UI       │  │
              │  │   - Enable/disable MCP  │  │
              │  │   - View tool schemas   │  │
              │  │   - Test tool calls     │  │
              │  └─────────────────────────┘  │
              │                               │
              │  ┌─────────────────────────┐  │
              │  │   OpenAPI REST API      │  │
              │  │   GET  /tools           │  │
              │  │   GET  /tools/{name}    │  │
              │  │   POST /tools/{name}    │  │
              │  │   GET  /servers         │  │
              │  │   POST /servers/{id}    │  │
              │  └─────────────────────────┘  │
              └───────────────┬───────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  MCP Server:    │  │  MCP Server:    │  │  MCP Server:    │
│  filesystem     │  │  github         │  │  brave-search   │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Proposed Changes

### New Module: services.ai.mcpGateway

```nix
services.ai.mcpGateway = {
  enable = lib.mkEnableOption "MCP Gateway with OpenAPI REST interface";

  role = lib.mkOption {
    type = lib.types.enum [ "server" "client" ];
    default = "server";
    description = ''
      MCP Gateway deployment role:
      - "server": Run gateway service locally
      - "client": Access remote gateway (for UI/API)
    '';
  };

  port = lib.mkOption {
    type = lib.types.port;
    default = 8085;
    description = "Local port for MCP Gateway service";
  };

  tailscaleServe = {
    enable = lib.mkEnableOption "Expose MCP Gateway via Tailscale HTTPS";
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8448;
      description = "HTTPS port for Tailscale serve";
    };
  };

  # Server orchestration
  servers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "this MCP server";
        # Inherits config from mcp-servers-nix
      };
    });
    default = {};
    description = "MCP servers to expose via gateway";
  };

  pwa = {
    enable = lib.mkEnableOption "Generate MCP Gateway PWA desktop entry";
    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };
};
```

### OpenAPI Endpoints

```yaml
openapi: 3.0.0
info:
  title: MCP Gateway API
  version: 1.0.0

paths:
  /api/servers:
    get:
      summary: List all MCP servers
      responses:
        200:
          description: List of servers with enabled status

  /api/servers/{serverId}:
    get:
      summary: Get server details and tools
    patch:
      summary: Enable/disable server

  /api/tools:
    get:
      summary: List all available tools across enabled servers
      parameters:
        - name: search
          in: query
          description: Filter tools by name pattern

  /api/tools/{serverId}/{toolName}:
    get:
      summary: Get tool schema (JSON Schema)
    post:
      summary: Execute tool
      requestBody:
        content:
          application/json:
            schema:
              type: object
              description: Tool arguments
      responses:
        200:
          description: Tool result
```

### Orchestrator UI Features

1. **Server Management**
   - List all configured MCP servers
   - Toggle enable/disable per server
   - View server status (connected/error)

2. **Tool Browser**
   - Browse all available tools
   - View tool schemas
   - Test tool execution with form UI

3. **Activity Log**
   - Recent tool calls
   - Errors and warnings

4. **Open WebUI Integration**
   - Generate Open WebUI function definitions
   - Copy-paste Python code for each tool

## Port Allocation

| Service | Local Port | Tailscale Port |
|---------|------------|----------------|
| MCP Gateway | 8085 | 8448 |

(Updates to `openspec/specs/networking/ports.md`)

## Implementation Options

### Option A: Custom Python/FastAPI Service

Build from scratch using FastAPI:
- Full control over design
- More development effort
- Can integrate directly with mcp-servers-nix

### Option B: Extend mcp-cli

Add HTTP server mode to mcp-cli:
- Leverages existing MCP connection logic
- Bun/TypeScript stack
- May be simpler

### Option C: Use Existing MCP HTTP Transport

MCP spec includes HTTP transport option:
- Standard-compliant
- May need adaptation for gateway pattern

**Recommendation**: Option A (FastAPI) - most flexible, Python ecosystem works well with NixOS, can use existing MCP SDK.

## Open WebUI Integration

Once MCP Gateway exists, Open WebUI can use tools via:

1. **Open WebUI Functions** (immediate)
   - Define Python functions that call MCP Gateway API
   - Each function wraps one MCP tool

2. **Ollama Tool Calling** (future)
   - When Ollama supports tool/function calling
   - Tools automatically available to models

Example Open WebUI function:
```python
async def read_file(path: str) -> str:
    """Read a file from the filesystem."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://edge.tailnet:8448/api/tools/filesystem/read_file",
            json={"path": path}
        )
        return response.json()["content"]
```

## Dependencies

- **Requires**: AI Module (#1) ✅
- **Requires**: Port Registry (#3) ✅
- **Enhances**: Open WebUI (#2) - makes it actually useful
- **Uses**: mcp-servers-nix (existing)

## Testing Requirements

- [ ] Gateway starts and connects to MCP servers
- [ ] OpenAPI endpoints return correct schemas
- [ ] Tool execution works via REST
- [ ] Orchestrator UI can enable/disable servers
- [ ] Tailscale serve exposes gateway correctly
- [ ] Open WebUI can call tools via gateway

## Security Considerations

1. **Tailscale-only access** - No public exposure, tailnet membership required
2. **No stored credentials** - Gateway doesn't store API keys; uses same secret mechanism as direct MCP
3. **Audit logging** - Log all tool calls for review
4. **Read-only option** - Some deployments may want read-only tool access

## Future Enhancements

- Tool result caching
- Rate limiting per tool
- Tool composition (chain multiple tools)
- WebSocket streaming for long-running tools
- Mobile-optimized orchestrator UI

## References

- MCP Specification: https://modelcontextprotocol.io/
- mcp-servers-nix: axios input for MCP server packages
- Open WebUI Functions: https://docs.openwebui.com/features/functions/
