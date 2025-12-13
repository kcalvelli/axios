{ config, lib, ... }:
let
  cpuType = config.axios.hardware.cpuType or null;
  isAmd = cpuType == "amd";
  isIntel = cpuType == "intel";
in
{
  options.axios.hardware.cpuType = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.enum [
        "amd"
        "intel"
      ]
    );
    default = null;
    description = "CPU type for hardware-specific configuration";
  };

  config = {
    hardware = {
      # Update AMD CPU microcode if AMD CPU and redistributable firmware is enabled
      cpu.amd.updateMicrocode = lib.mkIf isAmd (
        lib.mkDefault config.hardware.enableRedistributableFirmware
      );
      # Update Intel CPU microcode if Intel CPU and redistributable firmware is enabled
      cpu.intel.updateMicrocode = lib.mkIf isIntel (
        lib.mkDefault config.hardware.enableRedistributableFirmware
      );
      enableAllFirmware = true;
    };
  };
}
