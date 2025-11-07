{ inputs, self, config, lib, ... }:
let
  cfg = config.axios.users;

  # Determine which groups to add based on enabled modules
  autoGroups = lib.lists.unique (lib.flatten [
    # Essential groups for all normal users
    [ "wheel" ] # sudo access

    # Desktop environment groups
    (lib.optionals (config.desktop.enable or false) [
      "networkmanager" # Network management
      "video" # GPU/graphics access
      "input" # Input device access
      "audio" # Audio device access
      "lp" # Printer access
      "scanner" # Scanner access
    ])

    # Graphics-specific groups
    (lib.optionals (config.graphics.enable or false) [
      "video" # GPU access
    ])

    # Virtualization groups
    (lib.optionals (config.virt.libvirt.enable or false) [
      "kvm" # KVM virtualization
      "libvirtd" # Libvirt VM management
      "qemu-libvirtd" # QEMU with libvirt
    ])

    (lib.optionals (config.virt.containers.enable or false) [
      "docker" # Container management (podman-compat)
    ])

    # Hardware-specific groups
    (lib.optionals ((config.hardware.desktop.enable or false) || (config.hardware.laptop.enable or false)) [
      "plugdev" # Device access
    ])

    # Development and admin groups
    (lib.optionals ((config.development.enable or false) || (config.services.enable or false)) [
      "adm" # Log file access
      "disk" # Disk management tools
    ])

    # Additional groups specified by user
    cfg.extraGroups
  ]);
in
{
  options.axios.users = {
    autoGroups = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically add normal users to groups based on enabled axios modules.

        This provides sensible defaults so users don't need to manually specify
        groups like 'wheel', 'networkmanager', 'video', etc. in their user configurations.

        Groups are added based on which modules are enabled:
        - wheel: Always (sudo access)
        - networkmanager, video, input, audio, lp, scanner: desktop module
        - kvm, libvirtd, qemu-libvirtd: virt.libvirt module
        - docker: virt.containers module
        - plugdev: hardware.desktop or hardware.laptop modules
        - adm, disk: development or services modules

        Set to false to disable automatic group management.
      '';
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional groups to automatically add all normal users to.
        These are added in addition to the groups determined by enabled modules.
      '';
      example = [ "dialout" "i2c" ];
    };

    defaultExtraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      default = if cfg.autoGroups then autoGroups else [ ];
      description = ''
        Computed list of groups to automatically add to normal users based on enabled modules.
        Users can reference this in their user definitions: extraGroups = config.axios.users.defaultExtraGroups;
      '';
    };
  };

  config = {
    # Configure home-manager for user configurations
    # User accounts are defined in your config repo via userModulePath parameter
    home-manager = {
      # useGlobalPkgs and useUserPackages are set in system/default.nix
      extraSpecialArgs = {
        inherit inputs self;
      };
    };
  };
}
