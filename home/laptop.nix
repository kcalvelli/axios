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
  ];
}
