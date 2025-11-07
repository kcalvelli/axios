{ pkgs, ... }:
{
  # Base profile: shared configuration for all desktop profiles
  # This module contains packages and settings common to both workstation and laptop
  #
  # NOTE: Desktop applications, fonts, and utilities have been moved to
  # modules/applications.nix for system-level installation. This provides:
  # - Cleaner separation: system installs, home-manager configures
  # - Better caching and PATH management
  # - Avoids nixpkgs.config conflicts with useGlobalPkgs
  #
  # User-specific packages remain in individual home-manager modules:
  # - ai/mcp.nix: Development tools, AI clients
  # - calendar.nix: Calendar sync tools
  # - wayland-material.nix: Theme building tools

  imports = [
    ./defaults.nix # Sensible defaults for home-manager
    ../ai
    ../security.nix
    ../browser
    ../terminal
    ../calendar.nix
  ];
}
