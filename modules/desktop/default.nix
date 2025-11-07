{ lib, pkgs, config, homeModules, ... }:
{
  options.desktop = {
    enable = lib.mkEnableOption "Desktop environment with applications and services";
  };

  config = lib.mkIf config.desktop.enable {
    # === Wayland Packages ===
    environment.systemPackages = with pkgs; [
      # System desktop applications
      mate.mate-polkit
      wayvnc
      xwayland-satellite

      # File manager
      nautilus

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

      # === VPN ===
      protonvpn-gui

      # === Streaming ===
      obs-studio
    ];

    # === Wayland Environment Variables ===
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # == Use Flathub as the only repo in GNOME Software ==
      GNOME_SOFTWARE_REPOS_ENABLED = "flathub";
      GNOME_SOFTWARE_USE_FLATPAK_ONLY = "1";
    };

    # Enable DankMaterialShell greeter with niri
    programs.dankMaterialShell.greeter = {
      enable = true;
      compositor.name = "niri";
      # Note: configHome will be set automatically to the first normal user's home
      # or can be overridden in host configuration if needed
    };

    # GNOME Keyring for credentials
    services.gnome.gnome-keyring.enable = true;
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
      file-roller.enable = true;
      gnome-disks.enable = true;
      seahorse.enable = true;
      corectrl.enable = true;
      kdeconnect.enable = true;
      localsend = {
        enable = true;
        openFirewall = true;
      };
    };

    # === Desktop Services ===
    services = {
      gnome = {
        sushi.enable = true;
        gnome-keyring.enable = true;
      };
      accounts-daemon.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
      system76-scheduler.enable = true;
      flatpak.enable = true;
      fwupd.enable = true;
      upower.enable = true;
      libinput.enable = true;
      acpid.enable = true;
      power-profiles-daemon.enable = lib.mkDefault (
        !config.hardware.system76.power-daemon.enable
      );
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
        config.common.default = [ "gnome" "gtk" ];
      };
    };

    # Enable home-manager desktop module
    home-manager.sharedModules = with homeModules; [
      desktop
    ];
  };
}
