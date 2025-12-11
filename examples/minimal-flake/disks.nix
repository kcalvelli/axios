# Disk configuration extracted from hardware-configuration.nix
# This contains only filesystem mounts and swap devices
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Root filesystem
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
  };

  # Boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # NOTE: Replace UUIDs with your actual disk UUIDs!
  # Find them with: lsblk -f or blkid
}
