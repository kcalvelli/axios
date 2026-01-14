# Networking & Self-Hosted Services

## Purpose
Manages network connectivity and self-hosted application infrastructure.

## Components

### Tailscale
- **Features**: Mesh VPN, automatic HTTPS certificates.
- **Implementation**: `modules/networking/tailscale.nix`

### Caddy Reverse Proxy
- **Architecture**: Route Registry Pattern. Services register routes via `selfHosted.caddy.routes.<name>`.
- **Logic**: Automatic sorting - path-specific routes (priority 100) are evaluated before catch-all (priority 1000).
- **Implementation**: `modules/services/caddy.nix`

### Immich (Photo Backup)
- **Deployment**: Catch-all service on the primary domain.
- **Implementation**: `modules/services/immich.nix`

### File Synchronization
- **Samba**: Local network file sharing.
- **Google Drive Sync**: rclone-based bidi sync for Documents and Music.
- **Implementation**: `modules/networking/samba.nix`, `home/desktop/gdrive-sync.nix`

## Constraints
- **Caddy Registration**: All services MUST use the registry pattern, NEVER hardcoded path-based handle blocks.
