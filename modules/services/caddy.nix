# Caddy Reverse Proxy with Tailscale HTTPS
# Provides automatic HTTPS certificates from Tailscale for self-hosted services
{ config, lib, pkgs, ... }:

let
  cfg = config.selfHosted;
  tailscaleDomain = config.networking.tailscale.domain;
in
{
  options.selfHosted.caddy = {
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Additional Caddyfile configuration to append.
        Use this for custom reverse proxy entries.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = tailscaleDomain != null;
        message = ''
          selfHosted requires networking.tailscale.domain to be set.

          Find your tailnet domain in the Tailscale admin console under DNS settings.
          Example: networking.tailscale.domain = "tail1234ab.ts.net";
        '';
      }
    ];

    services.caddy = {
      # Global Caddy settings
      globalConfig = ''
        # Use Tailscale for HTTPS certificates
        # Caddy automatically gets certs from local Tailscale daemon for *.ts.net domains

        # Force HTTP/1.1 for WebSocket compatibility
        # HTTP/2 doesn't properly support WebSocket protocol upgrade
        servers {
          protocols h1
        }
      '';

      # Additional config from selfHosted.caddy.extraConfig and service modules
      extraConfig = cfg.caddy.extraConfig;
    };
  };
}
