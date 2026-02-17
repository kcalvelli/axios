## MODIFIED Requirements

### Requirement: File Synchronization

The system SHALL provide peer-to-peer file synchronization for XDG directories across axiOS hosts using Syncthing over Tailscale.

#### Scenario: File synchronization components

- **WHEN** file synchronization is configured
- **THEN** the following components SHALL be available:
  - **Syncthing XDG Sync**: Peer-to-peer XDG directory sync via Tailscale (`modules/syncthing/default.nix`)
  - **Samba**: Local network file sharing for media/documents (`modules/networking/samba.nix`)

## REMOVED Requirements

### Requirement: Google Drive Sync

**Reason**: Replaced by Syncthing XDG Sync, which provides reliable peer-to-peer synchronization without dependency on Google's API stability.

**Migration**: Enable `modules.syncthing = true` in host configuration, declare devices and folders, and verify sync works before removing any local rclone configuration. The `home/desktop/gdrive-sync.nix` module and `setup-gdrive-sync` helper script are retired.
