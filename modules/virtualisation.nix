{ config, lib, pkgs, ... }:
let
  cfg = config.virt;
in
{
  # Create options to enable containers and virtualisation
  options = {
    virt.containers = {
      enable = lib.mkEnableOption "Enable containers";
    };
    virt.libvirt = {
      enable = lib.mkEnableOption "Enable libvirt";
    };
  };

  # Enable and configure containers with podman
  config = lib.mkMerge [
    (lib.mkIf cfg.containers.enable {
      virtualisation = {
        oci-containers.backend = lib.mkDefault "podman";
        podman = {
          enable = true;
          dockerCompat = true;
          defaultNetwork.settings = {
            dns_enabled = true;
          };
        };
      };
      # Uncomment if you want to use waydroid
      #virtualisation.waydroid.enable = true;
    })

    (lib.mkIf cfg.libvirt.enable {
      # Enable libvirt for VM management
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
        };
      };

      # === Virtualization Packages ===
      environment.systemPackages = with pkgs; [
        virt-manager
        virt-viewer
        qemu
        quickemu
        quickgui
      ];

      # Allow redirection of USB devices
      virtualisation.spiceUSBRedirection.enable = true;
      services.spice-vdagentd.enable = true;
      
      # Add users to libvirtd group (managed via users module)
      # users.groups.libvirtd.members will be set by individual user configs
    })
  ];
}
