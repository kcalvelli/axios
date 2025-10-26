{ lib, config, ... }:
{
  # Define Niri options
  options.niri = {
    enable = lib.mkEnableOption "Enable Niri";
  };

  # Configure Niri if enabled
  config = lib.mkIf config.niri.enable {
    programs = {
      niri = {
        enable = true;
      };
    };
  };
}
