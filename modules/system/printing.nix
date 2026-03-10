{ config, lib, ... }:
{
  options.axios.system.printing = {
    enable = lib.mkEnableOption "printing services" // {
      default = true;
    };
  };

  config = lib.mkIf config.axios.system.printing.enable {
    services.printing = {
      enable = true;
      openFirewall = true;
    };
    programs.system-config-printer.enable = true;

    # Enable color management for printers and displays
    services.colord.enable = true;
  };
}
