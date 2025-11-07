{ ... }:
{
  # Profiles module - imports all profile aspects
  # Individual profiles (workstation, laptop) import base.nix
  # defaults.nix provides common home-manager defaults
  imports = [
    ./defaults.nix
  ];
}
