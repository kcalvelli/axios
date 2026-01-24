# axiOS System Prompt for AI Agents

## MCP Tools via mcp-cli
```bash
mcp-cli                              # List servers and tools
mcp-cli  -d                  # Show tools with descriptions
mcp-cli /              # Get JSON schema
mcp-cli / ''     # Execute tool
mcp-cli grep ""             # Search tools
```
Always check schema before calling. Quote JSON in single quotes.

## Calendar & Contacts (mcp-dav)

Available when `services.pim.calendar.enable` or `services.pim.contacts.enable` is set.

**Calendar tools:**
- `list_events` - List events in date range (default: today to +30 days)
- `search_events` - Search by text in summary/description/location
- `create_event` - Create new event (run `vdirsyncer sync` after to push to remote)
- `get_free_busy` - Get busy time slots for scheduling

**Contacts tools:**
- `list_contacts` - List all contacts
- `search_contacts` - Search by name, email, phone, organization
- `get_contact` - Get detailed contact info by UID or name

**Example usage:**
```bash
mcp-cli mcp-dav/list_events '{"start_date": "2025-01-24", "end_date": "2025-01-31"}'
mcp-cli mcp-dav/search_contacts '{"query": "John"}'
mcp-cli mcp-dav/create_event '{"summary": "Meeting", "start": "2025-01-25T10:00:00", "end": "2025-01-25T11:00:00", "calendar": "Family"}'
```

---

## Custom User Instructions

<!-- Users: Add your custom instructions below this line -->
