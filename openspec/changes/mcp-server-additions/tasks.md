# MCP Server Additions - Tasks

## Completed

### axios-ai-mail MCP Server

**Date Added**: 2025-01-24
**Status**: Complete ✅

axios-ai-mail provides an MCP server for AI-powered email management.

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

**Available Tools**:
- `list_accounts` - List configured email accounts
- `search_emails` - Search with filters (query, account, folder, tags, unread)
- `read_email` - Read email by message ID
- `compose_email` - Create new email draft
- `send_email` - Send email (from draft or directly)
- `reply_to_email` - Reply to email (with reply-all option)
- `mark_read` - Mark emails read/unread
- `delete_email` - Delete emails (soft or permanent)

**Tasks**:
- [x] Server configuration identified
- [x] Add to `home/ai/mcp.nix` settings.servers section
- [x] Add package to `home.packages`
- [x] Add to requirements comment block (PIM TOOLS section)
- [x] Update flake.lock with MCP-enabled version
- [x] Test server loads with `mcp-cli`

---

## In Progress

(None currently)

---

## Backlog

(Future MCP servers to add)
