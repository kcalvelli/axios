# Implementation Tasks: PIM axios-ai-mail Migration

## Phase 1: Flake Integration

- [ ] **1.1** Add axios-ai-mail flake input to `flake.nix`
  ```nix
  axios-ai-mail = {
    url = "github:kcalvelli/axios-ai-mail";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```

- [ ] **1.2** Verify `inputs` passes through to modules via `specialArgs` in `lib/default.nix`
  - Already passes `inputs` via specialArgs (line 437)
  - Test input availability in both NixOS and home-manager modules

## Phase 2: AI Module Default Change

- [ ] **2.1** Update `lib/default.nix` to default `modules.ai` to `true`
  - Change line 264: `lib.optional (hostCfg.modules.ai or false) ai`
  - To: `lib.optional (hostCfg.modules.ai or true) ai`

- [ ] **2.2** Add PIM server role requires AI assertion in `lib/default.nix` validation module
  ```nix
  {
    assertion = !(modules.pim or false)
      || (config.pim.role or "server") != "server"
      || (modules.ai or true);
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

- [ ] **2.3** Update `lib/default.nix` line 330-332 to use new default
  ```nix
  # Enable AI module if specified (now defaults to true)
  (lib.optionalAttrs (hostCfg.modules.ai or true) {
    services.ai.enable = true;
  })
  ```

- [ ] **2.4** Update `lib/default.nix` line 391 for home-manager AI module
  ```nix
  ++ lib.optional (hostCfg.modules.ai or true) self.homeModules.ai;
  ```

## Phase 3: Installer Update

- [ ] **3.1** Remove AI prompt from `scripts/init-config.sh`
  - Delete lines 228: `ENABLE_AI=$(prompt_bool ...)`
  - Set `ENABLE_AI="true"` as hardcoded value

- [ ] **3.2** Remove AI from configuration summary display
  - Delete line 275: `echo "  AI Services: $ENABLE_AI"`

- [ ] **3.3** Update template substitutions (keep `{{ENABLE_AI}}` but always `true`)
  - Or remove `{{ENABLE_AI}}` from templates and hardcode `true`

- [ ] **3.4** Update `scripts/templates/host.nix.template`
  - Remove `modules.ai = {{ENABLE_AI}};` line (defaults to true now)

## Phase 4: NixOS Module Rewrite

- [ ] **4.1** Rewrite `modules/pim/default.nix` with role-based architecture:
  ```nix
  { config, lib, pkgs, inputs, ... }:
  let
    cfg = config.pim;
    isServer = cfg.role == "server";
  in
  {
    options.pim = {
      enable = lib.mkEnableOption "Personal Information Management (axios-ai-mail)";

      role = lib.mkOption {
        type = lib.types.enum [ "server" "client" ];
        default = "server";
        description = ''
          PIM deployment role:
          - "server": Run axios-ai-mail backend service (requires AI module)
          - "client": PWA desktop entry only (connects to server on tailnet)
        '';
      };

      # Server-only options
      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port for axios-ai-mail web UI (server role only)";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "User to run axios-ai-mail service as (server role only)";
      };

      tailscaleServe = {
        enable = lib.mkEnableOption "Expose via Tailscale HTTPS (server role only)";
        httpsPort = lib.mkOption {
          type = lib.types.port;
          default = 8443;
        };
      };

      sync = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        frequency = lib.mkOption {
          type = lib.types.str;
          default = "5m";
        };
      };

      # PWA options (both roles)
      pwa = {
        enable = lib.mkEnableOption "Generate PWA desktop entry";
        serverHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "edge";
          description = ''
            Hostname of axios-ai-mail server on tailnet.
            - null: Use local hostname (for server role)
            - "edge": Connect to edge.tailnet.ts.net (for client role)
          '';
        };
        tailnetDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "taile0fb4.ts.net";
          description = "Tailscale tailnet domain for PWA URL";
        };
        httpsPort = lib.mkOption {
          type = lib.types.port;
          default = 8443;
          description = "HTTPS port of the axios-ai-mail server";
        };
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !cfg.pwa.enable || cfg.pwa.tailnetDomain != null;
          message = ''
            pim.pwa.enable requires pim.pwa.tailnetDomain to be set.

            Example:
              pim.pwa.tailnetDomain = "taile0fb4.ts.net";
          '';
        }
        {
          assertion = cfg.role != "client" || cfg.pwa.serverHost != null;
          message = ''
            pim.role = "client" requires pim.pwa.serverHost to be set.

            Example:
              pim.pwa.serverHost = "edge";  # hostname of your PIM server
          '';
        }
        {
          assertion = !isServer || cfg.user != "";
          message = ''
            pim.role = "server" requires pim.user to be set.

            Example:
              pim.user = "keith";
          '';
        }
      ];

      # Server role: import axios-ai-mail overlay and service
      nixpkgs.overlays = lib.mkIf isServer [ inputs.axios-ai-mail.overlays.default ];

      services.axios-ai-mail = lib.mkIf isServer {
        enable = true;
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

      # Keep vdirsyncer for calendar sync (both roles)
      environment.systemPackages = [ pkgs.vdirsyncer ];
    };
  }
  ```

- [ ] **4.2** Remove all GNOME PIM components:
  - Remove Geary overlay
  - Remove `pim.emailClient` option
  - Remove gnome-online-accounts-gtk
  - Remove gnome-calendar
  - Remove gnome-contacts
  - Remove evolution-ews
  - Remove services.gnome.evolution-data-server
  - Remove services.gnome.gnome-online-accounts
  - Remove services.geoclue2 (if only used for gnome-calendar)

## Phase 5: Home-Manager Module Creation

- [ ] **5.1** Create `home/pim/default.nix` with role-based PWA URL generation:
  ```nix
  { config, lib, pkgs, inputs, osConfig, ... }:
  let
    cfg = config.programs.axios-ai-mail;
    pimCfg = osConfig.pim or {};
    isServer = (pimCfg.role or "server") == "server";

    # Helper for PWA URL generation (supports both server and client roles)
    pwaUrl =
      let
        # Client role uses serverHost, server role uses local hostname
        effectiveHost =
          if pimCfg.pwa.serverHost or null != null
          then pimCfg.pwa.serverHost
          else osConfig.networking.hostName;
        domain = pimCfg.pwa.tailnetDomain or "";
        port = toString (pimCfg.pwa.httpsPort or 8443);
      in
      "https://${effectiveHost}.${domain}:${port}/";

    # Brave app-id for StartupWMClass
    urlToAppId = url: let
      withoutProtocol = lib.removePrefix "https://" url;
      parts = lib.splitString "/" withoutProtocol;
      domain = lib.head parts;
    in "brave-${domain}-Default";
  in
  {
    # Only import axios-ai-mail home module for server role
    imports = lib.optional (isServer && inputs ? axios-ai-mail)
      inputs.axios-ai-mail.homeManagerModules.default;

    config = lib.mkIf (pimCfg.enable or false) {
      # PWA desktop entry (both server and client roles)
      xdg.desktopEntries.axios-ai-mail = lib.mkIf (pimCfg.pwa.enable or false) {
        name = "Axios AI Mail";
        comment = "AI-powered email management";
        exec = "${lib.getExe pkgs.brave} --app=${pwaUrl}";
        icon = "axios-ai-mail";
        terminal = false;
        categories = [ "Network" "Email" ];
        settings = {
          StartupWMClass = urlToAppId pwaUrl;
        };
      };

      # Install PWA icon
      home.file.".local/share/icons/hicolor/128x128/apps/axios-ai-mail.png" =
        lib.mkIf (pimCfg.pwa.enable or false) {
          source = ../../home/resources/pwa-icons/mail.png;
        };
    };
  }
  ```

- [ ] **5.2** Add mail icon to `home/resources/pwa-icons/mail.png`
  - Copy from user's nixos_config or create new

- [ ] **5.3** Register home module in `home/default.nix`:
  ```nix
  pim = ./pim;
  ```

- [ ] **5.4** Update `modules/desktop/default.nix` to import home PIM module:
  - Add `pim` to `home-manager.sharedModules` when desktop enabled

- [ ] **5.5** Update `lib/default.nix` to import home PIM module:
  - Add to sharedModules: `++ lib.optional (hostCfg.modules.pim or false) self.homeModules.pim`

## Phase 6: Documentation Updates

- [ ] **6.1** Update `openspec/specs/desktop/spec.md` PIM section:
  ```markdown
  ### Personal Information Management (PIM)

  **Email**: axios-ai-mail - AI-powered email management with local LLM classification.
  - Multi-account support (Gmail OAuth, IMAP/SMTP)
  - Privacy-first local processing via Ollama
  - Modern web UI with PWA support
  - Tailscale integration for cross-device access

  **Calendar**: vdirsyncer + khal + PWA apps
  - Automated CalDAV sync via systemd timers
  - khal CLI for DMS calendar widget integration
  - PWA apps for graphical interface (user's choice)

  **Contacts**: Cloud provider UIs or PWA apps
  - Future: axios-ai-mail contacts module (planned)

  **Implementation**:
  - `modules/pim/default.nix` (system services)
  - `home/pim/default.nix` (user configuration)
  - See `openspec/specs/pim/spec.md` for full documentation
  ```

- [ ] **6.2** Move `specs/pim/spec.md` to main specs directory:
  ```bash
  mv openspec/changes/pim-axios-ai-mail/specs/pim openspec/specs/
  ```

- [ ] **6.3** Update `CHANGELOG.md`:
  - Document PIM module replacement
  - Document AI module default change
  - List breaking changes

- [ ] **6.4** Update `.claude/project.md` AI Module Specifics section:
  - Note that AI module now defaults to true
  - Document PIM → AI dependency

- [ ] **6.5** Update `docs/MODULE_REFERENCE.md`:
  - Update PIM module documentation
  - Note removed options (emailClient, etc.)

- [ ] **6.6** Update `scripts/README.md`:
  - Remove AI module from "prompted options" list

## Phase 7: Testing

- [ ] **7.1** Test fresh installation:
  - Enable `modules.pim = true`
  - Configure test account
  - Verify service starts
  - Verify PWA desktop entry appears

- [ ] **7.2** Test AI module default:
  - New config with no `modules.ai` specified
  - Verify AI services are enabled

- [ ] **7.3** Test PIM without AI assertion:
  - Set `modules.pim = true` and `modules.ai = false`
  - Verify assertion error is raised

- [ ] **7.4** Test calendar independence:
  - Disable PIM, keep desktop enabled
  - Verify vdirsyncer still works via calendar module

- [ ] **7.5** Test PWA generation (server role):
  - Enable `pim.pwa.enable = true` with tailnetDomain
  - Verify desktop entry created with local hostname
  - Verify icon installed
  - Test PWA assertion without tailnetDomain

- [ ] **7.6** Test client role:
  - Set `pim.role = "client"` and `pim.pwa.serverHost = "edge"`
  - Verify NO axios-ai-mail service is installed
  - Verify AI module is NOT required
  - Verify PWA desktop entry points to server host

- [ ] **7.7** Test client role assertions:
  - Set `pim.role = "client"` WITHOUT `pim.pwa.serverHost`
  - Verify assertion error about serverHost

- [ ] **7.8** Verify CI passes:
  - `nix flake check`
  - `nix fmt -- --check .`

## Phase 8: Finalization

- [ ] **8.1** Archive change directory:
  ```bash
  mv openspec/changes/pim-axios-ai-mail openspec/changes/archive/
  ```

- [ ] **8.2** Create commit with comprehensive message documenting:
  - PIM module replacement with axios-ai-mail
  - AI module default changed to true
  - Breaking changes for existing users
  - Migration steps

- [ ] **8.3** Push changes and notify users of breaking change
