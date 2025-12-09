{
  lib,
  pkgs,
  config,
  homeModules,
  inputs,
  ...
}:
let
  userCfg = config.axios.user;
in
{
  # Note: DMS NixOS modules are imported in lib/default.nix baseModules

  options.desktop = {
    enable = lib.mkEnableOption "Desktop environment with applications and services";
  };

  config = lib.mkIf config.desktop.enable {
    # === Wayland Packages ===
    environment.systemPackages = with pkgs; [
      # System desktop applications
      wayvnc
      xwayland-satellite

      # File manager
      nautilus
      file-roller # Archive manager

      # === Productivity Applications ===
      obsidian # Note-taking and knowledge management
      discord # Communication platform
      typora # Markdown editor
      libreoffice-fresh # Office suite
      bitwarden-desktop # Password manager and secure digital vault

      # === Media Creation & Editing ===
      pitivi # Video editor
      pinta # Image editor
      inkscape # Vector graphics editor

      # === Media Viewing & Playback ===
      shotwell # Photo manager
      loupe # Image viewer
      celluloid # Video player
      amberol # Music player

      # === System Utilities ===
      baobab # Disk usage analyzer
      swappy # Screenshot annotation
      qalculate-gtk # Calculator
      swaybg # Wallpaper setter
      imagemagick # Image processing
      libnotify # Desktop notifications
      gnome-text-editor # Text editor

      # === Wayland Tools ===
      fuzzel # Application launcher
      wtype # Wayland key automation
      playerctl # Media player control
      pavucontrol # Audio control
      wf-recorder # Screen recording
      slurp # Screen area selection (for wf-recorder)

      # === Theming & Appearance ===
      # Note: matugen, hyprpicker, cava provided by DMS
      colloid-gtk-theme # GTK theme
      colloid-icon-theme # Icon theme
      adwaita-icon-theme # GNOME icon theme
      papirus-icon-theme # Papirus icon theme
      adw-gtk3 # Adwaita GTK3 theme

      # === Calendar Sync ===
      # Note: khal provided by DMS, fonts provided by DMS greeter
      vdirsyncer

      # Note: PWA apps are now managed via home-manager (axios.pwa module)
      # This allows users to add custom PWAs with their own URLs and icons

      # === Streaming ===
      obs-studio

      # === Gnome  PIM (Evolution added in programs below) without Gnome ===
      gnome-online-accounts-gtk
      gnome-calendar
      gnome-contacts
    ];

    # === Wayland Environment Variables ===
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # Enable DankMaterialShell with greeter
    programs.dankMaterialShell = {
      enable = true; # Provides system packages (matugen, hyprpicker, cava, etc.)
      quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      greeter = {
        enable = true;
        compositor.name = "niri";
        # Auto-detect configHome from axios.user.name (convention over configuration)
        configHome = lib.mkIf (userCfg.name != "") "/home/${userCfg.name}";
      };
    };

    # GNOME Keyring for credentials (PAM configuration)
    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };

    # === Desktop Programs ===
    programs = {
      niri.enable = true;
      xwayland.enable = true;
      dconf.enable = true;
      nautilus-open-any-terminal.enable = true;
      nautilus-open-any-terminal.terminal = "ghostty";
      evince.enable = true;
      gnome-disks.enable = true;
      seahorse.enable = true;
      corectrl.enable = true;
      kdeconnect.enable = true;
      localsend = {
        enable = true;
        openFirewall = true;
      };
      _1password.enable = true;
      _1password-gui.enable = true;
      evolution.enable = true;
    };

    # === Desktop Services ===
    services = {
      gnome = {
        sushi.enable = true;
        gnome-keyring.enable = true;
        evolution-data-server.enable = true; # Backend for gnome-calendar and gnome-contacts
      };
      accounts-daemon.enable = true;
      geoclue2.enable = true; # Location services for weather in gnome-calendar
      gvfs.enable = true;
      udisks2.enable = true;
      system76-scheduler.enable = true;
      fwupd.enable = true;
      upower.enable = true;
      libinput.enable = true;
      acpid.enable = true;
      power-profiles-daemon.enable = lib.mkDefault (!config.hardware.system76.power-daemon.enable);
    };

    # === XDG Portal Configuration ===
    xdg = {
      mime.enable = true;
      icons.enable = true;
      portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = [
          "gnome"
          "gtk"
        ];
      };
    };

    # Enable home-manager desktop modules
    home-manager.sharedModules = with homeModules; [
      desktop
      browser
      calendar
    ];
  };
}
