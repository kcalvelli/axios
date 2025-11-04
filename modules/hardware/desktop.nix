{ config, lib, ... }:
let
  cfg = config.hardware.desktop;
in
{
  imports = [ ./common.nix ];

  options.hardware.desktop = {
    enable = lib.mkEnableOption "Desktop workstation hardware configuration";

    enableMsiSensors = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable MSI motherboard sensor support (nct6775)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Create plugdev group for hardware device access
      users.groups.plugdev = { };

      hardware = {
        # Logitech Unifying receiver support (common for desktop peripherals)
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

      # Kernel modules for desktop workstations
      boot = {
        kernelModules = [ "kvm-amd" ];

        kernelParams = lib.optionals cfg.enableMsiSensors [
          "acpi_enforce_resources=lax" # Required for nct6775 on many MSI boards
        ];

        initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];
      };

      # Desktop power policy - schedutil balances performance and efficiency
      powerManagement = {
        enable = true;
        cpuFreqGovernor = "schedutil"; # Scales CPU frequency based on actual load
      };

      # Desktop services
      services = {
        fstrim.enable = true; # Weekly TRIM for SSD
        irqbalance.enable = true; # Better multi-core interrupt handling
        power-profiles-daemon.enable = lib.mkForce false; # Not useful on desktops
      };
    })

    # MSI-specific sensor module
    (lib.mkIf (cfg.enable && cfg.enableMsiSensors) {
      boot.kernelModules = [
        "nct6775" # Super I/O sensors (fans/temps) for many MSI boards
      ];
    })
  ];
}
