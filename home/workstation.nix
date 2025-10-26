{ pkgs, ... }:
{
  # Workstation profile: full desktop with gaming and device support
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
    ++ packages.fonts
    # Gaming support
    ++ (with pkgs; [
      protonup-ng
    ]);

  # Solaar autostart for Logitech Unifying devices
  # Note: Solaar is installed by the system via hardware.logitech.wireless.enableGraphical
  home.file.".config/autostart/solaar.desktop" = {
    enable = true;
    force = true;
    text = ''
      [Desktop Entry]
      Name=Solaar
      Comment=Logitech Unifying Receiver peripherals manager
      Exec=solaar --window=hide
      Icon=solaar
      StartupNotify=true
      Terminal=false
      Type=Application
      Keywords=logitech;unifying;receiver;mouse;keyboard;
      Categories=Utility;GTK;
    '';
  };
}
