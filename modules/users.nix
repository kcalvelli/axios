{
  inputs,
  self,
  config,
  lib,
  ...
}:
let
  cfg = config.axios.users;
  userCfg = config.axios.user;

  # Determine which groups to add based on enabled modules
  autoGroups = lib.lists.unique (
    lib.flatten [
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
        "podman" # Container management
      ])

      # Hardware-specific groups
      (lib.optionals
        ((config.hardware.desktop.enable or false) || (config.hardware.laptop.enable or false))
        [
          "plugdev" # Device access
        ]
      )

      # Development and admin groups
      (lib.optionals ((config.development.enable or false) || (config.services.enable or false)) [
        "adm" # Log file access
        "disk" # Disk management tools
      ])

      # Additional groups specified by user
      cfg.extraGroups
    ]
  );
in
{
  options.axios.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Username for the primary user account.

        When set along with fullName and email, axios automatically creates
        the user account with sensible defaults.
      '';
      example = "myuser";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Full name of the user.

        Automatically used for:
        - System user description (users.users.\${userCfg.name}.description)
        - Git user.name configuration
      '';
      example = "John Doe";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Email address for the user.

        Automatically used for:
        - Git user.email configuration
        - Other tools requiring email
      '';
      example = "user@example.com";
    };
  };

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
        - podman: virt.containers module
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
      example = [
        "dialout"
        "i2c"
      ];
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

  config = lib.mkMerge [
    # Configure home-manager for user configurations
    {
      home-manager = {
        # useGlobalPkgs and useUserPackages are set in system/default.nix
        extraSpecialArgs = {
          inherit inputs self;
        };
      };
    }

    # Automatically create user when axios.user is configured
    (lib.mkIf (userCfg.name != "") {
      users.users.${userCfg.name} = {
        isNormalUser = lib.mkDefault true;
        description = lib.mkDefault userCfg.fullName;
        extraGroups = lib.mkDefault cfg.defaultExtraGroups;
      };

      home-manager.users.${userCfg.name} = {
        # Email is passed through to home-manager for git config
        axios.user.email = lib.mkDefault userCfg.email;
      };

      # Create standard XDG user directories on first boot
      # Uses systemd-tmpfiles which is idempotent (won't fail if dirs exist)
      systemd.tmpfiles.rules =
        let
          homeDir = config.users.users.${userCfg.name}.home;
          uid = toString config.users.users.${userCfg.name}.uid;
          gid = toString config.users.users.${userCfg.name}.group;
        in
        [
          "d ${homeDir}/Desktop 0755 ${userCfg.name} ${gid} -"
          "d ${homeDir}/Documents 0755 ${userCfg.name} ${gid} -"
          "d ${homeDir}/Downloads 0755 ${userCfg.name} ${gid} -"
          "d ${homeDir}/Music 0755 ${userCfg.name} ${gid} -"
          "d ${homeDir}/Pictures 0755 ${userCfg.name} ${gid} -"
          "d ${homeDir}/Videos 0755 ${userCfg.name} ${gid} -"
          "d ${homeDir}/Public 0755 ${userCfg.name} ${gid} -"
          "d ${homeDir}/Templates 0755 ${userCfg.name} ${gid} -"
        ];
    })
  ];
}
