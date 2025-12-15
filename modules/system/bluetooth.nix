{ config, lib, ... }:
{
  options.axios.system.bluetooth = {
    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically power on Bluetooth adapters at boot";
    };
  };

  config = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = config.axios.system.bluetooth.powerOnBoot;
    };
  };
}
