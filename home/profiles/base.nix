{ pkgs, ... }:
{
  imports = [
    ./defaults.nix # Sensible defaults for home-manager
    ../ai
    ../security
    ../browser
    ../terminal
    ../calendar
  ];
}
