{ pkgs, ... }:
{
  # Laptop profile: mobile-optimized base configuration
  imports = [
    ./security.nix
    ./browser
    ./terminal
    ./calendar.nix
  ];

  # Common application packages
  home.packages = let
    packages = import ./packages.nix { inherit pkgs; };
  in
    packages.notes
    ++ packages.communication
    ++ packages.documents
    ++ packages.media
    ++ packages.viewers
    ++ packages.utilities
    ++ packages.sync
    ++ packages.fonts;
}
