# Tasks: MCP Gateway

## Overview

Create an MCP Gateway service exposing axios MCP servers via OpenAPI REST, with an orchestrator UI for server management.

**Depends On**:
- AI Module Server/Client Refactor (#1) ✅
- Port Registry Governance (#3) ✅

**Enhances**: Open WebUI Integration (#2) - makes it useful

---

## Phase 1: Research and Design

### Task 1.1: Evaluate Implementation Options
- [ ] Review MCP SDK (Python) capabilities
- [ ] Evaluate FastAPI for REST gateway
- [ ] Research MCP stdio → HTTP bridging patterns
- [ ] Decision: FastAPI custom service vs extend mcp-cli

### Task 1.2: Design OpenAPI Schema
- [ ] Define `/api/servers` endpoints
- [ ] Define `/api/tools` endpoints
- [ ] Define error response format
- [ ] Generate OpenAPI spec document

### Task 1.3: Design Orchestrator UI
- [ ] Wireframe server management view
- [ ] Wireframe tool browser view
- [ ] Decide: SPA (React/Svelte) or server-rendered (Jinja2)
- [ ] Design mobile-responsive layout

---

## Phase 2: Core Gateway Implementation

### Task 2.1: Create Package Structure
- [ ] Create `pkgs/mcp-gateway/` directory
- [ ] Set up Python/FastAPI project
- [ ] Add to flake packages

### Task 2.2: Implement MCP Server Manager
- [ ] Load MCP server configurations
- [ ] Spawn/manage MCP server processes
- [ ] Handle server lifecycle (start/stop/restart)
- [ ] Implement health checking

### Task 2.3: Implement REST API
- [ ] `GET /api/servers` - List servers
- [ ] `GET /api/servers/{id}` - Server details
- [ ] `PATCH /api/servers/{id}` - Enable/disable
- [ ] `GET /api/tools` - List all tools
- [ ] `GET /api/tools/{server}/{tool}` - Tool schema
- [ ] `POST /api/tools/{server}/{tool}` - Execute tool

### Task 2.4: Implement MCP Protocol Bridge
- [ ] Connect to MCP servers via stdio
- [ ] Translate REST requests to MCP calls
- [ ] Handle async tool execution
- [ ] Stream results for long-running tools

---

## Phase 3: Orchestrator UI

### Task 3.1: Set Up Frontend
- [ ] Choose framework (recommend: htmx + Jinja2 for simplicity)
- [ ] Set up static file serving
- [ ] Create base layout template

### Task 3.2: Server Management UI
- [ ] List all MCP servers with status
- [ ] Toggle buttons to enable/disable
- [ ] Show connection status (connected/error)
- [ ] Display last error message

### Task 3.3: Tool Browser UI
- [ ] List tools grouped by server
- [ ] Search/filter tools
- [ ] Display tool schema (JSON Schema viewer)
- [ ] Tool testing form (generate from schema)

### Task 3.4: Activity Log
- [ ] Display recent tool calls
- [ ] Show request/response details
- [ ] Filter by server/tool

---

## Phase 4: NixOS Module

### Task 4.1: Create Module Structure
- [ ] Create `modules/ai/mcp-gateway.nix`
- [ ] Import in `modules/ai/default.nix`

### Task 4.2: Define Module Options
- [ ] `services.ai.mcpGateway.enable`
- [ ] `services.ai.mcpGateway.role` (server/client)
- [ ] `services.ai.mcpGateway.port`
- [ ] `services.ai.mcpGateway.tailscaleServe.*`
- [ ] `services.ai.mcpGateway.servers.*`
- [ ] `services.ai.mcpGateway.pwa.*`

### Task 4.3: Implement Server Role
- [ ] Systemd service for gateway
- [ ] Pass MCP server configs to gateway
- [ ] Configure Tailscale serve

### Task 4.4: Add Assertions
- [ ] PWA requires tailnetDomain
- [ ] Client role requires serverHost

---

## Phase 5: Home-Manager Module (PWA)

### Task 5.1: Create Home Module
- [ ] Create `home/ai/mcp-gateway.nix`
- [ ] Import in `home/ai/default.nix`

### Task 5.2: Implement PWA
- [ ] Desktop entry "Axios MCP Gateway"
- [ ] Icon (follow axios pattern)
- [ ] Correct StartupWMClass

---

## Phase 6: Open WebUI Integration

### Task 6.1: Research Open WebUI Functions
- [ ] Understand function definition format
- [ ] Test manual function creation
- [ ] Determine auto-generation feasibility

### Task 6.2: Generate Function Definitions
- [ ] Add endpoint: `GET /api/openwebui/functions`
- [ ] Generate Python code for each enabled tool
- [ ] Provide copy-paste UI in orchestrator

### Task 6.3: Document Integration
- [ ] Step-by-step Open WebUI setup guide
- [ ] Troubleshooting common issues

---

## Phase 7: Documentation

### Task 7.1: Update Module Documentation
- [ ] Add to `docs/MODULE_REFERENCE.md`
- [ ] Server and client configuration examples

### Task 7.2: Update AI Spec
- [ ] Add MCP Gateway to `openspec/specs/ai/spec.md`
- [ ] Document architecture

### Task 7.3: Update Port Registry
- [ ] Add port 8085/8448 to `openspec/specs/networking/ports.md`

---

## Phase 8: Testing

### Task 8.1: Unit Tests
- [ ] Test MCP server manager
- [ ] Test REST API endpoints
- [ ] Test MCP protocol bridge

### Task 8.2: Integration Tests
- [ ] Test with real MCP servers (filesystem, git)
- [ ] Test Tailscale serve
- [ ] Test Open WebUI function calling

### Task 8.3: Manual Testing
- [ ] Test orchestrator UI
- [ ] Test from mobile via Tailscale
- [ ] Test PWA on desktop

---

## Phase 9: Finalization

### Task 9.1: Code Review Checklist
- [ ] Follows axios module patterns
- [ ] Server/client pattern consistent
- [ ] Security considerations addressed
- [ ] Error handling comprehensive

### Task 9.2: Merge and Archive
- [ ] Update specs
- [ ] Archive this change directory

---

## Files to Create

| File | Purpose |
|------|---------|
| `pkgs/mcp-gateway/` | Python/FastAPI gateway package |
| `modules/ai/mcp-gateway.nix` | NixOS module |
| `home/ai/mcp-gateway.nix` | Home-manager PWA module |
| `home/resources/pwa-icons/axios-mcp-gateway.png` | PWA icon |

## Files to Modify

| File | Changes |
|------|---------|
| `modules/ai/default.nix` | Import mcp-gateway.nix |
| `home/ai/default.nix` | Import home module |
| `openspec/specs/ai/spec.md` | Document gateway |
| `openspec/specs/networking/ports.md` | Add port allocation |
| `flake.nix` | Add gateway package |

---

## Port Allocation

| Service | Local Port | Tailscale Port |
|---------|------------|----------------|
| MCP Gateway | 8085 | 8448 |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Research | 4 hours |
| Phase 2: Core Gateway | 12 hours |
| Phase 3: Orchestrator UI | 8 hours |
| Phase 4: NixOS Module | 2 hours |
| Phase 5: Home Module | 1 hour |
| Phase 6: Open WebUI | 4 hours |
| Phase 7: Documentation | 2 hours |
| Phase 8: Testing | 4 hours |
| Phase 9: Finalization | 1 hour |
| **Total** | **~38 hours** |

---

## Open Questions

1. **State persistence**: Where should enabled/disabled state be stored? NixOS config (declarative) vs runtime state file?

2. **Secret handling**: How do MCP servers that need API keys (brave-search) get them via the gateway?

3. **Concurrent requests**: How to handle multiple simultaneous tool calls to same MCP server?

4. **Tool timeouts**: What's the maximum execution time before timeout?

5. **Result size limits**: How to handle tools that return very large results?
