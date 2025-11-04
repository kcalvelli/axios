{ config, lib, ... }:

{
  # Caddy is always enabled when services module is loaded
  # This allows individual services to add their own virtualHosts
  config = lib.mkMerge [
    {
      services.caddy = {
        enable = true;
        globalConfig = ''
          servers {
            metrics
          }
        '';
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    }

    # Integrate with Tailscale if both are enabled
    # This allows Caddy to obtain TLS certificates from Tailscale
    (lib.mkIf config.services.tailscale.enable {
      services.tailscale.permitCertUid = config.services.caddy.user;
    })
  ];
}
