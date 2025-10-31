{ pkgs, ... }:
{
  # Workstation profile: full desktop with gaming and device support
  imports = [
    ./ai
    ./security.nix
    ./browser
    ./terminal
    ./calendar.nix
  ];

  # Common application packages
  home.packages = with pkgs; [
    # Note-taking and knowledge management
    obsidian

    # Communication and social
    discord

    # Document editors and viewers
    typora
    libreoffice-fresh

    # Media creation and editing
    pitivi
    pinta
    inkscape

    # Media viewing and playback
    shotwell
    loupe
    celluloid
    amberol

    # Cloud and sync
    nextcloud-client

    # Fonts
    nerd-fonts.fira-code
    inter
    material-symbols

    # System utilities
    baobab
    swappy
    qalculate-gtk
    swaybg
    imagemagick
    libnotify
    gnome-software
    gnome-text-editor

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
