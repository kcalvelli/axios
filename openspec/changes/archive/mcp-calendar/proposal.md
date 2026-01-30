# Proposal: MCP Calendar Integration (via axios-dav)

## Summary

Integrate axios-dav external flake to provide declarative CalDAV/CardDAV synchronization and MCP server for AI-powered calendar and contacts management.

## Motivation

### Problem Statement

axios currently has calendar sync infrastructure via vdirsyncer, but it has significant limitations:

1. **One-way sync**: CalDAV → local only, AI cannot create/modify events
2. **Manual configuration**: Users must manually create `~/.config/vdirsyncer/config`
3. **No AI integration**: Claude Code, Gemini CLI cannot query or manage calendar
4. **No declarative config**: Credentials and calendar sources not in Nix
5. **No contacts support**: khard exists but is not declaratively configured

### Solution

Create **axios-dav** as an external flake (similar to axios-ai-mail) that:

1. **Declarative Configuration**: Generate vdirsyncer, khal, and khard configs from Nix options
2. **Two-Way Sync**: Support bidirectional sync with Google Calendar and CalDAV providers
3. **MCP Server**: Build mcp-dav MCP server for AI calendar and contacts access
4. **Modular Design**: Can be used standalone or as an axios flake input

## Architecture Decision: External Flake

**Why external?**

Following the axios-ai-mail pattern, calendar/contacts functionality is complex enough to warrant a dedicated repository:

1. **Standalone use**: Users without axios can use axios-dav independently
2. **Focused development**: Separate test cycles, releases, and documentation
3. **Clear boundaries**: Calendar/contacts is a distinct domain from core OS configuration
4. **Simpler axios core**: axios imports the flake rather than maintaining complex PIM logic

**Repository**: `github:kcalvelli/axios-dav`

## axios-dav Features

### Calendar (CalDAV)

- Google Calendar (OAuth)
- Fastmail, Nextcloud, any CalDAV server
- HTTP ICS subscriptions (read-only)
- Two-way sync support

### Contacts (CardDAV)

- Google Contacts (OAuth via CardDAV endpoint)
- Fastmail, Nextcloud, any CardDAV server

### MCP Server (mcp-dav)

**Calendar Tools:**
- `list_events` - List events in date range
- `search_events` - Search events by text
- `create_event` - Create new calendar event
- `get_free_busy` - Check availability

**Contacts Tools:**
- `list_contacts` - List all contacts
- `search_contacts` - Search by name/email
- `get_contact` - Get contact details

## axios Integration

### Flake Input

```nix
# axios/flake.nix
inputs.axios-dav = {
  url = "github:kcalvelli/axios-dav";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Module Import

```nix
# lib/default.nix or modules/pim/default.nix
imports = [
  inputs.axios-dav.nixosModules.default
];
```

### Home-Manager Module

```nix
# home/default.nix
imports = [
  inputs.axios-dav.homeModules.default
];
```

### Configuration Example

```nix
{
  services.axios-dav = {
    enable = true;

    calendar = {
      enable = true;
      defaultCalendar = "personal";

      accounts = {
        personal = {
          type = "google";
          tokenFile = config.age.secrets.google-calendar-token.path;
          clientId = "your-client-id.apps.googleusercontent.com";
          clientSecretFile = config.age.secrets.google-client-secret.path;
        };
      };
    };

    contacts = {
      enable = true;

      accounts = {
        personal = {
          type = "google";
          tokenFile = config.age.secrets.google-contacts-token.path;
          clientId = "your-client-id.apps.googleusercontent.com";
          clientSecretFile = config.age.secrets.google-client-secret.path;
        };
      };
    };

    sync.frequency = "5m";
    mcp.enable = true;
  };
}
```

## Impact on axios

### What to Remove from axios

1. `home/calendar/default.nix` - Replaced by axios-dav systemd services
2. vdirsyncer from `modules/pim/default.nix` - Installed by axios-dav instead

### What axios Keeps

1. DMS integration with khal widget (`enableCalendarEvents`)
2. MCP server registration in `home/ai/mcp.nix` (conditional on axios-dav)

### Migration Path

1. **Phase 1**: Add axios-dav as flake input, test alongside existing setup
2. **Phase 2**: Remove redundant calendar code from axios
3. **Phase 3**: Update documentation

## Dependencies

- axios-dav must be developed first (greenfield repository created)
- OAuth setup documentation required for Google accounts

## Testing Requirements

### Integration Tests

- [ ] axios-dav imports correctly as flake input
- [ ] NixOS module options work
- [ ] Home-manager module options work
- [ ] MCP server registered in mcp-cli
- [ ] Calendar tools accessible from Claude Code
- [ ] Contacts tools accessible from Claude Code

## Timeline

1. **axios-dav development**: See axios-dav greenfield proposal
2. **axios integration**: After axios-dav has basic functionality

## References

- axios-dav repository: `~/Projects/axios-dav`
- axios-ai-mail (pattern to follow): `github:kcalvelli/axios-ai-mail`
- vdirsyncer documentation: https://vdirsyncer.pimutils.org/
- khal documentation: https://khal.readthedocs.io/
- khard documentation: https://khard.readthedocs.io/
