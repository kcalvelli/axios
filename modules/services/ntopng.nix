{ config, lib, ... }:
let
  cfg = config.services;
in
{
  options = {
    services.ntop = {
      enable = lib.mkEnableOption "ntopng network monitoring (port 3000)";
    };
  };

  config = lib.mkIf cfg.ntop.enable {
    services.ntopng = {
      enable = true;
      # Remove path prefix - access directly via port
    };

    # Open firewall for port access
    networking.firewall.allowedTCPPorts = [ 3000 ];
  };
}
