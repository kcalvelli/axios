# Tasks: MCP SDK Migration

## Overview

Migrate axios MCP implementations to official SDK libraries.

---

## Phase 1: mcp-gateway Client Migration

### Task 1.1: Research MCP Client SDK
- [x] Review `mcp` package documentation
- [x] Understand `stdio_client` and `ClientSession` API
- [x] Check nixpkgs for `mcp` package availability (v1.25.0 available)
- [x] Determine packaging strategy if not in nixpkgs (not needed - in nixpkgs)

### Task 1.2: Update Dependencies
- [x] Add `mcp` to pyproject.toml
- [x] Update default.nix with new dependency
- [x] Verify package builds

### Task 1.3: Refactor MCPServerConnection
- [x] Replace custom stdio handling with `stdio_client`
- [x] Replace custom JSON-RPC with `ClientSession`
- [x] Update `connect()`, `disconnect()`, `call_tool()` methods
- [x] Handle connection lifecycle properly

### Task 1.4: Update MCPServerManager
- [x] Adapt to new connection interface (interface unchanged, MCPServerConnection handles SDK)
- [x] Ensure async context management works correctly
- [x] Update error handling

### Task 1.5: Test mcp-gateway
- [ ] Test with git server (native binary)
- [ ] Test with github server (native binary)
- [ ] Test with filesystem server (npx)
- [ ] Test with context7 server (npx)
- [ ] Test with axios-ai-mail server
- [ ] Test with mcp-dav server
- [ ] Verify REST API endpoints work
- [ ] Verify Orchestrator UI works

### Task 1.6: Deploy and Verify
- [ ] Commit changes
- [ ] Push to axios
- [ ] Rebuild and test on live system
- [ ] Verify Tailscale Services registration

---

## Phase 2: mcp-dav Server Migration (axios-dav repo)

### Task 2.1: Research FastMCP
- [x] Review fastmcp documentation
- [x] Understand `@mcp.tool()` decorator pattern
- [x] Check nixpkgs for `fastmcp` package (v2.14.3 available)

### Task 2.2: Update Dependencies
- [x] Add `fastmcp` to pyproject.toml
- [x] Update flake.nix (package defined inline)
- [x] Verify package builds

### Task 2.3: Rewrite Server
- [x] Create new FastMCP-based server
- [x] Migrate calendar tools (list_events, search_events, create_event, get_free_busy)
- [x] Migrate contact tools (list_contacts, search_contacts, get_contact, create_contact, update_contact, delete_contact)
- [x] Remove old custom implementation (~320 lines removed)

### Task 2.4: Test mcp-dav
- [ ] Test with Claude Code directly
- [ ] Test with mcp-gateway
- [ ] Test with mcp-cli

### Task 2.5: Update axios-dav Flake
- [x] Update package version
- [x] Commit and push (bd56206)

---

## Phase 3: axios-ai-mail Server Migration (axios-ai-mail repo)

**NOTE**: axios-ai-mail was ALREADY using the official MCP SDK (`mcp.server.fastmcp`).
No migration needed - it was built with the SDK from the start.

### Task 3.1: Research Current Implementation
- [x] Review current MCP mode implementation
- [x] Identify all MCP tools exposed (8 tools: list_accounts, search_emails, read_email, compose_email, send_email, reply_to_email, mark_read, delete_email)

### Task 3.2: Update Dependencies
- [x] Already using `mcp>=1.0.0` in pyproject.toml
- [x] Already using `mcp` in flake.nix

### Task 3.3: Verify Implementation
- [x] Already using `mcp.server.fastmcp.FastMCP`
- [x] All tools use `@mcp.tool()` decorators
- [x] No custom JSON-RPC implementation

### Task 3.4: Test axios-ai-mail
- [ ] Test with Claude Code
- [ ] Test with mcp-gateway

### Task 3.5: Update axios-ai-mail Flake
- [x] No changes needed - already using official SDK

---

## Phase 4: Documentation and Cleanup

### Task 4.1: Update Specs
- [ ] Update `openspec/specs/ai/spec.md` with SDK info
- [ ] Document MCP SDK usage pattern

### Task 4.2: Archive Proposal
- [ ] Move to `openspec/changes/archive/`

---

## Files to Modify

### axios (Phase 1)
| File | Changes |
|------|---------|
| `pkgs/mcp-gateway/pyproject.toml` | Add `mcp` dependency |
| `pkgs/mcp-gateway/default.nix` | Add `mcp` to Nix deps |
| `pkgs/mcp-gateway/src/mcp_gateway/server_manager.py` | Refactor to use SDK |

### axios-dav (Phase 2)
| File | Changes |
|------|---------|
| `pkgs/mcp-dav/pyproject.toml` | Add `fastmcp` dependency |
| `pkgs/mcp-dav/default.nix` | Add `fastmcp` to Nix deps |
| `pkgs/mcp-dav/src/mcp_dav/server.py` | Rewrite with FastMCP |

### axios-ai-mail (Phase 3)
| File | Changes |
|------|---------|
| `pyproject.toml` | Add `fastmcp` dependency |
| `default.nix` | Add `fastmcp` to Nix deps |
| MCP server module | Rewrite with FastMCP |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: mcp-gateway | 2-3 hours |
| Phase 2: mcp-dav | 2-3 hours |
| Phase 3: axios-ai-mail | 2-3 hours |
| Phase 4: Documentation | 1 hour |
| **Total** | **7-10 hours** |
