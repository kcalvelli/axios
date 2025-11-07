{ config, lib, osConfig ? { }, ... }:
let
  cfg = config.axios.home;
in
{
  options.axios.home = {
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
      default = "\${HOME}/.config/nixos";
      description = ''
        Default path to NixOS flake configuration.

        Sets the FLAKE_PATH environment variable for convenience with
        rebuild scripts and aliases. Set to null to disable.
      '';
    };
  };

  config = lib.mkIf cfg.enableDefaults {
    # Set sensible home-manager state version
    home.stateVersion = lib.mkDefault cfg.stateVersion;

    # Set FLAKE_PATH for convenience with rebuild scripts
    home.sessionVariables = lib.mkIf (cfg.flakePath != null) {
      FLAKE_PATH = lib.mkDefault cfg.flakePath;
    };
  };
}
