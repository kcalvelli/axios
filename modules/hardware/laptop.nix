{ config, lib, ... }:
let
  cfg = config.hardware.laptop;
  cpuType = config.axios.hardware.cpuType or null;
in
{
  imports = [ ./common.nix ];

  options.hardware.laptop = {
    enable = lib.mkEnableOption "Laptop hardware configuration";
  };

  config = lib.mkIf cfg.enable {
    # Kernel modules for laptops
    boot = {
      kernelModules =
        [ ]
        ++ lib.optionals (cpuType == "amd") [ "kvm-amd" ]
        ++ lib.optionals (cpuType == "intel") [ "kvm-intel" ];
      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
      ];
    };

    # SSD TRIM for laptops
    services.fstrim.enable = true;
  };
}
