{ config, lib, pkgs, ... }:

{
  # AI home-manager configuration
  # Always import but modules will check osConfig.services.ai.enable internally
  imports = [
    ./mcp.nix
  ];

  config = lib.mkIf config.osConfig.services.ai.enable {
    home.activation.installJules = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD npm install -g @google/jules
    '';
  };

  # Additional AI configuration can go here
}
