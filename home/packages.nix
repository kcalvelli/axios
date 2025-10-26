{ pkgs }:
{
  # === Common Applications (work on any desktop) ===
  
  # Note-taking and knowledge management
  notes = with pkgs; [
    obsidian
  ];

  # Communication and social
  communication = with pkgs; [
    discord
  ];

  # Document editors and viewers
  documents = with pkgs; [
    typora
    libreoffice-fresh
  ];

  # Media creation and editing
  media = with pkgs; [
    pitivi
    pinta
    inkscape
  ];

  # Media viewing and playback
  viewers = with pkgs; [
    shotwell
    loupe
    celluloid
    amberol
  ];

  # Cloud and sync
  sync = with pkgs; [
    nextcloud-client
  ];

  # === Wayland-Specific Applications ===
  
  # Launchers and input
  launchers = with pkgs; [
    fuzzel
    wl-clipboard
    wtype
  ];

  # Audio control
  audio = with pkgs; [
    playerctl
    pavucontrol
    cava
  ];

  # Screenshot and screen tools
  screenshot = with pkgs; [
    grimblast
    grim
    slurp
    hyprpicker
  ];

  # Theming and appearance
  themes = with pkgs; [
    matugen
    colloid-gtk-theme
    colloid-icon-theme
    adwaita-icon-theme
    papirus-icon-theme
    adw-gtk3
  ];

  # Qt configuration
  qt = with pkgs; [
    kdePackages.qt6ct
  ];

  # === Shared Categories ===
  
  # Fonts
  fonts = with pkgs; [
    nerd-fonts.fira-code
    inter
    material-symbols
  ];

  # System utilities
  utilities = with pkgs; [
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
