# PIM Module: axios-ai-mail integration
# Provides AI-powered email management with server/client role support
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.pim;
  isServer = cfg.role == "server";
  tsCfg = config.networking.tailscale;
in
{
  # Import axios-ai-mail NixOS module (provides services.axios-ai-mail options)
  # This is always imported; the service is only enabled for server role
  imports = [ inputs.axios-ai-mail.nixosModules.default ];

  options.services.pim = {
    enable = lib.mkEnableOption "Personal Information Management (axios-ai-mail)";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client"
      ];
      default = "server";
      description = ''
        PIM deployment role:
        - "server": Run axios-ai-mail backend service (requires AI module)
                    Auto-registers as axios-mail.<tailnet>.ts.net via Tailscale Services
        - "client": PWA desktop entry only (connects to axios-mail.<tailnet>.ts.net)
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

    sync = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable background sync service (server role only)";
      };
      frequency = lib.mkOption {
        type = lib.types.str;
        default = "5m";
        description = "Sync frequency (systemd timer format)";
      };
    };

    # PWA options (both roles)
    pwa = {
      enable = lib.mkEnableOption "Generate axios-ai-mail PWA desktop entry";
      tailnetDomain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "taile0fb4.ts.net";
        description = "Tailscale tailnet domain for PWA URL generation";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.pwa.enable || cfg.pwa.tailnetDomain != null;
        message = ''
          services.pim.pwa.enable requires pwa.tailnetDomain to be set.

          Example:
            services.pim.pwa.tailnetDomain = "taile0fb4.ts.net";
        '';
      }
      {
        assertion = !isServer || cfg.user != "";
        message = ''
          services.pim.role = "server" requires services.pim.user to be set.

          Example:
            services.pim.user = "keith";
        '';
      }
      {
        assertion = !isServer || config.services.ai.enable;
        message = ''
          axiOS configuration error: PIM server role requires AI module.

          You have:
            modules.pim = true
            services.pim.role = "server"
            modules.ai = false (or services.ai.enable = false)

          axios-ai-mail server requires Ollama for email classification.

          Fix by either:
            modules.ai = true;  # Enable AI module (default)
          Or:
            services.pim.role = "client";  # Use client role (PWA only, no AI needed)
        '';
      }
      {
        assertion = !isServer || tsCfg.authMode == "authkey";
        message = ''
          services.pim.role = "server" requires networking.tailscale.authMode = "authkey".

          Server role uses Tailscale Services for HTTPS, which requires tag-based identity.
          Set up an auth key in the Tailscale admin console with appropriate tags.
        '';
      }
    ];

    # Server role: import axios-ai-mail overlay and configure service
    nixpkgs.overlays = lib.mkIf isServer [ inputs.axios-ai-mail.overlays.default ];

    services.axios-ai-mail = lib.mkIf isServer {
      enable = true;
      port = cfg.port;
      user = cfg.user;
      sync = {
        enable = cfg.sync.enable;
        frequency = cfg.sync.frequency;
      };
    };

    # Tailscale Services registration
    # Provides unique DNS name: axios-mail.<tailnet>.ts.net
    networking.tailscale.services."axios-mail" = lib.mkIf isServer {
      enable = true;
      backend = "http://127.0.0.1:${toString cfg.port}";
    };

    # Local hostname for server PWA (hairpinning workaround)
    # Server can't access its own Tailscale Services VIPs, so we use a local domain
    # This gives unique app_id for PWA icons on the server
    networking.hosts = lib.mkIf isServer {
      "127.0.0.1" = [ "axios-mail.local" ];
    };

    # Calendar/contacts sync is handled by axios-dav
    # See: https://github.com/kcalvelli/axios-dav
  };
}
