# Proposal: Open WebUI Integration

## Summary

Add Open WebUI as an axios service with server/client roles, Tailscale serve integration, and PWA desktop entry generation - following the established axios-ai-mail pattern.

## Motivation

### Problem Statement

axios users currently have no mobile-friendly way to interact with their local LLM infrastructure. The only options are:

1. SSH into the server and use CLI tools
2. Use cloud AI services directly (defeats purpose of local LLMs)

### Solution

Integrate Open WebUI - a mature, mobile-friendly web interface for Ollama - following the axios service pattern:

- **Server role**: Run Open WebUI locally, expose via Tailscale
- **Client role**: PWA desktop entry pointing to remote server
- **Mobile access**: Same URL works on phone via Tailscale app

### Why Open WebUI?

| Factor | Open WebUI | Alternatives |
|--------|------------|--------------|
| Maturity | Production-ready | Varies |
| Mobile UX | Excellent | Often poor |
| Ollama integration | Native | Requires config |
| nixpkgs | Already packaged | May need packaging |
| Multi-user | Supported | Often single-user |

## Proposed Changes

### New Module: services.ai.webui

```nix
services.ai.webui = {
  enable = lib.mkEnableOption "Open WebUI for AI chat interface";

  role = lib.mkOption {
    type = lib.types.enum [ "server" "client" ];
    default = "server";
    description = ''
      Open WebUI deployment role:
      - "server": Run Open WebUI service locally
      - "client": PWA desktop entry only (connects to remote server)
    '';
  };

  # Service configuration (server role only)
  port = lib.mkOption {
    type = lib.types.port;
    default = 8081;
    description = "Local port for Open WebUI service";
  };

  ollama = {
    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:11434";
      description = "Ollama API endpoint";
    };
  };

  # Tailscale serve (server role only)
  tailscaleServe = {
    enable = lib.mkEnableOption "Expose Open WebUI via Tailscale HTTPS";
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8444;
      description = "HTTPS port for Tailscale serve";
    };
  };

  # PWA configuration (both roles)
  pwa = {
    enable = lib.mkEnableOption "Generate Open WebUI PWA desktop entry";
    serverHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "edge";
      description = ''
        Hostname of Open WebUI server on tailnet.
        - null: Use local hostname (server role)
        - "edge": Connect to remote server (client role)
      '';
    };
    tailnetDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "taile0fb4.ts.net";
      description = "Tailscale tailnet domain for PWA URL";
    };
  };
};
```

### Server Role Implementation

```nix
config = lib.mkIf (cfg.webui.enable && cfg.webui.role == "server") {
  # Open WebUI service
  services.open-webui = {
    enable = true;
    port = cfg.webui.port;
    environment = {
      OLLAMA_BASE_URL = cfg.webui.ollama.endpoint;
      # Disable telemetry
      SCARF_NO_ANALYTICS = "true";
      DO_NOT_TRACK = "true";
    };
  };

  # Tailscale serve configuration
  # Uses tailscale serve to expose the service
};
```

### Client Role Implementation

```nix
config = lib.mkIf (cfg.webui.enable && cfg.webui.role == "client") {
  # No service installed
  # Only PWA desktop entry via home-manager
};
```

### Home-Manager Module (PWA)

```nix
# home/ai/webui.nix
xdg.desktopEntries.axios-ai-chat = lib.mkIf pwaEnabled {
  name = "Axios AI Chat";
  comment = "AI chat interface powered by local LLMs";
  exec = "${lib.getExe pkgs.brave} --app=${pwaUrl}";
  icon = "axios-ai-chat";
  terminal = false;
  categories = [ "Network" "Chat" "ArtificialIntelligence" ];
  settings = {
    StartupWMClass = urlToAppId pwaUrl;
  };
};

home.file.".local/share/icons/hicolor/128x128/apps/axios-ai-chat.png" =
  lib.mkIf pwaEnabled {
    source = ../resources/pwa-icons/axios-ai-chat.png;
  };
```

## Configuration Examples

### Desktop (Server)

```nix
{
  services.ai = {
    enable = true;

    local = {
      enable = true;
      role = "server";
      tailscaleServe.enable = true;
    };

    webui = {
      enable = true;
      role = "server";

      tailscaleServe = {
        enable = true;
        httpsPort = 8444;
      };

      pwa = {
        enable = true;
        tailnetDomain = "taile0fb4.ts.net";
      };
    };
  };
}
```

### Laptop (Client)

```nix
{
  services.ai = {
    enable = true;

    local = {
      enable = true;
      role = "client";
      serverHost = "edge";
      tailnetDomain = "taile0fb4.ts.net";
    };

    webui = {
      enable = true;
      role = "client";

      pwa = {
        enable = true;
        serverHost = "edge";
        tailnetDomain = "taile0fb4.ts.net";
      };
    };
  };
}
```

## Icon Design

Following axios icon pattern:
- Base: NixOS snowflake with axios colors
- Center element: Chat bubble icon
- File: `home/resources/pwa-icons/axios-ai-chat.png`
- Size: 128x128 PNG

## Port Allocation

| Service | Local Port | Tailscale Port |
|---------|------------|----------------|
| axios-ai-mail | 8080 | 8443 |
| **Open WebUI** | **8081** | **8444** |
| Ollama API | 11434 | 8447 |

## Dependencies

- **Requires**: AI Module Server/Client Refactor (proposal #1)
- **Requires**: Tailscale module
- **Optional**: Port Registry Governance (for documentation)

## Mobile Experience

1. User installs Tailscale app on phone
2. Joins same tailnet as axios server
3. Navigates to `https://edge.tailnet.ts.net:8444/`
4. Adds to home screen as PWA
5. Full AI chat experience, secured by Tailscale

## Testing Requirements

- [ ] Server role: Open WebUI service starts
- [ ] Server role: Connects to local Ollama
- [ ] Server role: Tailscale serve works
- [ ] Client role: No service installed
- [ ] PWA: Desktop entry created with correct URL
- [ ] PWA: Icon installed
- [ ] PWA: StartupWMClass matches Brave
- [ ] Mobile: Accessible via Tailscale
- [ ] Assertion: PWA without tailnetDomain fails
- [ ] Assertion: Client role without serverHost fails

## Alternatives Considered

### Alternative 1: text-generation-webui

More features but heavier, less mobile-friendly, more complex setup.

**Rejected**: Open WebUI has better UX and Ollama integration.

### Alternative 2: Ollama's built-in web UI

Minimal interface, no conversation history, single-model only.

**Rejected**: Too limited for daily use.

### Alternative 3: Build custom axios UI

Maximum control but significant development effort.

**Rejected**: Open WebUI already excellent, better to integrate than rebuild.

## Future Enhancements

- Multi-model switching in PWA
- Shared conversation history across devices
- Integration with axios-ai-mail (summarize emails via chat)
- Voice input via whisper-cpp

## References

- Open WebUI: https://github.com/open-webui/open-webui
- axios-ai-mail pattern: `modules/pim/default.nix`
- PWA generation: `home/pim/default.nix`
