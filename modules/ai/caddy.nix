{ config, lib, ... }:
let
  cfg = config.services.ai;
  hasTailscaleDomain = config.networking.tailscale.domain != null;
in
{
  config = lib.mkIf (cfg.enable && hasTailscaleDomain) {
    services.caddy = {
      enable = true;
      globalConfig = ''
        servers {
          metrics
        }
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # Integrate with Tailscale for TLS certificates
    services.tailscale.permitCertUid = config.services.caddy.user;
  };
}
