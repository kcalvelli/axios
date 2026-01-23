# Proposal: Replace PIM Module with axios-ai-mail

## Summary

Replace axiOS's current GTK/GNOME-based Personal Information Management (PIM) module with **axios-ai-mail**, a purpose-built AI-powered email management system. This is a clean replacement—no legacy fallback option.

## Problem Statement

### Current State Pain Points

1. **Email Client Quality**: Available Linux email clients (Geary, Evolution) have significant UX limitations:
   - Geary: Modern but feature-limited, poor keyboard navigation
   - Evolution: Dated UI, resource-heavy, complexity without proportional benefit
   - All: Poor AI/automation integration, no local-first intelligence

2. **Office365/Outlook Non-Functional**: The current PIM module documents that evolution-ews is installed but "Office365/Outlook integration is currently non-functional."

3. **GNOME Ecosystem Lock-in**: Current PIM requires GNOME Online Accounts + Evolution Data Server as backends.

4. **No AI Integration**: Email classification, tagging, and smart replies require manual effort.

### Production Validation

axios-ai-mail has been in exclusive production use on the axiOS maintainer's system (`edge` host). The integration pattern is proven and stable.

## Decisions (from review)

1. **No legacy mode** - Remove all GNOME Online Accounts and GNOME PIM ecosystem entirely
2. **PWA via declarative option** - Generate desktop entry when user provides tailnet domain
3. **Contacts** - Leave alone; will be pursued in axios-ai-mail separately
4. **`pim.enable`** = enable axios-ai-mail directly (no `pim.legacy`)
5. **`modules.ai` defaults to `true`** - Remove from installer prompt; require `ai=true` when `pim=true`

## Proposed Solution

### Architecture

| Component | Current | Proposed |
|-----------|---------|----------|
| **Email** | Geary/Evolution (GTK apps) | axios-ai-mail (web UI + systemd) |
| **Calendar UI** | GNOME Calendar | PWA apps (user's choice) |
| **Calendar Sync** | vdirsyncer + EDS | vdirsyncer (unchanged) |
| **Calendar Widget** | khal (DMS) | khal (unchanged) |
| **Contacts** | GNOME Contacts | Cloud provider UI / future axios-ai-mail |
| **Account Config** | GNOME Online Accounts | Declarative Nix config |
| **Backend Services** | EDS + GOA D-Bus | SQLite + systemd |

### Removed Components (Clean Break)

- GNOME Online Accounts (`gnome-online-accounts-gtk`)
- GNOME Calendar (`gnome-calendar`)
- GNOME Contacts (`gnome-contacts`)
- Evolution Data Server (`services.gnome.evolution-data-server`)
- Evolution EWS (`evolution-ews`)
- Geary (email client)
- Geary overlay patch
- `pim.emailClient` option

### Multi-Host Architecture (Server/Client Roles)

**Challenge**: Users may have multiple axiOS hosts on their Tailnet:
- **Server host** (e.g., `edge`): Runs axios-ai-mail backend, Ollama, SQLite database
- **Client hosts** (e.g., `pangolin`): Only need PWA desktop entry pointing to the server

**Solution**: Add a `role` option to distinguish server vs client configurations:

```nix
# edge (SERVER - runs axios-ai-mail service)
pim = {
  enable = true;
  role = "server";  # Default - runs backend service
  user = "keith";

  tailscaleServe = {
    enable = true;
    httpsPort = 8443;
  };

  pwa = {
    enable = true;
    tailnetDomain = "taile0fb4.ts.net";
  };
};

# pangolin (CLIENT - PWA only, connects to edge)
pim = {
  enable = true;
  role = "client";  # No service, no AI dependency

  pwa = {
    enable = true;
    serverHost = "edge";  # Point to server, not local hostname
    tailnetDomain = "taile0fb4.ts.net";
    httpsPort = 8443;
  };
};
```

**Role Differences**:

| Aspect | `role = "server"` | `role = "client"` |
|--------|-------------------|-------------------|
| axios-ai-mail service | ✅ Runs | ❌ Not installed |
| Ollama/AI dependency | ✅ Required | ❌ Not needed |
| SQLite database | ✅ Local | ❌ None |
| Background sync | ✅ Enabled | ❌ None |
| PWA URL hostname | Local hostname | `serverHost` value |

### PWA Desktop Entry Solution

**Challenge**: The axios-ai-mail URL is dynamic, depending on:
- Machine hostname (or server hostname for clients)
- Tailscale tailnet domain
- HTTPS port

**URL Generation Logic**:
```nix
effectiveHost =
  if cfg.pwa.serverHost != null
  then cfg.pwa.serverHost      # Client: use specified server
  else config.networking.hostName;  # Server: use local hostname

pwaUrl = "https://${effectiveHost}.${cfg.pwa.tailnetDomain}:${toString cfg.pwa.httpsPort}/";
```

**Implementation**: Generate an XDG desktop entry in the home-manager module with:
- Icon: Bundled with axios (mail icon in `home/resources/pwa-icons/`)
- StartupWMClass: Computed from URL for proper window matching
- Categories: `[ "Network" "Email" ]`

This approach:
- Keeps configuration declarative
- Works with existing PWA infrastructure patterns
- Doesn't require modifying `pwa-apps` package
- Handles the dynamic URL cleanly
- Supports multi-host Tailnet deployments

### AI Module Dependency

**New defaults:**
- `modules.ai` defaults to `true` (currently `false`)
- Installer no longer prompts for AI module

**New assertion (server role only):**
```nix
{
  assertion = !(hostCfg.modules.pim or false)
    || (config.pim.role or "server") != "server"
    || (hostCfg.modules.ai or true);
  message = ''
    axiOS configuration error: PIM server role requires AI module.

    You have:
      modules.pim = true
      pim.role = "server"
      modules.ai = false

    axios-ai-mail server requires Ollama for email classification.

    Fix by either:
      modules.ai = true;  # Enable AI module
    Or:
      pim.role = "client";  # Use client role (PWA only, no AI needed)
  '';
}
```

### Integration Pattern

```nix
# flake.nix - Add input
inputs.axios-ai-mail = {
  url = "github:kcalvelli/axios-ai-mail";
  inputs.nixpkgs.follows = "nixpkgs";  # ADR-008 compliance
};

# modules/pim/default.nix - Complete rewrite
{
  nixpkgs.overlays = [ inputs.axios-ai-mail.overlays.default ];
  imports = [ inputs.axios-ai-mail.nixosModules.default ];

  services.axios-ai-mail = {
    enable = cfg.enable;
    port = cfg.port;
    user = cfg.user;
    tailscaleServe = {
      enable = cfg.tailscaleServe.enable;
      httpsPort = cfg.tailscaleServe.httpsPort;
    };
    sync = {
      enable = cfg.sync.enable;
      frequency = cfg.sync.frequency;
    };
  };
}

# home/pim/default.nix - New module
{
  imports = [ inputs.axios-ai-mail.homeManagerModules.default ];

  programs.axios-ai-mail = {
    enable = true;
    accounts = cfg.accounts;
    ai = cfg.ai;
  };

  # PWA desktop entry (conditional)
  xdg.desktopEntries.axios-ai-mail = lib.mkIf cfg.pwa.enable { ... };
}
```

## Benefits

1. **Better Email UX**: AI-powered classification, modern responsive UI, keyboard shortcuts
2. **Privacy**: Local AI processing via Ollama
3. **Declarative Config**: Email accounts configured in Nix, not GUI
4. **Reduced Dependencies**: No GNOME Online Accounts or Evolution Data Server
5. **Cross-Device Access**: Tailscale integration for secure access
6. **Clean Architecture**: No legacy cruft or fallback complexity

## Migration Path

### For Existing PIM Users

1. **Email**: Configure accounts in new `pim.accounts` option (home-manager)
2. **Calendar**: No change required (vdirsyncer continues working)
3. **Contacts**: Use cloud provider web UI or await axios-ai-mail contacts feature

### Breaking Changes

- `pim.emailClient` option removed
- GNOME Calendar no longer installed by default
- GNOME Contacts no longer installed by default
- Users must configure email accounts in Nix

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| axios-ai-mail is newer | Proven in production use; calendar/contacts via other means |
| Requires Ollama | AI module now default; required assertion prevents misconfiguration |
| Web UI only | PWA provides app-like experience; cross-device benefit |

## Related Documents

- axios-ai-mail repo: `~/Projects/axios-ai-mail`
- Production integration: `~/.config/nixos_config/mail.nix`
- Current PIM: `modules/pim/default.nix`
