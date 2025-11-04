{ config, lib, ... }:
let
  cfg = config.hardware.laptop;
in
{
  imports = [ ./common.nix ];

  options.hardware.laptop = {
    enable = lib.mkEnableOption "Laptop hardware configuration";

    enableSystem76 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable System76 hardware integration (firmware/power daemon)";
    };

    enablePangolinQuirks = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Pangolin 12 specific quirks (touchpad, Wi-Fi)";
    };
  };

  config = lib.mkMerge [
    # Generic laptop configuration
    (lib.mkIf cfg.enable {
      # Kernel modules for laptops
      boot = {
        kernelModules = [ "kvm-amd" ];
        initrd.availableKernelModules = [ "nvme" "xhci_pci" ];
      };

      # SSD TRIM for laptops
      services.fstrim.enable = true;
    })

    # System76 hardware integration
    (lib.mkIf (cfg.enable && cfg.enableSystem76) {
      hardware.system76 = {
        firmware-daemon.enable = true;
        power-daemon.enable = true;
      };

      # Load System76 ACPI module for keyboard backlight control
      boot.kernelModules = [ "system76_acpi" ];
    })

    # Pangolin 12 specific quirks
    (lib.mkIf (cfg.enable && cfg.enablePangolinQuirks) {
      boot = {
        # Disable PS/2 fallback touchpad for Pangolin 12
        blacklistedKernelModules = [ "psmouse" ];

        # Pangolin 12 Wi-Fi quirk (MediaTek MT7921/MT7922)
        extraModprobeConfig = ''
          options mt7921_common disable_clc=1
        '';
      };
    })
  ];
}
