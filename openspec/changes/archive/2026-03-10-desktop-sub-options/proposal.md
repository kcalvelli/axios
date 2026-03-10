## Why

The desktop module installs ~50 packages behind a single `desktop.enable` flag. Users cannot opt out of heavyweight apps (libreoffice, krita, OBS, discord) without disabling the entire desktop. For a library/framework, application choices should be configurable while still providing a full desktop experience by default.

## What Changes

- **Split desktop packages into sub-option groups** with their own `enable` flags, all defaulting to `true`:
  - `desktop.media.enable` — media viewing, playback, creation, screen capture
  - `desktop.office.enable` — productivity apps (documents, PDF, markdown, calculator)
  - `desktop.streaming.enable` — live streaming and comms (OBS, discord)
  - `desktop.social.enable` — messaging and entertainment (materialgram, spotify)
- **Remove profanity** — redundant XMPP client (gajim stays, tied to XMPP/chat use cases outside desktop)
- **Remove c64term** — novelty retro terminal, users can add via extraConfig
- **Move gajim out of desktop** — XMPP client belongs with a chat/PIM module, not desktop
- **Move zenity into social group** — only needed for Spotify local files
- **Core desktop** retains: window management, file manager, theming, launchers, system utilities, 1password, corectrl, kdeconnect

All sub-options default to `true` for backward compatibility. New installs via Calamares get the full desktop. Power users disable groups they don't need.

## Capabilities

### New Capabilities

_None — restructuring existing capability._

### Modified Capabilities

- `desktop`: Breaking monolithic package list into toggleable sub-groups with independent enable flags.

## Impact

- **modules/desktop/default.nix** — Major restructure: extract packages into conditional blocks
- **Calamares/installer** — No changes needed (all defaults are true, full desktop installed)
- **Downstream configs** — No breaking changes (all sub-options default to true)
- Power users gain granular control: `desktop.streaming.enable = false` to drop OBS+discord
