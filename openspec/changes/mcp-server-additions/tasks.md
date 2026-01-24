# MCP Server Additions - Tasks

## Completed

### axios-ai-mail MCP Server

**Date Added**: 2025-01-24
**Status**: Complete

axios-ai-mail has been updated to provide an MCP server mode for AI-powered email management.

**Server Configuration**:
```json
{
  "mcpServers": {
    "axios-ai-mail": {
      "command": "axios-ai-mail",
      "args": ["mcp"]
    }
  }
}
```

**Tasks**:
- [x] Server configuration identified
- [x] Add to `home/ai/mcp.nix` settings.servers section
- [x] Add package to `home.packages`
- [x] Add to requirements comment block (PIM TOOLS section)
- [ ] Test server loads with `mcp-cli` (requires rebuild)
- [ ] Mark complete in proposal.md table

---

## In Progress

(None currently)

---

## Backlog

(Future MCP servers to add)
