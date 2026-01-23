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
        - "client": PWA desktop entry only (connects to remote server)
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

    tailscaleServe = {
      enable = lib.mkEnableOption "Expose Open WebUI via Tailscale HTTPS (server role only)";
      httpsPort = lib.mkOption {
        type = lib.types.port;
        default = 8444;
        description = "HTTPS port for Tailscale serve";
      };
    };

    # Client options
    serverHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "edge";
      description = "Hostname of Open WebUI server on tailnet (client role only)";
    };

    serverPort = lib.mkOption {
      type = lib.types.port;
      default = 8444;
      description = "HTTPS port of the remote Open WebUI server (client role only)";
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
        # Client role requires serverHost
        {
          assertion = !(aiCfg.enable && cfg.enable && isClient) || cfg.serverHost != null;
          message = ''
            services.ai.webui.role = "client" requires serverHost to be set.

            Example:
              services.ai.webui.serverHost = "edge";
          '';
        }
        # Tailscale serve only for server role
        {
          assertion = !cfg.tailscaleServe.enable || isServer;
          message = ''
            services.ai.webui.tailscaleServe is only available for server role.

            You have role = "client" with tailscaleServe.enable = true.
            Remove tailscaleServe or set role = "server".
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
    })

    # Server role: Tailscale serve
    (lib.mkIf (aiCfg.enable && cfg.enable && isServer && cfg.tailscaleServe.enable) {
      systemd.services.tailscale-serve-open-webui = {
        description = "Configure Tailscale serve for Open WebUI";
        after = [
          "network-online.target"
          "tailscaled.service"
          "open-webui.service"
        ];
        wants = [
          "network-online.target"
          "tailscaled.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https ${toString cfg.tailscaleServe.httpsPort} http://${cfg.host}:${toString cfg.port}";
          ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https ${toString cfg.tailscaleServe.httpsPort} off";
        };
      };
    })

    # Client role: No service, just ensure serverHost is available for home-manager
    # (PWA generation happens in home-manager module)
  ];
}
