# Open WebUI integration for axios
# Provides mobile-friendly AI chat interface with server/client roles
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ai.webui;
  aiCfg = config.services.ai;
  isServer = cfg.role == "server";
  isClient = cfg.role == "client";
  tsCfg = config.networking.tailscale;
in
{
  options.services.ai.webui = {
    enable = lib.mkEnableOption "Open WebUI for AI chat interface";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client"
      ];
      default = "server";
      description = ''
        Open WebUI deployment role:
        - "server": Run Open WebUI service locally
                    Auto-registers as axios-ai-chat.<tailnet>.ts.net via Tailscale Services
        - "client": PWA desktop entry only (connects to axios-ai-chat.<tailnet>.ts.net)
      '';
    };

    # Server-only options
    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Local port for Open WebUI service (server role only)";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind to (server role only)";
    };

    ollama = {
      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:11434";
        description = "Ollama API endpoint URL";
      };
    };

    # PWA configuration (both roles)
    pwa = {
      enable = lib.mkEnableOption "Generate Open WebUI PWA desktop entry";
      tailnetDomain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "taile0fb4.ts.net";
        description = "Tailscale tailnet domain for PWA URL";
      };
    };
  };

  config = lib.mkMerge [
    # Assertions
    {
      assertions = [
        # PWA requires tailnetDomain
        {
          assertion = !(aiCfg.enable && cfg.enable && cfg.pwa.enable) || cfg.pwa.tailnetDomain != null;
          message = ''
            services.ai.webui.pwa.enable requires pwa.tailnetDomain to be set.

            Example:
              services.ai.webui.pwa.tailnetDomain = "taile0fb4.ts.net";
          '';
        }
        # Server role requires authkey mode for Tailscale Services
        {
          assertion = !(aiCfg.enable && cfg.enable && isServer) || tsCfg.authMode == "authkey";
          message = ''
            services.ai.webui.role = "server" requires networking.tailscale.authMode = "authkey".

            Server role uses Tailscale Services for HTTPS, which requires tag-based identity.
            Set up an auth key in the Tailscale admin console with appropriate tags.
          '';
        }
      ];
    }

    # Server role: Run Open WebUI locally
    (lib.mkIf (aiCfg.enable && cfg.enable && isServer) {
      services.open-webui = {
        enable = true;
        port = cfg.port;
        host = cfg.host;
        environment = {
          # Ollama integration
          OLLAMA_BASE_URL = cfg.ollama.endpoint;

          # Privacy: Disable all telemetry
          SCARF_NO_ANALYTICS = "true";
          DO_NOT_TRACK = "true";
          ANONYMIZED_TELEMETRY = "false";

          # Security: Disable signup after first user (rely on Tailscale for access control)
          ENABLE_SIGNUP = "false";
        };
      };

      # Tailscale Services registration
      # Provides unique DNS name: axios-ai-chat.<tailnet>.ts.net
      networking.tailscale.services."axios-ai-chat" = {
        enable = true;
        backend = "http://${cfg.host}:${toString cfg.port}";
      };
    })

    # Client role: No service, just PWA desktop entry
    # (PWA generation happens in home-manager module)
  ];
}
