# Tailscale Services Setup Guide

This guide explains how to configure Tailscale Services for axios, enabling unique DNS names for each service (e.g., `axios-mail.your-tailnet.ts.net`).

## Why Tailscale Services?

axios uses Tailscale Services to provide:

1. **Unique DNS names per service** - Each service gets its own hostname
2. **Automatic HTTPS** - TLS certificates managed by Tailscale
3. **Proper PWA icons** - Chromium/Brave generates unique app_ids from distinct domains
4. **Zero port management** - All services accessible on standard HTTPS port

Without Tailscale Services, all PWAs served from the same host would share identical dock icons on Wayland.

## Prerequisites

- Tailscale account with admin access
- axios server machine (e.g., `edge`)
- agenix configured for secrets management

## Step 1: Configure Tailscale ACLs

Go to [Tailscale Admin Console](https://login.tailscale.com/admin/acls) and configure your ACL policy.

### Minimal ACL Configuration

```json
{
    "grants": [
        {
            "src": ["*"],
            "dst": ["*"],
            "ip":  ["*"]
        }
    ],

    "tagOwners": {
        "tag:server": ["autogroup:member"]
    },

    "autoApprovers": {
        "services": {
            "svc:axios-mail":    ["tag:server"],
                        "svc:axios-ollama":  ["tag:server"],
            "svc:axios-immich":  ["tag:server"]
        }
    }
}
```

### ACL Breakdown

| Section | Purpose |
|---------|---------|
| `grants` | Allows all tailnet members to access all services |
| `tagOwners` | Lets tailnet members create devices with `tag:server` |
| `autoApprovers.services` | Auto-approves service registration from tagged devices |

### Optional: SSH Access

Add SSH configuration for remote management:

```json
{
    "ssh": [
        {
            "action": "check",
            "src":    ["autogroup:member"],
            "dst":    ["autogroup:self"],
            "users":  ["autogroup:nonroot", "root"]
        }
    ]
}
```

## Step 2: Create Auth Key

Tailscale Services require tag-based device identity (not user-owned).

1. Go to [Tailscale Admin → Settings → Keys](https://login.tailscale.com/admin/settings/keys)
2. Click **Generate auth key**
3. Configure:
   - **Description**: `axios-server`
   - **Reusable**: Yes (allows rebuilds without new keys)
   - **Expiration**: No expiry (or manage rotation)
   - **Tags**: `tag:server`
4. Copy the key (starts with `tskey-auth-`)

## Step 3: Store Auth Key in Agenix

```bash
# In your nixos config directory
cd ~/.config/nixos_config

# Create the encrypted secret
echo "tskey-auth-kYourKeyHere-XXXXXXXX" | agenix -e secrets/tailscale-server-key.age

# Register in your secrets configuration
```

Add to your agenix secrets configuration:

```nix
age.secrets.tailscale-server-key = {
  file = ./secrets/tailscale-server-key.age;
};
```

## Step 4: Configure axios Server

In your server host configuration (e.g., `hosts/edge.nix`):

```nix
{
  extraConfig = {
    # Tailscale configuration - Server mode with tag-based identity
    networking.tailscale = {
      domain = "your-tailnet.ts.net";  # Find this in Tailscale admin
      operator = "your-username";       # Allow user to manage Tailscale
      authMode = "authkey";             # Tag-based identity for servers
      authKeyFile = "/run/agenix/tailscale-server-key";
    };
  };
}
```

## Step 5: Configure axios Client

Client machines (laptops, etc.) stay user-owned and just need `acceptRoutes`:

```nix
{
  extraConfig = {
    networking.tailscale = {
      domain = "your-tailnet.ts.net";
      # authMode defaults to "interactive" (user-owned)
      # acceptRoutes defaults to true (receives service VIPs)
    };
  };
}
```

## Step 6: Enable Services

Services auto-register with Tailscale when enabled:

### Server Role (runs the service)

```nix
{
  # In extraConfig
  services.pim = {
    user = "your-username";
    pwa.enable = true;
    pwa.tailnetDomain = "your-tailnet.ts.net";
  };

  services.ai.local = {
    role = "server";
  };
}

# In hostConfig (outside extraConfig)
axios = {
  immich = {
    enable = true;
    pwa.enable = true;
    pwa.tailnetDomain = "your-tailnet.ts.net";
  };
};
```

### Client Role (PWA only)

```nix
{
  extraConfig = {
    services.pim = {
      role = "client";
      pwa.enable = true;
      pwa.tailnetDomain = "your-tailnet.ts.net";
    };

    services.ai.local = {
      role = "client";
      tailnetDomain = "your-tailnet.ts.net";
    };

    axios.immich = {
      enable = true;
      role = "client";
      pwa.enable = true;
      pwa.tailnetDomain = "your-tailnet.ts.net";
    };
  };
}
```

## Rebuild and Verify

```bash
# Rebuild server
sudo nixos-rebuild switch --flake .#edge

# Rebuild client
sudo nixos-rebuild switch --flake .#pangolin
```

### Verify Services are Registered

Check the Tailscale admin console → Services tab. You should see:
- `axios-mail` (1 online)
- `axios-ollama` (1 online)
- `axios-immich` (1 online)

### Test from Client

```bash
# Should return HTTP 200
curl -I https://axios-mail.your-tailnet.ts.net
curl -I https://axios-ollama.your-tailnet.ts.net
curl -I https://axios-immich.your-tailnet.ts.net
```

## Troubleshooting

### Services Not Appearing in Admin Console

1. Verify auth key has `tag:server`
2. Check `autoApprovers.services` in ACL
3. Ensure `authMode = "authkey"` in NixOS config
4. Check systemd service: `systemctl status tailscale-serve-axios-mail`

### Client Can't Access Services (Connection Timeout)

1. Verify `acceptRoutes = true` on client (default)
2. Check route: `ip route get <service-vip>`
3. Should route through `tailscale0`, not `wlan0`/`eth0`

### PWA Icons Still Shared

1. Clear PWA profile: `rm -rf ~/.local/share/axios-pwa/<service>`
2. Relaunch from desktop entry (not bookmark)
3. Verify StartupWMClass in desktop entry matches window app_id

### Server Can't Access Own Services

This is expected - Tailscale Services has a hairpinning restriction. Servers use local domains via `/etc/hosts`:
- `axios-mail.local` → `127.0.0.1`
- etc.

## Service DNS Names

| Service | DNS Name | Config Path |
|---------|----------|-------------|
| Mail (PIM) | `axios-mail.<tailnet>.ts.net` | `services.pim` |
| Ollama | `axios-ollama.<tailnet>.ts.net` | `services.ai.local` |
| Immich | `axios-immich.<tailnet>.ts.net` | `axios.immich` |

## References

- [Tailscale Services Documentation](https://tailscale.com/kb/1552/tailscale-services)
- [Tailscale Serve](https://tailscale.com/kb/1312/serve)
- [Tailscale Auth Keys](https://tailscale.com/kb/1085/auth-keys)
- [Tailscale ACLs](https://tailscale.com/kb/1018/acls)
