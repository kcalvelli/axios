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
          dockerCompat = false;
          defaultNetwork.settings = {
            dns_enabled = true;
          };
        };
        docker = {
          enable = true;
        };
      };
      users.users.${username}.extraGroups = [ "docker" ];
      environment.systemPackages = with pkgs; [
        winboat
        freerdp
      ];
      # Uncomment if you want to use waydroid
      #virtualisation.waydroid.enable = true;
    })

    (lib.mkIf cfg.libvirt.enable {
      # === Virtualization Packages ===
      environment.systemPackages = with pkgs; [
        virt-manager
        virt-viewer
        qemu
        quickemu
        quickgui
      ];

      # Enable libvirt for VM management
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
          # Configure QEMU security - allow access to user directories
          verbatimConfig = ''
            user = "root"
            group = "root"
            dynamic_ownership = 1
          '';
        };
        # Allow libvirt to access user files
        # This fixes "Permission denied" errors when accessing ISOs in ~/Downloads
        onBoot = "ignore";
        onShutdown = "shutdown";
      };

      # Configure QEMU to run with user permissions
      # This allows access to files in user directories
      security.polkit.enable = true;

      # Allow redirection of USB devices
      virtualisation.spiceUSBRedirection.enable = true;
      services.spice-vdagentd.enable = true;

      # Add users to libvirtd group (managed via users module)
      # users.groups.libvirtd.members will be set by individual user configs
    })
  ];
}
