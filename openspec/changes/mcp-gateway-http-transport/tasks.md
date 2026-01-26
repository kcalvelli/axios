# Tasks: MCP Gateway HTTP Transport

## Phase 1: MCP Protocol Implementation

- [ ] **1.1 Research MCP HTTP Transport spec**
  - Read https://spec.modelcontextprotocol.io/specification/basic/transports/#http-with-sse
  - Understand message format, SSE event types
  - Document required methods (initialize, tools/list, tools/call, ping)

- [ ] **1.2 Add SSE endpoint to mcp-gateway**
  - Add `sse-starlette` or equivalent dependency
  - Create `/mcp/sse` endpoint for SSE connections
  - Implement connection management (track active clients)

- [ ] **1.3 Add message endpoint**
  - Create `/mcp/message` POST endpoint
  - Parse JSON-RPC 2.0 messages
  - Route to appropriate handler

- [ ] **1.4 Implement MCP methods**
  - `initialize` - Return server capabilities
  - `tools/list` - Aggregate tools from all enabled servers
  - `tools/call` - Route to server manager, return result
  - `ping` - Health check

## Phase 2: Tool Aggregation

- [ ] **2.1 Design tool namespacing**
  - Decide format: `server__tool` vs `server/tool` vs flat
  - Handle potential name collisions
  - Document approach

- [ ] **2.2 Implement tool aggregation**
  - Collect tools from all enabled MCP servers
  - Apply namespacing
  - Cache tool list (refresh on server enable/disable)

- [ ] **2.3 Map tool calls to servers**
  - Parse namespaced tool name
  - Route to correct server
  - Return MCP-formatted result

## Phase 3: Testing & Integration

- [ ] **3.1 Local testing**
  - Test with MCP Inspector or similar
  - Verify all methods work
  - Test multiple concurrent clients

- [ ] **3.2 Claude.ai Integration testing**
  - Expose via Tailscale serve
  - Add as custom connector in Claude.ai
  - Verify tool discovery
  - Test tool execution

- [ ] **3.3 Backward compatibility**
  - Verify REST/OpenAPI endpoints still work
  - Verify Open WebUI integration unchanged
  - Verify orchestrator UI works

## Phase 4: Documentation & Finalization

- [ ] **4.1 Update specs**
  - Update `openspec/specs/ai/spec.md` with MCP HTTP transport
  - Document Claude.ai integration steps
  - Update mcp-gateway README

- [ ] **4.2 Update NixOS module**
  - Add `mcp.enable` option
  - Ensure Tailscale serve configured correctly

- [ ] **4.3 Archive proposal**
  - Move to `openspec/changes/archive/`
  - Update changelog

## Dependencies

- mcp-gateway core (complete)
- Tailscale serve (complete)
- sse-starlette or equivalent (to add)

## Notes

- Keep REST/OpenAPI fully functional - this is additive
- Consider: Should MCP and REST share the same port or separate?
- Future: axios-ai-chat will be primary consumer of MCP HTTP transport
