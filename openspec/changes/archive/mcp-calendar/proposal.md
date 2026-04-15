# Proposal: MCP Calendar Integration (via cairn-dav)

## Summary

Integrate cairn-dav external flake to provide declarative CalDAV/CardDAV synchronization and MCP server for AI-powered calendar and contacts management.

## Motivation

### Problem Statement

cairn currently has calendar sync infrastructure via vdirsyncer, but it has significant limitations:

1. **One-way sync**: CalDAV → local only, AI cannot create/modify events
2. **Manual configuration**: Users must manually create `~/.config/vdirsyncer/config`
3. **No AI integration**: Claude Code, Gemini CLI cannot query or manage calendar
4. **No declarative config**: Credentials and calendar sources not in Nix
5. **No contacts support**: khard exists but is not declaratively configured

### Solution

Create **cairn-dav** as an external flake (similar to cairn-mail) that:

1. **Declarative Configuration**: Generate vdirsyncer, khal, and khard configs from Nix options
2. **Two-Way Sync**: Support bidirectional sync with Google Calendar and CalDAV providers
3. **MCP Server**: Build mcp-dav MCP server for AI calendar and contacts access
4. **Modular Design**: Can be used standalone or as an cairn flake input

## Architecture Decision: External Flake

**Why external?**

Following the cairn-mail pattern, calendar/contacts functionality is complex enough to warrant a dedicated repository:

1. **Standalone use**: Users without cairn can use cairn-dav independently
2. **Focused development**: Separate test cycles, releases, and documentation
3. **Clear boundaries**: Calendar/contacts is a distinct domain from core OS configuration
4. **Simpler cairn core**: cairn imports the flake rather than maintaining complex PIM logic

**Repository**: `github:kcalvelli/cairn-dav`

## cairn-dav Features

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

## cairn Integration

### Flake Input

```nix
# cairn/flake.nix
inputs.cairn-dav = {
  url = "github:kcalvelli/cairn-dav";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Module Import

```nix
# lib/default.nix or modules/pim/default.nix
imports = [
  inputs.cairn-dav.nixosModules.default
];
```

### Home-Manager Module

```nix
# home/default.nix
imports = [
  inputs.cairn-dav.homeModules.default
];
```

### Configuration Example

```nix
{
  services.cairn-dav = {
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

## Impact on cairn

### What to Remove from cairn

1. `home/calendar/default.nix` - Replaced by cairn-dav systemd services
2. vdirsyncer from `modules/pim/default.nix` - Installed by cairn-dav instead

### What cairn Keeps

1. DMS integration with khal widget (`enableCalendarEvents`)
2. MCP server registration in `home/ai/mcp.nix` (conditional on cairn-dav)

### Migration Path

1. **Phase 1**: Add cairn-dav as flake input, test alongside existing setup
2. **Phase 2**: Remove redundant calendar code from cairn
3. **Phase 3**: Update documentation

## Dependencies

- cairn-dav must be developed first (greenfield repository created)
- OAuth setup documentation required for Google accounts

## Testing Requirements

### Integration Tests

- [ ] cairn-dav imports correctly as flake input
- [ ] NixOS module options work
- [ ] Home-manager module options work
- [ ] MCP server registered in mcp-cli
- [ ] Calendar tools accessible from Claude Code
- [ ] Contacts tools accessible from Claude Code

## Timeline

1. **cairn-dav development**: See cairn-dav greenfield proposal
2. **cairn integration**: After cairn-dav has basic functionality

## References

- cairn-dav repository: `~/Projects/cairn-dav`
- cairn-mail (pattern to follow): `github:kcalvelli/cairn-mail`
- vdirsyncer documentation: https://vdirsyncer.pimutils.org/
- khal documentation: https://khal.readthedocs.io/
- khard documentation: https://khard.readthedocs.io/
