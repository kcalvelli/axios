## Context

axiOS hosts need to sync common XDG directories (Documents, Music, Pictures, Videos, etc.) across installations. The current mechanism uses rclone bisync to Google Drive (`home/desktop/gdrive-sync.nix`), which is fragile and dependent on Google's API stability. A previous attempt with Syncthing failed due to NAT traversal and relay discovery issues. All axiOS hosts already run Tailscale via the `modules/networking/tailscale.nix` module, providing a reliable mesh network with stable IPs that eliminates Syncthing's connectivity problems entirely.

NixOS ships a built-in `services.syncthing` module that manages the Syncthing daemon, including declarative folder and device configuration via `services.syncthing.settings`. The axiOS module wraps this to provide XDG-aware folder semantics and Tailscale-only transport defaults.

## Goals / Non-Goals

**Goals:**
- Declarative Syncthing configuration via an `axios.syncthing` NixOS module
- XDG-semantic folder names (e.g., `"documents"`, `"pictures"`) that resolve to correct user paths
- Tailscale-only transport: no global discovery, no relaying, no NAT traversal
- Per-host selective sync: each host declares which XDG dirs it participates in
- Per-host device declarations addressed by Tailscale MagicDNS names for direct connectivity
- Conflict handling via Syncthing's built-in `.sync-conflict` mechanism with configurable ignore patterns
- Retire `home/desktop/gdrive-sync.nix`

**Non-Goals:**
- GUI for Syncthing (users can access the web UI at localhost:8384 if needed)
- Syncthing relay or discovery server hosting
- Syncing non-XDG arbitrary paths (users can use raw `services.syncthing` for that)
- Automatic device ID exchange or discovery (device IDs are declared in config)
- Multi-user per-host Syncthing (one Syncthing instance per host, running as the primary user)

## Decisions

### Decision 1: NixOS module, not home-manager module

**Choice**: Implement as a NixOS module at `modules/syncthing/default.nix` using the `axios.syncthing` namespace.

**Rationale**: NixOS's `services.syncthing` is a system-level service module. While Syncthing runs as a specific user, the NixOS module handles user/group configuration, the systemd service, and firewall rules. This matches the pattern used by `axios.immich` (system module with `axios.*` namespace). A home-manager module would be insufficient since it can't manage system services or firewall rules.

**Alternative considered**: Home-manager-only module using `systemd.user.services`. Rejected because NixOS already provides a well-tested `services.syncthing` module, and we'd lose firewall integration and system service management.

### Decision 2: XDG folder name mapping

**Choice**: Map short XDG names to paths using a fixed lookup table:

| Name | XDG Variable | Default Path |
|------|-------------|-------------|
| `documents` | `XDG_DOCUMENTS_DIR` | `~/Documents` |
| `music` | `XDG_MUSIC_DIR` | `~/Music` |
| `pictures` | `XDG_PICTURES_DIR` | `~/Pictures` |
| `videos` | `XDG_VIDEOS_DIR` | `~/Videos` |
| `downloads` | `XDG_DOWNLOAD_DIR` | `~/Downloads` |
| `templates` | `XDG_TEMPLATES_DIR` | `~/Templates` |
| `desktop` | `XDG_DESKTOP_DIR` | `~/Desktop` |
| `publicshare` | `XDG_PUBLICSHARE_DIR` | `~/Public` |

**Rationale**: Using well-known names rather than raw paths prevents misconfiguration and makes the interface self-documenting. The module uses the standard default paths (e.g., `/home/<user>/Documents`) since NixOS doesn't generally customize `user-dirs.dirs` — these defaults are stable and correct.

**Alternative considered**: Reading `~/.config/user-dirs.dirs` at evaluation time. Rejected because Nix evaluation happens at build time, not runtime, and the file may not exist yet.

### Decision 3: Tailscale-only transport via MagicDNS

**Choice**: Disable all Syncthing discovery and relay mechanisms by default:
- `globalAnnounceEnabled = false`
- `localAnnounceEnabled = false`
- `relaysEnabled = false`
- `natEnabled = false`

Devices are addressed by Tailscale MagicDNS names (e.g., `tcp://pangolin.<tailnet>.ts.net:22000`). The device attr name is used as the Tailscale machine name by default, with a `tailscaleName` override for cases where they differ. The module reads `config.networking.tailscale.domain` to construct the full FQDN. An `addresses` option provides a full escape hatch for non-standard scenarios.

**Rationale**: MagicDNS names are human-readable and stable. Using them instead of raw IPs makes configs self-documenting and eliminates the need to look up CGNAT addresses. All axiOS hosts run Tailscale with MagicDNS enabled, so hostname resolution is guaranteed. This also solves the (already unlikely) edge case of Tailscale IP reassignment after device re-registration.

**Alternative considered**: Raw Tailscale IPs (e.g., `tcp://100.64.x.y:22000`). Rejected because IPs are harder to read, require manual lookup, and offer no advantage over MagicDNS on a tailnet where all devices have DNS names.

### Decision 4: Device IDs in plain config (no agenix)

**Choice**: Syncthing device IDs are declared in plain-text host configuration. No encryption via agenix.

**Rationale**: Syncthing device IDs are public identifiers (derived from public keys). They are designed to be shared openly — knowing a device ID doesn't grant access unless that device also adds you. This is analogous to SSH public keys. Encrypting them via agenix would add operational complexity with no security benefit.

### Decision 5: Single-user per host

**Choice**: The module configures one Syncthing instance per host, running as a single user specified via `axios.syncthing.user`. XDG folder paths are resolved relative to that user's home directory.

**Rationale**: Syncthing's NixOS module runs a single daemon per host. Multi-user Syncthing would require multiple daemon instances and significantly more complexity. The typical axiOS deployment has one primary user per host. Users who need multi-user sync can extend with raw `services.syncthing` configuration.

### Decision 6: Module registration as flagged module

**Choice**: Register as a new top-level module `syncthing` in `modules/default.nix`, controlled by `modules.syncthing` flag (default `false`) in `lib/default.nix` flaggedModules.

**Rationale**: Syncthing is an opt-in feature, not something every host needs. This follows the pattern of `gaming`, `pim`, `virt` etc. The `services` coreModule is for things like Immich/Caddy that are always available for configuration. Syncthing is distinct enough to warrant its own module flag.

## Risks / Trade-offs

- **[Risk] Initial sync of large directories** → First sync of a directory with many files could take significant time and bandwidth. Mitigation: Syncthing handles this gracefully with delta sync. No special handling needed.

- **[Risk] Conflict files accumulate** → Syncthing creates `.sync-conflict-*` files that could accumulate. Mitigation: Provide configurable `ignorePatterns` per folder and document the conflict resolution workflow.

- **[Trade-off] Device ID bootstrap** → Users must obtain each device's Syncthing device ID before full config is possible. The ID is generated on first Syncthing start and can be retrieved via `syncthing --device-id` (no GUI needed). Bootstrap workflow: enable module → rebuild → grab ID from CLI → add IDs to config → rebuild again. This is a one-time process per device.

- **[Trade-off] Single user limitation** → Only one user's XDG dirs can be synced per host. Acceptable for the typical axiOS use case (single primary user per machine).

## Migration Plan

1. **Add module**: Create `modules/syncthing/default.nix`, register in `modules/default.nix` and `lib/default.nix`
2. **Downstream adoption**: Users add `modules.syncthing = true` and configure devices/folders in their host config
3. **Verify sync works**: Users confirm Syncthing peer-to-peer connectivity over Tailscale
4. **Remove gdrive-sync**: Delete `home/desktop/gdrive-sync.nix` and remove its import from `home/desktop/default.nix`
5. **Rollback**: If Syncthing fails, users can disable `modules.syncthing = false` and the gdrive-sync code remains until explicitly removed

## Open Questions

- None — all key decisions are resolved. Device ID management, transport strategy, and module architecture are defined above.
