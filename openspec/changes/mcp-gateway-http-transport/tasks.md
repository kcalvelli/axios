# Tasks: MCP Gateway HTTP Transport

## Phase 1: MCP Protocol Implementation

- [x] **1.1 Research MCP HTTP Transport spec**
  - Read https://spec.modelcontextprotocol.io/specification/2025-06-18/basic/transports
  - Streamable HTTP (not SSE-only) is the current spec
  - Single `/mcp` endpoint handles POST/GET/DELETE

- [x] **1.2 Add MCP endpoint to mcp-gateway**
  - Added `sse-starlette` dependency (for future SSE streaming)
  - Created `/mcp` endpoint handling POST/GET/DELETE
  - Implemented session management with `Mcp-Session-Id` header

- [x] **1.3 Implement MCP methods**
  - `initialize` - Returns server capabilities, creates session ✅
  - `tools/list` - Returns all 86 tools with namespacing ✅
  - `tools/call` - Routes to server manager, returns MCP-formatted result ✅
  - `ping` - Health check ✅
  - `notifications/initialized` - Session initialization notification ✅

## Phase 2: Tool Aggregation

- [x] **2.1 Design tool namespacing**
  - Format: `server_id__tool_name` (double underscore separator)
  - Examples: `axios-ai-mail__send_email`, `git__git_status`
  - Descriptions prefixed with `[server_id]` for clarity

- [x] **2.2 Implement tool aggregation**
  - Aggregates tools from all enabled MCP servers
  - Dynamic - reflects currently enabled servers

- [x] **2.3 Map tool calls to servers**
  - Parses namespaced tool name
  - Routes to correct server via server manager
  - Returns MCP content format

## Phase 3: Testing & Integration

- [x] **3.1 Local testing**
  - Verified initialize, tools/list, tools/call via curl
  - All 86 tools discovered
  - Tool execution works (tested with axios-ai-mail__list_accounts)

- [ ] **3.2 Claude.ai Integration testing**
  - Expose via Tailscale serve
  - Add as custom connector in Claude.ai
  - Verify tool discovery
  - Test tool execution

- [ ] **3.3 Backward compatibility**
  - Verify REST/OpenAPI endpoints still work
  - Verify orchestrator UI works

## Phase 4: Documentation & Finalization

- [ ] **4.1 Update specs**
  - Update `openspec/specs/ai/spec.md` with MCP HTTP transport
  - Document Claude.ai integration steps

- [ ] **4.2 Archive proposal**
  - Move to `openspec/changes/archive/`
  - Update changelog

## Implementation Notes

**Endpoint structure (Streamable HTTP spec 2025-06-18):**
- `POST /mcp` - Send JSON-RPC messages (initialize, tools/list, tools/call)
- `GET /mcp` - SSE stream for server-initiated messages (not implemented yet)
- `DELETE /mcp` - Terminate session

**Session flow:**
1. Client POSTs `initialize` request
2. Server returns capabilities + `Mcp-Session-Id` header
3. Client POSTs `notifications/initialized`
4. Client can now call `tools/list` and `tools/call`

**Tool namespacing:**
- Format: `{server_id}__{tool_name}`
- Example: `axios-ai-mail__send_email`
- Parsing: Split on `__` to get server_id and tool_name
