# Disk configuration extracted from hardware-configuration.nix
# This contains only filesystem mounts and swap devices
{
  config,
  lib,
  pkgs,
  ...
}:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
  };

  # Additional data partition
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY";
    fsType = "ext4";
  };

  swapDevices = [ ];
}
