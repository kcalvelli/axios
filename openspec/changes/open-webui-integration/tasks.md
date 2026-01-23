# Tasks: Open WebUI Integration

## Overview

Add Open WebUI as an axios service with server/client roles, Tailscale serve integration, and PWA desktop entry generation.

**Depends On**: AI Module Server/Client Refactor (proposal #1)

---

## Phase 1: Research and Preparation

### Task 1.1: Verify Open WebUI in nixpkgs
- [ ] Check `nixpkgs` for `open-webui` package
- [ ] Verify package version and options
- [ ] Document any packaging gaps

```bash
nix search nixpkgs open-webui
nix eval nixpkgs#open-webui.meta
```

### Task 1.2: Test Open WebUI Manually
- [ ] Run Open WebUI in a test environment
- [ ] Verify Ollama integration works
- [ ] Identify required environment variables
- [ ] Document default port and configuration

---

## Phase 2: NixOS Module Creation

### Task 2.1: Create Module Structure
- [ ] Create `modules/ai/webui.nix`
- [ ] Import in `modules/ai/default.nix`

```bash
touch modules/ai/webui.nix
```

### Task 2.2: Define Module Options
- [ ] Add `services.ai.webui.enable` option
- [ ] Add `services.ai.webui.role` option (server/client)
- [ ] Add `services.ai.webui.port` option (default 8081)
- [ ] Add `services.ai.webui.ollama.endpoint` option
- [ ] Add `services.ai.webui.tailscaleServe.*` options
- [ ] Add `services.ai.webui.pwa.*` options

```nix
# modules/ai/webui.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.ai.webui;
in
{
  options.services.ai.webui = {
    enable = lib.mkEnableOption "Open WebUI for AI chat interface";

    role = lib.mkOption {
      type = lib.types.enum [ "server" "client" ];
      default = "server";
      description = ''
        Open WebUI deployment role:
        - "server": Run Open WebUI service locally
        - "client": PWA desktop entry only
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Local port for Open WebUI service";
    };

    ollama.endpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:11434";
      description = "Ollama API endpoint";
    };

    tailscaleServe = {
      enable = lib.mkEnableOption "Expose Open WebUI via Tailscale HTTPS";
      httpsPort = lib.mkOption {
        type = lib.types.port;
        default = 8444;
        description = "HTTPS port for Tailscale serve";
      };
    };

    pwa = {
      enable = lib.mkEnableOption "Generate Open WebUI PWA desktop entry";
      serverHost = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hostname of Open WebUI server (null = local)";
      };
      tailnetDomain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Tailscale tailnet domain";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Implementation in subsequent tasks
  };
}
```

### Task 2.3: Implement Server Role
- [ ] Enable `services.open-webui` when role == "server"
- [ ] Configure Ollama endpoint
- [ ] Set privacy-preserving environment variables
- [ ] Configure Tailscale serve when enabled

```nix
config = lib.mkMerge [
  # Server role
  (lib.mkIf (cfg.enable && cfg.role == "server") {
    services.open-webui = {
      enable = true;
      port = cfg.port;
      environment = {
        OLLAMA_BASE_URL = cfg.ollama.endpoint;
        SCARF_NO_ANALYTICS = "true";
        DO_NOT_TRACK = "true";
        ANONYMIZED_TELEMETRY = "false";
      };
    };
  })

  # Tailscale serve (server role only)
  (lib.mkIf (cfg.enable && cfg.role == "server" && cfg.tailscaleServe.enable) {
    # Tailscale serve configuration
  })
];
```

### Task 2.4: Add Assertions
- [ ] Assert PWA requires tailnetDomain
- [ ] Assert client role requires serverHost

```nix
assertions = [
  {
    assertion = !cfg.pwa.enable || cfg.pwa.tailnetDomain != null;
    message = "services.ai.webui.pwa.enable requires pwa.tailnetDomain";
  }
  {
    assertion = cfg.role != "client" || cfg.pwa.serverHost != null;
    message = "services.ai.webui.role = \"client\" requires pwa.serverHost";
  }
];
```

---

## Phase 3: Home-Manager Module (PWA)

### Task 3.1: Create Home Module
- [ ] Create `home/ai/webui.nix`
- [ ] Import in `home/ai/default.nix` or `home/ai/mcp.nix`

### Task 3.2: Implement PWA Desktop Entry
- [ ] Generate desktop entry when `pwa.enable = true`
- [ ] Calculate correct URL based on role and serverHost
- [ ] Set StartupWMClass for Brave PWA

```nix
# home/ai/webui.nix
{ config, lib, pkgs, osConfig, ... }:

let
  webuiCfg = osConfig.services.ai.webui or { };
  isEnabled = webuiCfg.enable or false;
  pwaEnabled = webuiCfg.pwa.enable or false;

  effectiveHost =
    if webuiCfg.pwa.serverHost or null != null
    then webuiCfg.pwa.serverHost
    else osConfig.networking.hostName or "localhost";

  tailnetDomain = webuiCfg.pwa.tailnetDomain or "";
  httpsPort = toString (webuiCfg.tailscaleServe.httpsPort or 8444);
  pwaUrl = "https://${effectiveHost}.${tailnetDomain}:${httpsPort}/";

  urlToAppId = url:
    let
      withoutProtocol = lib.removePrefix "https://" url;
      parts = lib.splitString "/" withoutProtocol;
      domainWithPort = lib.head parts;
      domain = lib.head (lib.splitString ":" domainWithPort);
    in
    "brave-${domain}__-Default";
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    xdg.desktopEntries.axios-ai-chat = {
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

    home.file.".local/share/icons/hicolor/128x128/apps/axios-ai-chat.png" = {
      source = ../resources/pwa-icons/axios-ai-chat.png;
    };
  };
}
```

---

## Phase 4: Icon Creation

### Task 4.1: Design Icon
- [ ] Follow axios icon pattern (NixOS snowflake + axios colors)
- [ ] Add chat bubble as center element
- [ ] Create 128x128 PNG

### Task 4.2: Add Icon to Resources
- [ ] Save to `home/resources/pwa-icons/axios-ai-chat.png`
- [ ] Verify icon displays correctly in desktop environment

---

## Phase 5: Integration with AI Module

### Task 5.1: Import webui.nix
- [ ] Add import to `modules/ai/default.nix`

```nix
# modules/ai/default.nix
{
  imports = [
    ./webui.nix
  ];
  # ... existing config
}
```

### Task 5.2: Auto-configure Ollama Endpoint for Client
- [ ] When `services.ai.local.role == "client"`, auto-set webui.ollama.endpoint
- [ ] Use same remote Ollama URL

```nix
# If local role is client, webui should use same remote endpoint
services.ai.webui.ollama.endpoint = lib.mkIf
  (config.services.ai.local.role == "client")
  "https://${config.services.ai.local.serverHost}.${config.services.ai.local.tailnetDomain}:${toString config.services.ai.local.tailscaleServe.httpsPort}";
```

---

## Phase 6: Documentation

### Task 6.1: Update Module Documentation
- [ ] Add webui section to `docs/MODULE_REFERENCE.md`
- [ ] Include server and client configuration examples

### Task 6.2: Update AI Spec
- [ ] Add webui to `openspec/specs/ai/spec.md`
- [ ] Document PWA access pattern

### Task 6.3: Add to CLAUDE.md
- [ ] Document Open WebUI in AI module section
- [ ] Add mobile access instructions

---

## Phase 7: Testing

### Task 7.1: Server Role Tests
- [ ] Test: Open WebUI service starts
- [ ] Test: Connects to local Ollama
- [ ] Test: Tailscale serve exposes correctly
- [ ] Test: Web UI accessible via browser

### Task 7.2: Client Role Tests
- [ ] Test: No service installed for client role
- [ ] Test: PWA desktop entry created
- [ ] Test: PWA URL points to remote server

### Task 7.3: PWA Tests
- [ ] Test: Icon displays in app launcher
- [ ] Test: StartupWMClass matches Brave window
- [ ] Test: PWA opens in app mode (no browser chrome)

### Task 7.4: Mobile Tests (Manual)
- [ ] Test: Access from phone via Tailscale
- [ ] Test: Add to home screen works
- [ ] Test: Chat functionality on mobile

---

## Phase 8: Finalization

### Task 8.1: Code Review Checklist
- [ ] Options follow axios patterns
- [ ] Server/client pattern matches axios-ai-mail
- [ ] PWA generation matches existing pattern
- [ ] Privacy settings configured

### Task 8.2: Merge Specs
- [ ] Move updated specs to `openspec/specs/`
- [ ] Archive this change directory

---

## Files to Modify

| File | Changes |
|------|---------|
| `modules/ai/default.nix` | Import webui.nix |
| `home/ai/default.nix` | Import home webui module |
| `openspec/specs/ai/spec.md` | Document Open WebUI |
| `docs/MODULE_REFERENCE.md` | Add webui documentation |

## Files to Create

| File | Purpose |
|------|---------|
| `modules/ai/webui.nix` | NixOS module for Open WebUI |
| `home/ai/webui.nix` | Home-manager module for PWA |
| `home/resources/pwa-icons/axios-ai-chat.png` | PWA icon |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Research | 1 hour |
| Phase 2: NixOS Module | 2 hours |
| Phase 3: Home Module | 1 hour |
| Phase 4: Icon | 1 hour |
| Phase 5: Integration | 1 hour |
| Phase 6: Documentation | 1 hour |
| Phase 7: Testing | 2 hours |
| Phase 8: Finalization | 30 min |
| **Total** | **~10 hours** |

---

## Open Questions

1. **Open WebUI authentication**: Should we configure user authentication, or rely on Tailscale for access control?

2. **Data persistence**: Where should Open WebUI store conversation history? Default or configurable?

3. **Multi-user**: Should we support multiple users with separate conversations?
