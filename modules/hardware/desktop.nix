{ config, lib, ... }:
let
  cfg = config.hardware.desktop;
  cpuType = config.axios.hardware.cpuType or null;
in
{
  imports = [ ./common.nix ];

  options.hardware.desktop = {
    enable = lib.mkEnableOption "Desktop workstation hardware configuration";

    enableLogitechSupport = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Logitech wireless peripheral support";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Create plugdev group for hardware device access
      users.groups.plugdev = { };

      # Kernel modules for desktop workstations
      boot = {
        kernelModules =
          [ ]
          ++ lib.optionals (cpuType == "amd") [ "kvm-amd" ]
          ++ lib.optionals (cpuType == "intel") [ "kvm-intel" ];

        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];
      };

      # Desktop power policy - use powersave for universal compatibility
      # Modern AMD (amd-pstate-epp) and Intel cpufreq drivers provide
      # intelligent frequency scaling with the powersave governor
      powerManagement = {
        enable = true;
        cpuFreqGovernor = lib.mkDefault "powersave";
      };

      # Desktop services
      services = {
        fstrim.enable = true; # Weekly TRIM for SSD
        irqbalance.enable = true; # Better multi-core interrupt handling
        power-profiles-daemon.enable = lib.mkForce false; # Not useful on desktops
      };
    })

    # Logitech peripheral support (opt-in)
    (lib.mkIf (cfg.enable && cfg.enableLogitechSupport) {
      hardware = {
        # Logitech Unifying receiver support
        logitech.wireless.enable = true;
        logitech.wireless.enableGraphical = true;
      };

      # Additional udev rules for Logitech device access via plugdev group
      services.udev.extraRules = ''
        # Logitech Unifying receiver - ensure plugdev group has access
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", MODE="0660", GROUP="plugdev"
        # Lenovo nano receiver
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="6042", MODE="0660", GROUP="plugdev"
      '';
    })
  ];
}
