{ pkgs, ... }:
{
  # Workstation profile: full desktop with gaming and device support
  imports = [
    ./profiles/base.nix
  ];

  # Workstation-specific packages
  home.packages = with pkgs; [
    # Gaming support
    protonup-ng
  ];

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
