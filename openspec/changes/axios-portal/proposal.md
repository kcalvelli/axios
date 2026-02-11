# Proposal: axios Portal PWA

## Summary

Create an axios Portal - a service discovery dashboard that lists all available axios services on the user's tailnet, providing a unified entry point for the axios ecosystem.

## Motivation

### Problem Statement

As axios expands its service ecosystem, users face discovery challenges:

1. **Multiple URLs to remember**: Each service has its own `host:port` combination
2. **No central dashboard**: Users must bookmark each service individually
3. **Status visibility**: No easy way to see which services are running
4. **Mobile friction**: Adding multiple PWAs on phone is tedious

### Solution

Create an axios Portal - a lightweight web dashboard that:

- Lists all configured axios services
- Shows service status (online/offline)
- Provides quick links to each service
- Works as the primary PWA for mobile users

## Proposed Design

### Portal Interface

```
┌─────────────────────────────────────────────────────────────────┐
│                        axios Portal                              │
│                    edge.tailnet.ts.net                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   ● Mail    │  │   ● Chat    │  │  ○ Photos   │             │
│  │             │  │             │  │             │             │
│  │  [envelope] │  │   [chat]    │  │  [camera]   │             │
│  │             │  │             │  │             │             │
│  │   :8443     │  │   :8444     │  │   :8450     │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │  ● Calendar │  │   ● API     │                               │
│  │             │  │             │                               │
│  │ [calendar]  │  │  [ollama]   │                               │
│  │             │  │             │                               │
│  │   :8446     │  │   :8447     │                               │
│  └─────────────┘  └─────────────┘                               │
│                                                                  │
│  ● = Online    ○ = Offline                                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Features

1. **Service Cards**: Visual tiles for each axios service
2. **Status Indicators**: Green (online), red (offline), gray (not configured)
3. **Quick Launch**: Click card to open service in new tab
4. **Responsive**: Works on desktop and mobile
5. **Auto-Discovery**: Reads from axios configuration
6. **Health Checks**: Periodic ping to verify service availability

## Proposed Changes

### New Module: services.portal

```nix
services.portal = {
  enable = lib.mkEnableOption "axios Portal service discovery dashboard";

  port = lib.mkOption {
    type = lib.types.port;
    default = 8082;
    description = "Local port for axios Portal";
  };

  tailscaleServe = {
    enable = lib.mkEnableOption "Expose Portal via Tailscale HTTPS";
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8445;
      description = "HTTPS port for Tailscale serve";
    };
  };

  pwa = {
    enable = lib.mkEnableOption "Generate Portal PWA desktop entry";
    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Tailscale tailnet domain";
    };
  };

  # Auto-populated from other axios services
  # Users don't configure this directly
  services = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule { ... });
    internal = true;
    description = "Auto-discovered axios services";
  };
};
```

### Service Auto-Discovery

The portal automatically discovers configured axios services:

```nix
config = lib.mkIf cfg.portal.enable {
  services.portal.services = {
    mail = lib.mkIf (config.pim.enable or false) {
      name = "Axios AI Mail";
      icon = "axios-ai-mail";
      port = config.pim.tailscaleServe.httpsPort;
      healthEndpoint = "/api/health";
    };

    ollama = lib.mkIf (config.services.ai.local.tailscaleServe.enable or false) {
      name = "Ollama API";
      icon = "axios-ollama";
      port = config.services.ai.local.tailscaleServe.httpsPort;
      healthEndpoint = "/api/version";
    };

    # ... other services
  };
};
```

### Implementation Options

#### Option A: Static HTML Generator (Recommended for v1)

Generate static HTML at build time from Nix configuration:

```nix
# Generate portal HTML from service configuration
home.file.".local/share/axios-portal/index.html".text = ''
  <!DOCTYPE html>
  <html>
  <head>
    <title>axios Portal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      /* Responsive grid of service cards */
    </style>
  </head>
  <body>
    <h1>axios Portal</h1>
    <div class="services">
      ${lib.concatMapStrings (svc: ''
        <a href="https://${hostname}.${tailnet}:${svc.port}/" class="card">
          <img src="${svc.icon}.png" alt="${svc.name}">
          <span>${svc.name}</span>
        </a>
      '') (lib.attrValues cfg.services)}
    </div>
    <script>
      // Client-side health checks via fetch
    </script>
  </body>
  </html>
'';
```

Serve via simple HTTP server (caddy, nginx, or python http.server).

#### Option B: Dynamic Service (Future)

Full web application with:
- Real-time health monitoring
- Service metrics
- User authentication
- Notifications

**Deferred**: Static generation is sufficient for initial release.

### PWA Desktop Entry

```nix
xdg.desktopEntries.axios-portal = {
  name = "Axios Portal";
  comment = "Service discovery dashboard for axios ecosystem";
  exec = "${lib.getExe pkgs.brave} --app=${portalUrl}";
  icon = "axios-portal";
  terminal = false;
  categories = [ "Network" "System" ];
  settings = {
    StartupWMClass = urlToAppId portalUrl;
  };
};
```

### Icon Design

Following axios icon pattern:
- Base: NixOS snowflake with axios colors
- Center element: Grid/dashboard icon (4 squares)
- File: `home/resources/pwa-icons/axios-portal.png`

## Configuration Example

```nix
{
  # Portal is auto-configured based on enabled services
  services.portal = {
    enable = true;

    tailscaleServe = {
      enable = true;
      httpsPort = 8445;
    };

    pwa = {
      enable = true;
      tailnetDomain = "taile0fb4.ts.net";
    };
  };

  # These services auto-register with portal
  pim.enable = true;
  pim.tailscaleServe.enable = true;

  services.ai.webui.enable = true;
  services.ai.webui.tailscaleServe.enable = true;
}
```

## Port Allocation

| Service | Local Port | Tailscale Port |
|---------|------------|----------------|
| axios-ai-mail | 8080 | 8443 |
| Open WebUI | 8081 | 8444 |
| **axios Portal** | **8082** | **8445** |
| axios-calendar | 8083 | 8446 |
| Ollama API | 11434 | 8447 |

## Mobile Experience

The Portal becomes the **primary entry point** for mobile users:

1. Install Tailscale app
2. Join tailnet
3. Navigate to `https://edge.tailnet:8445/`
4. Add Portal to home screen
5. Access all axios services from one place

**Benefits**:
- Single PWA to install
- No need to remember individual ports
- Visual service status
- Responsive mobile layout

## Dependencies

- **Requires**: At least one axios service with Tailscale serve
- **Optional**: All other axios services (auto-discovered)
- **Requires**: Port Registry Governance (for documentation)

## Testing Requirements

- [ ] Portal generates with no services (empty state)
- [ ] Portal shows configured services
- [ ] Service cards link to correct URLs
- [ ] Health checks work (online/offline indicators)
- [ ] PWA desktop entry created
- [ ] Responsive on mobile viewport
- [ ] Works when some services offline

## Future Enhancements

- Service metrics (uptime, response time)
- Quick actions (restart service, view logs)
- Notifications (service went down)
- Multi-host support (show services across tailnet)
- Custom service registration (non-axios services)

## Alternatives Considered

### Alternative 1: Homepage (gethomepage.dev)

Existing dashboard solution with many integrations.

**Rejected**: Overkill for axios, doesn't auto-discover axios services.

### Alternative 2: Organizr

Another dashboard solution.

**Rejected**: PHP-based, heavy, not Nix-native.

### Alternative 3: No portal, just bookmarks

Let users manage their own bookmarks.

**Rejected**: Poor mobile UX, no status visibility, axios should be cohesive.

## References

- axios-ai-mail PWA: `home/pim/default.nix`
- Tailscale serve documentation
- PWA best practices
