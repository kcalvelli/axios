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
      wayvnc
      xwayland-satellite

      # File manager
      kdePackages.dolphin # File manager (split-pane, superior plugin ecosystem)
      kdePackages.ark # Archive manager (integrates with Dolphin)
      kdePackages.kio-extras # Extra protocols for Dolphin
      kdePackages.kdegraphics-thumbnailers # Thumbnails for graphics files

      # === Productivity Applications ===
      discord # Communication platform
      kdePackages.ghostwriter # Markdown editor (Qt, FOSS alternative to Typora)
      dbeaver-bin # Universal database tool (supports PostgreSQL, MySQL, SQLite, etc.)

      # === Media Creation & Editing ===
      kdePackages.kdenlive # Video editor (professional-grade, industry standard)
      krita # Digital art studio (professional raster graphics)
      inkscape # Vector graphics editor

      # === Media Viewing & Playback ===
      digikam # Photo manager (professional asset management)
      loupe # Image viewer (fast, clean UI, great touchpad gestures)
      haruna # Video player (excellent MPV frontend)
      mpv # Media player (CLI, UDP streaming, hardware acceleration)
      ffmpeg # Video/audio processing, conversion, streaming
      amberol # Music player (simple, focused on music playback)

      # === Ultimate64 Tools ===
      inputs.c64-stream-viewer.packages.${pkgs.stdenv.hostPlatform.system}.av # C64/Ultimate64 video/audio stream viewer

      # === System Utilities ===
      kdePackages.filelight # Disk usage analyzer (superior radial visualization)
      kdePackages.ksshaskpass # GUI password prompt for sudo -A
      swappy # Screenshot annotation (fits tiling WM workflow)
      qalculate-qt # Calculator (Qt port, better theming)
      kdePackages.okular # PDF reader (best-in-class annotations, format support)
      swaybg # Wallpaper setter
      imagemagick # Image processing
      libnotify # Desktop notifications
      kdePackages.kate # Text editor (LSP, minimap, plugins, dev-tier features)

      # === Wayland Tools ===
      pipewire # Required for Qt6 multimedia symbols (Dolphin, etc.)
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
      # OBS with full GStreamer + VA-API support for camera format conversion
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
      v4l-utils # Camera debugging (v4l2-ctl --list-formats-ext)

      # === Implements freedesktops's Desktop Menu Specification
      kdePackages.plasma-workspace
      kdePackages.kservice

      # === BBS Access
      syncterm

      # === Portal Helpers ===
      kdePackages.kdialog # Required by xdg-desktop-portal-kde
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
      # NOTE: GTK_USE_PORTAL="1" REMOVED - deprecated upstream and causes portal loops
      # Modern replacement: GDK_DEBUG=portals forces GTK apps (including Electron/VSCode)
      # to use XDG Desktop Portal file choosers without causing timeout loops
      GDK_DEBUG = "portals";
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
      localsend = {
        enable = true;
        openFirewall = true;
      };
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
    # Fix 20-30s boot delay caused by portal service timeouts (NixOS 24.11 issue)
    # Ensure portals start only after session environment is fully initialized
    systemd.user.services.xdg-desktop-portal = {
      serviceConfig = {
        # Reduce timeout from default 90s to 10s for faster failure/retry
        TimeoutStartSec = "10s";
      };
    };

    systemd.user.services.xdg-desktop-portal-gnome = {
      serviceConfig = {
        TimeoutStartSec = "10s";
      };
    };

    systemd.user.services.xdg-desktop-portal-kde = {
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
    xdg = {
      mime.enable = true;
      icons.enable = true;
      portal = {
        enable = true;

        # NOTE: xdgOpenUsePortal NOT used - causes 20-30s boot delays due to portal timeout loops.
        # It's only for xdg-open command, not file chooser dialogs. VSCode/Electron apps use
        # GtkFileChooserNative which respects portal config directly without this option.

        # All three portals are required:
        # - xdg-desktop-portal-kde: KDE file chooser (superior UX)
        # - xdg-desktop-portal-gnome: Required by niri for screencasting support
        # - xdg-desktop-portal-gtk: Fallback for other interfaces
        extraPortals = [
          pkgs.kdePackages.xdg-desktop-portal-kde
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
        ];

        # Use GNOME/GTK for most interfaces (Niri compatibility + screencasting)
        # but KDE specifically for file chooser (better UX)
        config = {
          common = {
            default = [
              "gnome"
              "gtk"
            ];
            # Use KDE file chooser (Dolphin-style) instead of GNOME/GTK
            "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
          };
          # Explicitly configure niri to use KDE file chooser
          # (fallback to 'common' doesn't work reliably with Electron apps)
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
          };
        };
      };
    };

    # Enable home-manager desktop modules
    home-manager.sharedModules = with homeModules; [
      desktop
      calendar
    ];
  };
}
