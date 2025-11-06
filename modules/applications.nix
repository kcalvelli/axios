{ pkgs, lib, config, ... }:
{
  # Desktop applications - installed system-wide
  # These packages are available to all users and managed at the system level.
  # User-specific packages and tools remain in home-manager configuration.
  # Only installed when desktop.enable = true

  config = lib.mkIf config.desktop.enable {
    environment.systemPackages = with pkgs; [
      # === Productivity Applications ===
      obsidian # Note-taking and knowledge management
      discord # Communication platform
      typora # Markdown editor
      libreoffice-fresh # Office suite

      # === Media Creation & Editing ===
      pitivi # Video editor
      pinta # Image editor
      inkscape # Vector graphics editor

      # === Media Viewing & Playback ===
      shotwell # Photo manager
      loupe # Image viewer
      celluloid # Video player
      amberol # Music player

      # === Cloud & Sync ===
      nextcloud-client # Nextcloud sync client

      # === System Utilities ===
      baobab # Disk usage analyzer
      swappy # Screenshot annotation
      qalculate-gtk # Calculator
      swaybg # Wallpaper setter
      imagemagick # Image processing
      libnotify # Desktop notifications
      gnome-software # Software center
      gnome-text-editor # Text editor

      # === Wayland Tools ===
      fuzzel # Application launcher
      wl-clipboard # Clipboard utilities
      wtype # Wayland key automation
      playerctl # Media player control
      pavucontrol # Audio control
      cava # Audio visualizer
      wf-recorder # Screen recording
      slurp # Screen area selection (for wf-recorder)
      hyprpicker # Color picker

      # === Theming & Appearance ===
      matugen # Material theme generator
      colloid-gtk-theme # GTK theme
      colloid-icon-theme # Icon theme
      adwaita-icon-theme # GNOME icon theme
      papirus-icon-theme # Papirus icon theme
      adw-gtk3 # Adwaita GTK3 theme

      # === Qt Configuration ===
      kdePackages.qt6ct # Qt6 configuration tool

      # === Fonts ===
      # System-wide fonts (deduplicated from home-manager)
      nerd-fonts.fira-code # Nerd Fonts variant of Fira Code
      inter # Inter font family
      material-symbols # Material Design symbols

      # === DankMaterialShell Calendar ===
      vdirsyncer
      khal

      # === PWA apps for all users ===
      pwa-apps
    ];
  };
}
