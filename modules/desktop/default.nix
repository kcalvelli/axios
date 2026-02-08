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
  # Added flatpak.nix to imports
  imports = [
    ./browsers.nix
    ./flatpak.nix
  ];

  options.desktop = {
    enable = lib.mkEnableOption "Desktop environment with applications and services";
  };

  config = lib.mkIf config.desktop.enable {
    # === Wayland Packages ===
    environment.systemPackages = with pkgs; [
      # System desktop applications
      xwayland-satellite

      # File manager
      kdePackages.dolphin # File manager (split-pane, superior plugin ecosystem)
      kdePackages.ark # Archive manager (integrates with Dolphin)
      kdePackages.kio-extras # Extra protocols for Dolphin
      kdePackages.kdegraphics-thumbnailers # Thumbnails for graphics files

      # === Communication ===
      discord # Communication platform
      spotify # Music streaming
      zenity # File dialogs (required for Spotify local files)
      gajim # XMPP client
      profanity # XMPP client (terminal, OTR/OMEMO, great for SSH)

      # === Productivity Applications ===
      kdePackages.ghostwriter # Markdown editor (Qt, FOSS alternative to Typora)

      # === Media Creation & Editing ===
      krita # Digital art studio (professional raster graphics)

      # === Media Viewing & Playback ===
      kdePackages.gwenview # Image viewer (Qt, SSD, KDE integration, thumbnail browsing)
      # mpv configured via home-manager (home/desktop/mpv.nix) with PipeWire audio
      tauon # Music library player (SDL/FFmpeg, FLAC support, no GStreamer)
      ffmpeg # Video/audio processing, conversion, streaming

      # === System Utilities ===
      kdePackages.filelight # Disk usage analyzer (superior radial visualization)
      lxqt.lxqt-openssh-askpass # GUI password prompt for sudo -A (no KWallet dependency)
      swappy # Screenshot annotation (fits tiling WM workflow)
      qalculate-qt # Calculator (Qt port, better theming)
      kdePackages.okular # PDF reader (best-in-class annotations, format support)
      swaybg # Wallpaper setter
      imagemagick # Image processing
      libnotify # Desktop notifications
      mousepad # Text editor (simple, syntax highlighting, no CSD)

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
      hicolor-icon-theme # Base icon theme (fallback for apps like solaar)
      adw-gtk3 # Adwaita GTK3 theme
      libsForQt5.qt5ct # Qt5 theme configuration tool
      kdePackages.qt6ct # Qt6 theme configuration tool

      # Note: khal provided by DMS, fonts provided by DMS greeter
      # Note: vdirsyncer moved to PIM module

      # Note: PWA apps are now managed via home-manager (axios.pwa module)
      # This allows users to add custom PWAs with their own URLs and icons

      # === Streaming ===
      # OBS with VA-API support for camera format conversion
      # Fixes: Green screen/crashes with NV12 format on high-resolution webcams
      # Wrapped with gamemoderun to always launch in gamemode for optimal performance
      (
        let
          obs-wrapped = wrapOBS {
            plugins = with obs-studio-plugins; [
              obs-vaapi # VA-API hardware encoding support
              obs-vkcapture # Vulkan/OpenGL game capture
            ];
          };
        in
        pkgs.symlinkJoin {
          name = "obs-studio-gamemode";
          paths = [ obs-wrapped ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/obs \
              --prefix PATH : ${lib.makeBinPath [ pkgs.gamemode ]} \
              --run 'exec ${pkgs.gamemode}/bin/gamemoderun ${obs-wrapped}/bin/obs "$@"'
          '';
        }
      )
      # === Implements freedesktops's Desktop Menu Specification
      kdePackages.plasma-workspace
      kdePackages.kservice

      # === BBS Access
      syncterm

      # === Retro Terminal
      inputs.c64term.packages.${pkgs.stdenv.hostPlatform.system}.c64term
    ];

    # === Wayland Environment Variables ===
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # === Desktop Session Identity ===
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "niri";

      # === Use plasma-menus (Required for kded6/Dolphin)
      XDG_MENU_PREFIX = "plasma-";

      # === Portal Configuration ===
      # NOTE: No portal-specific environment variables - portals auto-detect based on XDG_CURRENT_DESKTOP
      # Niri uses xdg-desktop-portal-gnome and xdg-desktop-portal-gtk (official requirement)

      # NOTE: GStreamer removed - mpv uses FFmpeg/PipeWire directly (see home/desktop/mpv.nix)
      # Users needing GStreamer for specific Qt apps can add it manually with:
      #   environment.systemPackages = [ gst_all_1.gstreamer gst_all_1.gst-plugins-base ... ];
      #   environment.sessionVariables.QT_MEDIA_BACKEND = "gstreamer";
      #   environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPath "lib/gstreamer-1.0" [ ... ];
    };

    # === Binary Cache Configuration ===
    # Configure binary caches to avoid compiling from source
    nix.settings = {
      substituters = [
        "https://niri.cachix.org"
        "https://brave-previews.cachix.org"
      ];
      trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "brave-previews.cachix.org-1:9bLSYtgro1rYD4hUzFVASMpsNjWjHvEz11HGB2trAq4="
      ];
    };

    # Enable DankMaterialShell with greeter
    programs.dank-material-shell = {
      enable = true; # Provides system packages (matugen, hyprpicker, cava, etc.)
      quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      greeter = {
        enable = userCfg.name != "";
        compositor.name = "niri";
        # Auto-detect configHome from axios.user.name (convention over configuration)
        configHome = if userCfg.name != "" then "/home/${userCfg.name}" else null;
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
      # Note: Dolphin has built-in terminal integration via F4 (no plugin needed)
      gnome-disks.enable = true; # Disk utility (cleaner UX for ISO writing/benchmarking)
      seahorse.enable = true; # Password and encryption key manager (GNOME Keyring integration)
      corectrl.enable = true;
      kdeconnect.enable = true;
      _1password.enable = true;
      _1password-gui.enable = true;
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
      # flatpak.enable moved to flatpak.nix
      fwupd.enable = true;
      upower.enable = true;
      libinput.enable = true;
      acpid.enable = true;
      power-profiles-daemon.enable = lib.mkDefault (!config.hardware.system76.power-daemon.enable);

      # === USB Device Permissions ===
      # Allow normal users to access USB devices without root
      # Particularly useful for game controllers, dev boards, Arduino, etc.
      udev.extraRules = ''
        # Game controllers - Sony (PlayStation)
        SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", MODE="0666", TAG+="uaccess"
        # Game controllers - Microsoft (Xbox)
        SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", MODE="0666", TAG+="uaccess"
        # Game controllers - Nintendo
        SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", MODE="0666", TAG+="uaccess"
        # Game controllers - Valve (Steam Controller)
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666", TAG+="uaccess"

        # Input devices - give users in 'input' group access
        SUBSYSTEM=="input", GROUP="input", MODE="0660"
        SUBSYSTEM=="usb", ENV{ID_INPUT_JOYSTICK}=="1", MODE="0666", TAG+="uaccess"
      '';
    };

    # === Start kded6 (KDE Daemon) automatically ===
    # Required for Niri to support KDE file dialogs and menus
    systemd.user.services.kded6 = {
      description = "KDE Daemon";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.kdePackages.kded}/bin/kded6";
        Restart = "on-failure";
        Slice = "session.slice";
        # FIX: Explicitly pass the prefix so kded6 looks for 'plasma-applications.menu'
        Environment = "XDG_MENU_PREFIX=plasma-";
      };
    };

    # === Portal Service Optimization ===
    # Reduce timeout for faster failure/retry (addresses NixOS 24.11 portal timeout issue)
    systemd.user.services.xdg-desktop-portal = {
      serviceConfig = {
        TimeoutStartSec = "10s";
      };
    };

    systemd.user.services.xdg-desktop-portal-gnome = {
      serviceConfig = {
        TimeoutStartSec = "10s";
      };
    };

    systemd.user.services.xdg-desktop-portal-gtk = {
      serviceConfig = {
        TimeoutStartSec = "10s";
      };
    };

    # === XDG Portal Configuration ===
    # Using only Niri-required portals (no mixing with KDE)
    xdg = {
      mime.enable = true;
      icons.enable = true;
      portal = {
        enable = true;

        # Niri officially requires:
        # - xdg-desktop-portal-gnome: Required for screencasting support
        # - xdg-desktop-portal-gtk: Default fallback portal for all interfaces
        extraPortals = [
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
        ];

        # Use GNOME portal as default (handles screencasting + all interfaces)
        # GTK portal serves as fallback
        config = {
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
          };
        };
      };
    };

    # === System Tuning ===
    # Increase inotify limits for apps that watch many files (Spotify, VS Code, etc.)
    boot.kernel.sysctl."fs.inotify.max_user_instances" = 8192;

    # Enable home-manager desktop modules
    home-manager.sharedModules = with homeModules; [
      desktop
      # Calendar/contacts sync moved to axios-dav: https://github.com/kcalvelli/axios-dav
    ];
  };
}
