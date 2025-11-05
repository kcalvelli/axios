{ config, lib, pkgs, osConfig ? { }, ... }:

{
  # AI home-manager configuration
  # Always import but modules will check osConfig.services.ai.enable internally
  imports = [
    ./mcp.nix
  ];

  # Additional AI configuration can go here
}
