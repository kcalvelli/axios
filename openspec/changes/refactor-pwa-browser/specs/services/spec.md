# Networking & Self-Hosted Services

## Purpose
Manages network connectivity and self-hosted application infrastructure using a declarative reverse proxy pattern.

## Components

### Tailscale
- **Protocol**: Mesh VPN with automatic HTTPS certificate provisioning.
- **Requirement**: `networking.tailscale.domain` must be set for self-hosted services.
- **Implementation**: `modules/networking/tailscale.nix`

### Caddy Route Registry
- **Pattern**: Route Registry Pattern. Services register routes via `selfHosted.caddy.routes.<name>`.
- **Logic**: Automatic sorting - path-specific routes (priority 100) are evaluated before catch-all (priority 1000).
- **Features**: Automatic HTTPS via Tailscale, custom `extraConfig` for reverse proxy blocks, and `handleConfig` for outer blocks.
- **Implementation**: `modules/services/caddy.nix`, `modules/services/default.nix`

### Immich (Photo Backup)
- **Features**: Subdomain support (`selfHosted.immich.subdomain`), custom media location, and GPU acceleration.
- **Acceleration**: Optional AMD/Nvidia/Intel GPU support for video transcoding.
- **Networking**: Uses **Tailscale Services** (`axios-immich.<tailnet>.ts.net`) for secure, magic-dns addressed access.
- **PWA Strategy**: Uses `loopbackProxy` for unified HTTPS access (`https://axios-immich.<tailnet>/`) on both server and client.
- **Implementation**: `modules/services/immich.nix`

### Local AI (Ollama)
- **Features**: Path-based reverse proxy (`/ollama/*`) on the primary system domain.
- **Priority**: High (priority 100) to ensure path matching works alongside catch-all services.
- **Implementation**: `modules/ai/default.nix`

### File Synchronization
- **Samba**: Local network file sharing for media/documents.
- **Google Drive Sync**: `rclone`-based bi-directional sync (Home Manager).
- **Implementation**: `modules/networking/samba.nix`, `home/desktop/gdrive-sync.nix`

## Constraints
- **Registry Mandate**: All self-hosted services MUST use the registry pattern, NEVER hardcoded Caddyfile handle blocks.
- **Domain Consistency**: Services sharing a domain must be careful with path-based priorities.
