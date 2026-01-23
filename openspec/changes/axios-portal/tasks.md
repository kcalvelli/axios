# Tasks: axios Portal PWA

## Overview

Create an axios Portal - a service discovery dashboard that lists all available axios services on the user's tailnet.

**Depends On**:
- Open WebUI Integration (proposal #2)
- Port Registry Governance (proposal #3)

---

## Phase 1: Module Definition

### Task 1.1: Create Portal Module
- [ ] Create `modules/portal/default.nix`
- [ ] Register in `modules/default.nix`
- [ ] Add to `lib/default.nix` flaggedModules

```bash
mkdir -p modules/portal
touch modules/portal/default.nix
```

### Task 1.2: Define Module Options
- [ ] Add `services.portal.enable` option
- [ ] Add `services.portal.port` option (default 8082)
- [ ] Add `services.portal.tailscaleServe.*` options
- [ ] Add `services.portal.pwa.*` options

```nix
# modules/portal/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.portal;
in
{
  options.services.portal = {
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
  };

  config = lib.mkIf cfg.enable {
    # Implementation follows
  };
}
```

---

## Phase 2: Service Discovery

### Task 2.1: Define Service Registry Structure
- [ ] Create internal option `services.portal.services`
- [ ] Define service submodule (name, icon, port, healthEndpoint)

```nix
services = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule {
    options = {
      name = lib.mkOption { type = lib.types.str; };
      icon = lib.mkOption { type = lib.types.str; };
      port = lib.mkOption { type = lib.types.port; };
      healthEndpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  });
  internal = true;
  default = { };
};
```

### Task 2.2: Auto-Discover axios Services
- [ ] Check for axios-ai-mail configuration
- [ ] Check for Open WebUI configuration
- [ ] Check for Ollama API configuration
- [ ] Check for future services (calendar, photos)

```nix
config = lib.mkIf cfg.enable {
  services.portal.services = {
    mail = lib.mkIf (config.pim.enable or false && config.pim.tailscaleServe.enable or false) {
      name = "Axios AI Mail";
      icon = "axios-ai-mail";
      port = config.pim.tailscaleServe.httpsPort or 8443;
      healthEndpoint = "/api/health";
    };

    chat = lib.mkIf (config.services.ai.webui.enable or false && config.services.ai.webui.tailscaleServe.enable or false) {
      name = "Axios AI Chat";
      icon = "axios-ai-chat";
      port = config.services.ai.webui.tailscaleServe.httpsPort or 8444;
      healthEndpoint = "/health";
    };

    ollama = lib.mkIf (config.services.ai.local.tailscaleServe.enable or false) {
      name = "Ollama API";
      icon = "axios-ollama";
      port = config.services.ai.local.tailscaleServe.httpsPort or 8447;
      healthEndpoint = "/api/version";
    };
  };
};
```

---

## Phase 3: Static HTML Generation

### Task 3.1: Create HTML Template
- [ ] Design responsive grid layout
- [ ] Style service cards
- [ ] Add status indicator CSS
- [ ] Mobile-friendly viewport

### Task 3.2: Generate Portal HTML in Home Module
- [ ] Create `home/portal/default.nix`
- [ ] Generate `index.html` from service configuration
- [ ] Include inline CSS and JavaScript

```nix
# home/portal/default.nix
{ config, lib, pkgs, osConfig, ... }:

let
  portalCfg = osConfig.services.portal or { };
  services = portalCfg.services or { };
  tailnetDomain = portalCfg.pwa.tailnetDomain or "";
  hostname = osConfig.networking.hostName or "localhost";

  generateServiceCard = name: svc: ''
    <a href="https://${hostname}.${tailnetDomain}:${toString svc.port}/"
       class="card"
       data-health="${svc.healthEndpoint or ""}"
       data-port="${toString svc.port}">
      <div class="status-indicator" id="status-${name}"></div>
      <img src="icons/${svc.icon}.png" alt="${svc.name}">
      <span class="name">${svc.name}</span>
      <span class="port">:${toString svc.port}</span>
    </a>
  '';

  html = ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>axios Portal</title>
      <style>
        * { box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: #1a1a2e;
          color: #eee;
          margin: 0;
          padding: 20px;
          min-height: 100vh;
        }
        h1 {
          text-align: center;
          color: #88c0d0;
          margin-bottom: 30px;
        }
        .services {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
          gap: 20px;
          max-width: 800px;
          margin: 0 auto;
        }
        .card {
          background: #2d2d44;
          border-radius: 12px;
          padding: 20px;
          text-align: center;
          text-decoration: none;
          color: inherit;
          transition: transform 0.2s, box-shadow 0.2s;
          position: relative;
        }
        .card:hover {
          transform: translateY(-4px);
          box-shadow: 0 8px 25px rgba(0,0,0,0.3);
        }
        .card img {
          width: 64px;
          height: 64px;
          margin-bottom: 10px;
        }
        .card .name {
          display: block;
          font-weight: 600;
          margin-bottom: 4px;
        }
        .card .port {
          font-size: 0.8em;
          color: #888;
        }
        .status-indicator {
          position: absolute;
          top: 10px;
          right: 10px;
          width: 12px;
          height: 12px;
          border-radius: 50%;
          background: #666;
        }
        .status-indicator.online { background: #4caf50; }
        .status-indicator.offline { background: #f44336; }
        .legend {
          text-align: center;
          margin-top: 30px;
          color: #888;
          font-size: 0.9em;
        }
      </style>
    </head>
    <body>
      <h1>axios Portal</h1>
      <div class="services">
        ${lib.concatStrings (lib.mapAttrsToList generateServiceCard (lib.filterAttrs (_: s: s.enabled) services))}
      </div>
      <div class="legend">
        <span style="color: #4caf50;">●</span> Online
        <span style="color: #f44336; margin-left: 15px;">●</span> Offline
      </div>
      <script>
        // Health check on load
        document.querySelectorAll('.card').forEach(card => {
          const health = card.dataset.health;
          const port = card.dataset.port;
          const indicator = card.querySelector('.status-indicator');

          if (health) {
            fetch(card.href + health.replace(/^\\//, ""))
              .then(r => r.ok ? indicator.classList.add('online') : indicator.classList.add('offline'))
              .catch(() => indicator.classList.add('offline'));
          } else {
            // No health endpoint, try basic fetch
            fetch(card.href)
              .then(r => indicator.classList.add('online'))
              .catch(() => indicator.classList.add('offline'));
          }
        });
      </script>
    </body>
    </html>
  '';
in
{
  config = lib.mkIf (portalCfg.enable or false) {
    # Generate portal HTML
    home.file.".local/share/axios-portal/index.html".text = html;

    # Copy service icons
    home.file.".local/share/axios-portal/icons/axios-ai-mail.png".source =
      ../resources/pwa-icons/axios-ai-mail.png;
    home.file.".local/share/axios-portal/icons/axios-ai-chat.png".source =
      ../resources/pwa-icons/axios-ai-chat.png;
    # Add more icons as services are added
  };
}
```

---

## Phase 4: HTTP Server

### Task 4.1: Choose Server Approach
- [ ] Option A: Python http.server (simplest)
- [ ] Option B: Caddy (if already in use)
- [ ] Option C: nginx (lightweight)

### Task 4.2: Implement Server Service
- [ ] Create systemd user service to serve portal
- [ ] Serve from `~/.local/share/axios-portal/`
- [ ] Listen on configured port

```nix
# Simple Python server approach
systemd.user.services.axios-portal = {
  Unit = {
    Description = "axios Portal HTTP server";
    After = [ "network.target" ];
  };
  Service = {
    Type = "simple";
    WorkingDirectory = "%h/.local/share/axios-portal";
    ExecStart = "${pkgs.python3}/bin/python -m http.server ${toString portalCfg.port}";
    Restart = "on-failure";
  };
  Install = {
    WantedBy = [ "default.target" ];
  };
};
```

### Task 4.3: Configure Tailscale Serve
- [ ] When `tailscaleServe.enable = true`, expose portal
- [ ] Map `:httpsPort` → `localhost:port`

---

## Phase 5: PWA Desktop Entry

### Task 5.1: Create Icon
- [ ] Design icon: NixOS snowflake + axios colors + grid/dashboard center
- [ ] Create 128x128 PNG
- [ ] Save to `home/resources/pwa-icons/axios-portal.png`

### Task 5.2: Generate Desktop Entry
- [ ] Create desktop entry in home module
- [ ] Set correct URL and StartupWMClass

```nix
xdg.desktopEntries.axios-portal = lib.mkIf (portalCfg.pwa.enable or false) {
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

home.file.".local/share/icons/hicolor/128x128/apps/axios-portal.png" = {
  source = ../resources/pwa-icons/axios-portal.png;
};
```

---

## Phase 6: Documentation

### Task 6.1: Create Portal Spec
- [ ] Create `openspec/specs/portal/spec.md`
- [ ] Document service auto-discovery
- [ ] Document adding new services

### Task 6.2: Update Related Docs
- [ ] Add portal to `docs/MODULE_REFERENCE.md`
- [ ] Update `CLAUDE.md` with portal info

---

## Phase 7: Testing

### Task 7.1: Service Discovery Tests
- [ ] Test: Mail service discovered when configured
- [ ] Test: Chat service discovered when configured
- [ ] Test: Empty portal when no services
- [ ] Test: Only enabled services shown

### Task 7.2: HTML Generation Tests
- [ ] Test: HTML valid
- [ ] Test: Service cards render
- [ ] Test: Links point to correct URLs
- [ ] Test: Mobile responsive

### Task 7.3: Server Tests
- [ ] Test: Portal accessible on configured port
- [ ] Test: Static files served correctly
- [ ] Test: Health checks work

### Task 7.4: PWA Tests
- [ ] Test: Desktop entry created
- [ ] Test: Icon displays correctly
- [ ] Test: Opens in app mode

---

## Phase 8: Finalization

### Task 8.1: Code Review
- [ ] Auto-discovery pattern is extensible
- [ ] HTML/CSS is clean and maintainable
- [ ] Service works reliably

### Task 8.2: Merge Specs
- [ ] Move specs to `openspec/specs/`
- [ ] Archive change directory

---

## Files to Create

| File | Purpose |
|------|---------|
| `modules/portal/default.nix` | NixOS module |
| `home/portal/default.nix` | Home module (HTML gen, PWA) |
| `home/resources/pwa-icons/axios-portal.png` | Portal icon |
| `openspec/specs/portal/spec.md` | Portal specification |

## Files to Modify

| File | Changes |
|------|---------|
| `modules/default.nix` | Register portal module |
| `lib/default.nix` | Add to flaggedModules |
| `home/default.nix` | Import portal home module |
| `docs/MODULE_REFERENCE.md` | Document portal |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Module Definition | 1 hour |
| Phase 2: Service Discovery | 2 hours |
| Phase 3: HTML Generation | 3 hours |
| Phase 4: HTTP Server | 1 hour |
| Phase 5: PWA | 1 hour |
| Phase 6: Documentation | 1 hour |
| Phase 7: Testing | 2 hours |
| Phase 8: Finalization | 30 min |
| **Total** | **~12 hours** |

---

## Open Questions

1. **Server choice**: Python http.server is simplest but not production-grade. Is that acceptable for internal tailnet use?

2. **Dynamic updates**: Should portal auto-refresh, or is manual refresh sufficient?

3. **Multi-host**: Future enhancement - show services across multiple tailnet hosts?
