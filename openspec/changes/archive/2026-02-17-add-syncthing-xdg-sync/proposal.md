## Why

axiOS has no reliable mechanism for syncing common XDG directories (Documents, Music, Pictures, etc.) across installations. The existing approach uses an rclone-to-Google-Drive script (`home/desktop/gdrive-sync.nix`) that is fragile and dependent on Google's API stability. A previous attempt with Syncthing failed due to connectivity and discovery issues. Since all axiOS hosts already run Tailscale, Syncthing can use Tailscale IPs for direct peer-to-peer connectivity, eliminating NAT traversal and relay problems entirely.

## What Changes

- Add a new NixOS module (`modules/syncthing/default.nix`) that declaratively configures Syncthing with axiOS-specific defaults and XDG-aware folder configuration
- Folders are defined by XDG directory name (e.g., `"documents"`, `"pictures"`) rather than raw paths; the module resolves to the correct XDG path per user
- Tailscale-only transport: disable global discovery, default relaying, and NAT traversal; address devices by Tailscale MagicDNS names
- Per-host device and folder declarations: each host declares which XDG dirs it participates in and which peer devices it syncs with; device attr names map to Tailscale machine names automatically
- Syncthing's default `.sync-conflict` files for conflict handling, with optional ignore patterns configurable per folder
- Support selective sync: not every host needs every directory (e.g., a headless server may only want Documents, not Pictures)
- Retire the existing rclone Google Drive sync mechanism (`home/desktop/gdrive-sync.nix`)
- Register the module in `modules/default.nix` and `lib/default.nix` as a flagged module

## Capabilities

### New Capabilities
- `syncthing-xdg-sync`: Declarative Syncthing module for peer-to-peer XDG directory synchronization across axiOS hosts via Tailscale

### Modified Capabilities
- `services`: Update File Synchronization section to reflect Syncthing replacing Google Drive sync

## Impact

- **New files**: `modules/syncthing/default.nix` (NixOS module)
- **Modified files**: `modules/default.nix` (register module), `lib/default.nix` (add to flaggedModules + hostModule wiring), `openspec/specs/services/spec.md` (update File Synchronization section)
- **Removed files**: `home/desktop/gdrive-sync.nix` (retired)
- **Modified files**: `home/desktop/default.nix` (remove gdrive-sync import)
- **Dependencies**: NixOS `services.syncthing` (already in nixpkgs), Tailscale (already configured)
- **Host config**: Downstream hosts will need to add `modules.syncthing = true` and configure device/folder declarations
- **Syncthing device IDs**: Non-sensitive public identifiers; safe for plain config (no agenix needed)
