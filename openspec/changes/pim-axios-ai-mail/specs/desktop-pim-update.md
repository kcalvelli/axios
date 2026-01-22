# Desktop Spec Update: PIM Section

This document shows the proposed changes to `openspec/specs/desktop/spec.md` PIM section.

## Current (to be replaced)

```markdown
### Personal Information Management (PIM)
- **Clients**: Geary (Email), GNOME Calendar, GNOME Contacts, Evolution (Backend).
- **Backend**: Evolution Data Server (EDS) services for lightweight PIM without full GNOME.
- **Sync**: `vdirsyncer` support for CalDAV/CardDAV.
- **Limitation**: Office365/Outlook integration is currently non-functional.
- **Implementation**: `modules/pim/default.nix`
```

## Proposed (new content)

```markdown
### Personal Information Management (PIM)

**Email**: axios-ai-mail - AI-powered email management with local LLM classification.
- Multi-account support (Gmail OAuth, IMAP/SMTP)
- Privacy-first local processing via Ollama
- Modern web UI with PWA support
- Tailscale integration for cross-device access

**Calendar**: vdirsyncer + khal + PWA apps
- Automated CalDAV sync via systemd timers
- khal CLI for DMS calendar widget integration
- PWA apps for graphical interface (user's choice)

**Contacts**: Cloud provider UIs or PWA apps
- Future: axios-ai-mail contacts module (planned)

**Implementation**:
- `modules/pim/default.nix` (system services)
- `home/pim/default.nix` (user configuration)
- See `openspec/specs/pim/spec.md` for full documentation
```

## Changes Summary

1. **Removed**: Geary, GNOME Calendar, GNOME Contacts, Evolution, Evolution Data Server, GNOME Online Accounts
2. **Added**: axios-ai-mail with local AI classification
3. **Preserved**: vdirsyncer for calendar sync, khal for DMS widget
4. **Removed**: Office365 limitation note (no longer relevant)
5. **Added**: Reference to dedicated PIM spec
