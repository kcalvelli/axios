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
  cfg = config.pim;
  isServer = cfg.role == "server";
  tsCfg = config.networking.tailscale;
  useServices = tsCfg.authMode == "authkey";
in
{
  # Import axios-ai-mail NixOS module (provides services.axios-ai-mail options)
  # This is always imported; the service is only enabled for server role
  imports = [ inputs.axios-ai-mail.nixosModules.default ];

  options.pim = {
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
      enable = lib.mkEnableOption "Expose axios-ai-mail via Tailscale HTTPS (server role only)";
      httpsPort = lib.mkOption {
        type = lib.types.port;
        default = 8443;
        description = "HTTPS port for Tailscale serve";
      };
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
        description = "Tailscale tailnet domain for PWA URL generation";
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
      {
        assertion = !isServer || config.services.ai.enable;
        message = ''
          axiOS configuration error: PIM server role requires AI module.

          You have:
            modules.pim = true
            pim.role = "server"
            modules.ai = false (or services.ai.enable = false)

          axios-ai-mail server requires Ollama for email classification.

          Fix by either:
            modules.ai = true;  # Enable AI module (default)
          Or:
            pim.role = "client";  # Use client role (PWA only, no AI needed)
        '';
      }
    ];

    # Server role: import axios-ai-mail overlay and configure service
    nixpkgs.overlays = lib.mkIf isServer [ inputs.axios-ai-mail.overlays.default ];

    services.axios-ai-mail = lib.mkIf isServer {
      enable = true;
      port = cfg.port;
      user = cfg.user;
      # Legacy tailscaleServe (only when NOT using Tailscale Services)
      tailscaleServe = lib.mkIf (!useServices) {
        enable = cfg.tailscaleServe.enable;
        httpsPort = cfg.tailscaleServe.httpsPort;
      };
      sync = {
        enable = cfg.sync.enable;
        frequency = cfg.sync.frequency;
      };
    };

    # Tailscale Services registration (when authMode = "authkey")
    # This provides unique DNS name: axios-mail.<tailnet>.ts.net
    networking.tailscale.services."axios-mail" = lib.mkIf (isServer && useServices) {
      enable = true;
      backend = "http://127.0.0.1:${toString cfg.port}";
    };

    # Keep vdirsyncer for calendar sync (both roles)
    environment.systemPackages = [ pkgs.vdirsyncer ];
  };
}
