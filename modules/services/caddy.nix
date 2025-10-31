{ config, lib, ... }:

{
  # Caddy is always enabled when services module is loaded
  # This allows individual services to add their own virtualHosts
  config = {
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
  };
}
