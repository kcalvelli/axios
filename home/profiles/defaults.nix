{ config, lib, ... }:
let
  cfg = config.axios.home;
in
{
  options.axios = {
    home = {
      enableDefaults = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable axios home-manager sensible defaults.

          This automatically configures:
          - home.stateVersion: Set to a sensible default
          - FLAKE_PATH environment variable: Points to ~/.config/nixos by default

          These defaults reduce boilerplate in user configurations while remaining
          overridable with lib.mkForce if needed.
        '';
      };

      stateVersion = lib.mkOption {
        type = lib.types.str;
        default = "24.11";
        description = ''
          Default home-manager state version.

          This should match the NixOS release version and is updated
          with each major axios release.
        '';
      };

      flakePath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "\${HOME}/.config/nixos_config";
        description = ''
          Default path to NixOS flake configuration.

          Sets the FLAKE_PATH environment variable for convenience with
          rebuild scripts and aliases. Set to null to disable.

          The axios init script creates configurations in ~/.config/nixos_config
          by default.
        '';
      };

      xdgUserDirs = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable XDG user directories (Documents, Pictures, Downloads, etc).

          When enabled, creates standard user directories and manages the
          XDG configuration file (~/.config/user-dirs.dirs).

          WARNING: This will fail if you already have ~/.config/user-dirs.dirs
          created by another tool. Only enable this on fresh user accounts or
          if you want home-manager to take over XDG directory management.

          For new installations via 'nix run .#init', this should be safe to enable.
        '';
      };
    };

    user = {
      email = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          User's email address.

          This is automatically used for git configuration and other tools
          that need an email address. The user's full name is automatically
          retrieved from the system user account description.
        '';
        example = "user@example.com";
      };
    };
  };

  config = lib.mkIf cfg.enableDefaults {
    # Set sensible home-manager state version
    home.stateVersion = lib.mkDefault cfg.stateVersion;

    # Set FLAKE_PATH for convenience with rebuild scripts
    home.sessionVariables = lib.mkIf (cfg.flakePath != null) {
      FLAKE_PATH = lib.mkDefault cfg.flakePath;
    };

    # Create standard XDG user directories (opt-in)
    xdg.userDirs = lib.mkIf cfg.xdgUserDirs {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };
  };
}
