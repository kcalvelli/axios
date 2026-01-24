# Proposal: Tailscale Server Identity & Services Integration

## Status: Critical

## Problem Statement

PWAs served from the same Tailscale hostname (e.g., `edge.tailnet.ts.net`) on different ports receive identical Wayland app_ids from Chromium/Brave. This causes:

1. **Identical dock icons** - All PWAs share the same icon
2. **Window grouping issues** - Can't distinguish apps in task switchers
3. **No workaround** - Chromium ignores `--class` flag on Wayland

The root cause: Brave generates app_id from domain only, stripping port numbers.

## Solution: Tailscale Services

Tailscale Services provide unique DNS names per service:
- `axios-mail.tailnet.ts.net` → Mail PWA
- `axios-chat.tailnet.ts.net` → Open WebUI PWA
- `axios-ollama.tailnet.ts.net` → Ollama API

Each service gets a distinct hostname → distinct Brave app_id → distinct icon.

**Requirement**: Tailscale Services require tag-based device identity, not user-owned devices.

## Architecture Change

### Current State
```
edge (user-owned)
├── axios-ai-mail    → https://edge.tailnet:8443
├── axios-ai-chat    → https://edge.tailnet:8444
└── ollama           → https://edge.tailnet:8447

All PWAs get app_id: brave-edge.tailnet.ts.net__-Default
```

### Target State
```
edge (tag:axios-server)
├── svc:axios-mail   → https://axios-mail.tailnet.ts.net
├── svc:axios-chat   → https://axios-chat.tailnet.ts.net
└── svc:axios-ollama → https://axios-ollama.tailnet.ts.net

PWA app_ids:
- brave-axios-mail.tailnet.ts.net-Default
- brave-axios-chat.tailnet.ts.net-Default
```

## Implementation Design

### 1. Tailscale Auth Mode Option

Add to networking/tailscale module:

```nix
networking.tailscale = {
  enable = true;

  # NEW: Authentication mode
  authMode = lib.mkOption {
    type = lib.types.enum [ "interactive" "authkey" ];
    default = "interactive";
    description = ''
      Authentication mode:
      - "interactive": User logs in via browser (default, user-owned)
      - "authkey": Use pre-provisioned auth key (tag-based, for servers)
    '';
  };

  # NEW: Auth key secret (required when authMode = "authkey")
  authKeySecret = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Name of agenix secret containing Tailscale auth key";
  };

  # NEW: Tags for this device (used with authkey mode)
  tags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "axios-server" ];
    description = "Tailscale tags for this device (requires authkey mode)";
  };
};
```

### 2. Tailscale Services Option

Add service advertisement:

```nix
networking.tailscale.services = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "this Tailscale service";
      port = lib.mkOption {
        type = lib.types.port;
        description = "HTTPS port for the service";
        default = 443;
      };
      backend = lib.mkOption {
        type = lib.types.str;
        description = "Backend URL (e.g., http://127.0.0.1:8080)";
      };
    };
  });
  default = { };
  example = {
    "axios-mail" = {
      enable = true;
      port = 443;
      backend = "http://127.0.0.1:8080";
    };
  };
};
```

### 3. Service Auto-Registration

When modules enable services, they auto-register with Tailscale Services:

```nix
# In modules/pim/default.nix (server role)
config = lib.mkIf (cfg.enable && isServer) {
  networking.tailscale.services."axios-mail" = {
    enable = true;
    backend = "http://127.0.0.1:${toString cfg.port}";
  };
};

# In modules/ai/webui.nix (server role)
config = lib.mkIf (cfg.enable && isServer) {
  networking.tailscale.services."axios-chat" = {
    enable = true;
    backend = "http://127.0.0.1:${toString cfg.port}";
  };
};
```

### 4. PWA URL Generation

Update PWA modules to use service DNS names:

```nix
# Instead of: https://edge.tailnet:8443
# Generate:   https://axios-mail.tailnet.ts.net

pwaUrl = "https://${serviceName}.${tailnetDomain}/";
```

### 5. Systemd Services for Tailscale Serve

Generate systemd services that run `tailscale serve --service`:

```nix
systemd.services."tailscale-service-${name}" = {
  description = "Tailscale Service: ${name}";
  after = [ "tailscaled.service" ];
  wants = [ "tailscaled.service" ];
  wantedBy = [ "multi-user.target" ];

  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    ExecStart = "${pkgs.tailscale}/bin/tailscale serve --service=\"svc:${name}\" --https=${toString port} ${backend}";
    ExecStop = "${pkgs.tailscale}/bin/tailscale serve --service=\"svc:${name}\" --https=${toString port} off";
  };
};
```

## User Setup Requirements

### 1. Create Auth Key in Tailscale Admin

1. Go to Tailscale Admin Console → Settings → Keys
2. Generate auth key with:
   - Tags: `tag:axios-server`
   - Reusable: Yes (for rebuilds)
   - Expiration: No expiry (or manage rotation)

### 2. Create ACL Rules

```json
{
  "tagOwners": {
    "tag:axios-server": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:axios-server:*"]
    }
  ]
}
```

### 3. Store Auth Key in Agenix

```bash
echo "tskey-auth-xxxxx" | agenix -e secrets/tailscale-server-key.age
```

### 4. Configure Host

```nix
# hosts/edge.nix
{
  networking.tailscale = {
    enable = true;
    authMode = "authkey";
    authKeySecret = "tailscale-server-key";
    tags = [ "axios-server" ];
  };

  # Services auto-register when enabled
  services.ai.webui.enable = true;
  pim.enable = true;
}
```

## Migration Path

1. **Phase 1**: Add new options (backwards compatible)
   - `authMode = "interactive"` remains default
   - Existing setups continue working

2. **Phase 2**: User migrates server
   - Create auth key and ACLs
   - Switch `authMode = "authkey"`
   - Rebuild and re-authenticate

3. **Phase 3**: Services auto-register
   - PWAs get unique URLs
   - Icons work correctly

## Files to Create/Modify

| File | Changes |
|------|---------|
| `modules/networking/tailscale.nix` | New file: Tailscale auth mode and services |
| `modules/networking/default.nix` | Import tailscale.nix |
| `modules/pim/default.nix` | Register as Tailscale service |
| `modules/ai/webui.nix` | Register as Tailscale service |
| `modules/ai/default.nix` | Register Ollama as Tailscale service |
| `home/pim/default.nix` | Update PWA URL generation |
| `home/ai/webui.nix` | Update PWA URL generation |
| `pkgs/pwa-apps/default.nix` | Support service-based URLs |

## Dependencies

- Tailscale v1.86.0+ (for Services support)
- Agenix for auth key storage
- User must configure ACLs in Tailscale admin

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Auth key exposure | Store in agenix, proper permissions |
| ACL misconfiguration | Document clearly, provide examples |
| Service name conflicts | Use `axios-` prefix for all services |
| Migration disruption | Backwards compatible, opt-in |

## Success Criteria

1. ✅ Server machines use tag-based identity
2. ✅ Each axios service has unique DNS name
3. ✅ PWAs have distinct Wayland app_ids
4. ✅ Icons display correctly in dock
5. ✅ Client machines (user-owned) connect to services
6. ✅ Mobile devices access services via Tailscale

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Research & Design | 2 hours (done) |
| Tailscale module | 4 hours |
| Service auto-registration | 2 hours |
| PWA URL updates | 2 hours |
| Testing & Migration | 3 hours |
| Documentation | 2 hours |
| **Total** | **~15 hours** |

## References

- [Tailscale Services](https://tailscale.com/kb/1552/tailscale-services)
- [Tailscale Serve](https://tailscale.com/kb/1312/serve)
- [Tailscale Auth Keys](https://tailscale.com/kb/1085/auth-keys)
- [Chromium Wayland app_id issue](https://bugs.chromium.org/p/chromium/issues/detail?id=118613)
