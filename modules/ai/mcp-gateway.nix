# MCP Gateway - REST API for Model Context Protocol servers
# Exposes axios MCP servers via OpenAPI endpoints with web-based orchestrator UI
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ai.mcpGateway;
  aiCfg = config.services.ai;
  isServer = cfg.role == "server";
  isClient = cfg.role == "client";
  tsCfg = config.networking.tailscale;
in
{
  options.services.ai.mcpGateway = {
    enable = lib.mkEnableOption "MCP Gateway REST API for MCP servers";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client"
      ];
      default = "server";
      description = ''
        MCP Gateway deployment role:
        - "server": Run MCP Gateway service locally
                    Auto-registers as axios-mcp-gateway.<tailnet>.ts.net via Tailscale Services
        - "client": PWA desktop entry only (connects to axios-mcp-gateway.<tailnet>.ts.net)
      '';
    };

    # Server-only options
    port = lib.mkOption {
      type = lib.types.port;
      default = 8085;
      description = "Local port for MCP Gateway service (server role only)";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind to (server role only)";
    };

    autoEnable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "filesystem"
        "git"
        "github"
      ];
      description = ''
        List of MCP server IDs to automatically enable on gateway startup.
        Server IDs must match those configured in ~/.config/mcp/mcp_servers.json
      '';
    };

    # OAuth2 configuration (for Claude.ai Integrations and remote access)
    oauth = {
      enable = lib.mkEnableOption "OAuth2 authentication for remote access";

      provider = lib.mkOption {
        type = lib.types.enum [ "github" ];
        default = "github";
        description = "OAuth2 identity provider";
      };

      githubClientId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "Ov23liXXXXXXXXXXXXXX";
        description = "GitHub OAuth App Client ID";
      };

      githubClientSecretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/run/agenix/mcp-gateway-github-client-secret";
        description = "Path to file containing GitHub OAuth App Client Secret";
      };

      jwtSecretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/run/agenix/mcp-gateway-jwt-secret";
        description = "Path to file containing JWT signing secret";
      };

      baseUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "https://edge.taile0fb4.ts.net:8448";
        description = ''
          Public base URL for OAuth callbacks.
          Required when OAuth is enabled.
        '';
      };

      allowedUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "kcalvelli" ];
        description = ''
          List of GitHub usernames allowed to authenticate.
          Empty list allows all authenticated users.
        '';
      };

      accessTokenExpireMinutes = lib.mkOption {
        type = lib.types.int;
        default = 60;
        description = "Access token expiration time in minutes";
      };

      refreshTokenExpireDays = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Refresh token expiration time in days";
      };
    };

    # PWA configuration (both roles)
    pwa = {
      enable = lib.mkEnableOption "Generate MCP Gateway PWA desktop entry";
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
            services.ai.mcpGateway.pwa.enable requires pwa.tailnetDomain to be set.

            Example:
              services.ai.mcpGateway.pwa.tailnetDomain = "taile0fb4.ts.net";
          '';
        }
        # Server role requires authkey mode for Tailscale Services
        {
          assertion = !(aiCfg.enable && cfg.enable && isServer) || tsCfg.authMode == "authkey";
          message = ''
            services.ai.mcpGateway.role = "server" requires networking.tailscale.authMode = "authkey".

            Server role uses Tailscale Services for HTTPS, which requires tag-based identity.
            Set up an auth key in the Tailscale admin console with appropriate tags.
          '';
        }
        # OAuth requires baseUrl
        {
          assertion = !(aiCfg.enable && cfg.enable && cfg.oauth.enable) || cfg.oauth.baseUrl != null;
          message = ''
            services.ai.mcpGateway.oauth.enable requires oauth.baseUrl to be set.

            Example:
              services.ai.mcpGateway.oauth.baseUrl = "https://edge.taile0fb4.ts.net:8448";
          '';
        }
        # OAuth requires githubClientId
        {
          assertion = !(aiCfg.enable && cfg.enable && cfg.oauth.enable) || cfg.oauth.githubClientId != "";
          message = ''
            services.ai.mcpGateway.oauth.enable requires oauth.githubClientId to be set.

            Example:
              services.ai.mcpGateway.oauth.githubClientId = "Ov23liXXXXXXXXXXXXXX";
          '';
        }
        # OAuth requires secret files
        {
          assertion =
            !(aiCfg.enable && cfg.enable && cfg.oauth.enable)
            || (cfg.oauth.githubClientSecretFile != null && cfg.oauth.jwtSecretFile != null);
          message = ''
            services.ai.mcpGateway.oauth.enable requires secret files to be configured.

            Example with agenix:
              services.ai.mcpGateway.oauth.githubClientSecretFile = config.age.secrets.mcp-gateway-github-client-secret.path;
              services.ai.mcpGateway.oauth.jwtSecretFile = config.age.secrets.mcp-gateway-jwt-secret.path;
          '';
        }
      ];
    }

    # Server role: Run MCP Gateway locally
    (lib.mkIf (aiCfg.enable && cfg.enable && isServer) {
      # Install the gateway package
      environment.systemPackages = [ pkgs.mcp-gateway ];

      # Systemd service for MCP Gateway
      systemd.user.services.mcp-gateway = {
        description = "MCP Gateway REST API";
        wantedBy = [ "default.target" ];
        after = [ "network.target" ];

        # npx-based MCP servers need bash, node, and coreutils in PATH
        path = [
          pkgs.bash
          pkgs.coreutils
          pkgs.nodejs
        ];

        environment = {
          MCP_GATEWAY_HOST = cfg.host;
          MCP_GATEWAY_PORT = toString cfg.port;
          MCP_GATEWAY_AUTO_ENABLE = lib.concatStringsSep "," cfg.autoEnable;
        }
        // lib.optionalAttrs cfg.oauth.enable {
          MCP_GATEWAY_OAUTH_ENABLED = "true";
          MCP_GATEWAY_OAUTH_PROVIDER = cfg.oauth.provider;
          MCP_GATEWAY_GITHUB_CLIENT_ID = cfg.oauth.githubClientId;
          MCP_GATEWAY_GITHUB_CLIENT_SECRET_FILE = toString cfg.oauth.githubClientSecretFile;
          MCP_GATEWAY_JWT_SECRET_FILE = toString cfg.oauth.jwtSecretFile;
          MCP_GATEWAY_BASE_URL = cfg.oauth.baseUrl;
          MCP_GATEWAY_ALLOWED_USERS = lib.concatStringsSep "," cfg.oauth.allowedUsers;
          MCP_GATEWAY_ACCESS_TOKEN_EXPIRE_MINUTES = toString cfg.oauth.accessTokenExpireMinutes;
          MCP_GATEWAY_REFRESH_TOKEN_EXPIRE_DAYS = toString cfg.oauth.refreshTokenExpireDays;
        };

        serviceConfig = {
          ExecStart = "${pkgs.mcp-gateway}/bin/mcp-gateway";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      # Tailscale Services registration
      # Provides unique DNS name: axios-mcp-gateway.<tailnet>.ts.net
      networking.tailscale.services."axios-mcp-gateway" = {
        enable = true;
        backend = "http://${cfg.host}:${toString cfg.port}";
      };

      # Local hostname for server PWA (hairpinning workaround)
      networking.hosts = {
        "127.0.0.1" = [ "axios-mcp-gateway.local" ];
      };
    })

    # Client role: No service, just PWA desktop entry
    # (PWA generation happens in home-manager module)
  ];
}
