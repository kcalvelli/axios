# Networking Module

Network configuration and services.

## Purpose

Provides network manager configuration, SSH, and optional network services like Avahi, Samba, and Tailscale.

## Core Configuration

- **NetworkManager**: System network management
- **SSH**: OpenSSH server (enabled by default)
- **Firewall**: Configured via NixOS firewall

## Optional Services

### Avahi (`avahi.nix`)
Local network service discovery (mDNS/DNS-SD).
- Enable with: `axios.networking.avahi.enable = true`
- **Default behavior**: Auto-enabled when Samba is enabled, disabled otherwise
- Use for: Local network device discovery, `.local` domains, Samba auto-discovery
- **Note**: Disable explicitly to reduce network noise if you don't need auto-discovery
- Samba works without Avahi (use direct connections: `smb://hostname/share`)

### Samba (`samba.nix`)
File sharing with Windows and network devices.
- Enable with: `networking.samba.enable = true`
- Configure shares in host config

### Tailscale (`tailscale.nix`)
VPN mesh network for secure remote access.
- Enable with: `networking.tailscale.enable = true`
- Requires authentication: `sudo tailscale up`

## What Goes Here

**Network services:**
- Core networking (NetworkManager, SSH)
- Service discovery protocols
- File sharing services
- VPN clients and servers

**Desktop network apps go to:** `home/common/` or `modules/desktop/`

## Usage in Host Configuration

```nix
{
  networking = {
    hostName = "myhost";
    networkmanager.enable = true;  # Default

    # Optional services
    samba.enable = true;           # Avahi auto-enables for discovery
    tailscale.enable = true;
  };

  # To disable Avahi even with Samba:
  axios.networking.avahi.enable = false;

  # To enable Avahi without Samba:
  axios.networking.avahi.enable = true;
}
```

## Notes

- All services are opt-in except core networking
- SSH is enabled by default for system administration
- Firewall is automatically configured for enabled services
