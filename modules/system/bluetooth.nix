{ config, lib, ... }:
let
  cfg = config.cairn.system.bluetooth;
in
{
  options.cairn.system.bluetooth = {
    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically power on Bluetooth adapters at boot";
    };

    disableSeatMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable WirePlumber's bluez seat monitoring for headless machines without an active logind seat";
    };
  };

  config = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = cfg.powerOnBoot;
      settings.General.Disable = "Headset";
    };

    services.pipewire.wireplumber.extraConfig."10-disable-bluez-seat-monitoring" =
      lib.mkIf cfg.disableSeatMonitoring
        {
          "wireplumber.profiles" = {
            main = {
              "monitor.bluez.seat-monitoring" = "disabled";
            };
          };
        };
  };
}
