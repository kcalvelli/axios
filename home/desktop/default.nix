{
  inputs,
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:

{
  imports = [
    ./theming.nix
    ./wallpaper.nix
    ./niri.nix
    ./niri-keybinds.nix
    ./gdrive-sync.nix
    ./pwa-apps.nix
    inputs.axios-monitor.homeManagerModules.default
    inputs.dankMaterialShell.homeModules.dank-material-shell
    inputs.dsearch.homeModules.default
  ];

  # Enable PWA apps by default for desktop users
  axios.pwa.enable = true;

  # Enable axiOS Monitor widget by default for desktop users
  programs.axios-monitor.enable = lib.mkDefault (osConfig.desktop.enable or false);

  # Configure sudo to use GUI password prompt
  home.sessionVariables = {
    SUDO_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  };

  # DankMaterialShell configuration
  programs.dank-material-shell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Systemd integration - DISABLED to use Niri spawn-at-startup instead
    # This eliminates race conditions with PipeWire/Wayland at boot
    systemd = {
      enable = false; # Use Niri spawn instead (see niri.nix)
      restartIfChanged = false;
    };

    # Feature toggles (explicit configuration for clarity)
    enableSystemMonitoring = true; # System resource monitoring widgets
    enableVPN = true; # VPN status widget
    enableDynamicTheming = true; # Dynamic theme generation (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)

    # Note: The following options are now built-in to DMS and have been removed:
    # - enableClipboard: Clipboard history built-in
    # - enableBrightnessControl: Brightness controls built-in
    # - enableColorPicker: Color picker (hyprpicker) built-in
    # - enableSystemSound: System sounds now included in dms-shell package
  };

  programs.dsearch = {
    enable = true;
  };

  # Helper scripts
  home.packages = [
    (pkgs.writeShellScriptBin "focus-or-spawn-qalculate" ''
      # robust-focus.sh

      # 1. Define the App ID explicitly
      MATCH_APP="io.github.Qalculate.qalculate-qt"

      # 2. Use jq to parse the JSON array
      # -j: Output raw string (no quotes around the ID)
      # select: Filter the list for windows matching the app_id
      # .id: Extract only the window ID
      # head -n 1: In case multiple windows exist, pick the first one
      WINDOW_ID=$(niri msg -j windows | jq -r ".[] | select(.app_id == \"$MATCH_APP\") | .id" | head -n 1)

      if [ -n "$WINDOW_ID" ]; then
          niri msg action focus-window --id "$WINDOW_ID"
      else
          qalculate-qt &
      fi
    '')
  ];

  # Desktop services
  services.gnome-keyring = {
    enable = true;
    components = [
      "pkcs11"
      "secrets"
      "ssh"
    ];
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # Default application associations for all installed apps
  # Ensures every MIME type opens with the correct axiOS-shipped application
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # === KDE Connect scheme handler ===
      "x-scheme-handler/kdeconnect" = "org.kde.dolphin.desktop";

      # === Flatpak install handler ===
      "application/vnd.flatpak.ref" = "com.github.kcalvelli.axios.flatpak-install.desktop";
      "application/vnd.flatpak.repo" = "com.github.kcalvelli.axios.flatpak-install.desktop";

      # === File Manager (Dolphin) ===
      "inode/directory" = "org.kde.dolphin.desktop";

      # === Web Browser (Brave) ===
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
      "text/html" = "brave-browser.desktop";
      "application/xhtml+xml" = "brave-browser.desktop";

      # === Text Editor (Mousepad) ===
      "text/plain" = "org.xfce.mousepad.desktop";
      "text/x-csrc" = "org.xfce.mousepad.desktop";
      "text/x-chdr" = "org.xfce.mousepad.desktop";
      "text/x-c++src" = "org.xfce.mousepad.desktop";
      "text/x-c++hdr" = "org.xfce.mousepad.desktop";
      "text/x-java" = "org.xfce.mousepad.desktop";
      "text/x-python" = "org.xfce.mousepad.desktop";
      "text/x-shellscript" = "org.xfce.mousepad.desktop";
      "text/x-script.python" = "org.xfce.mousepad.desktop";
      "text/x-perl" = "org.xfce.mousepad.desktop";
      "text/x-ruby" = "org.xfce.mousepad.desktop";
      "text/x-lua" = "org.xfce.mousepad.desktop";
      "text/x-makefile" = "org.xfce.mousepad.desktop";
      "text/x-cmake" = "org.xfce.mousepad.desktop";
      "text/x-diff" = "org.xfce.mousepad.desktop";
      "text/x-patch" = "org.xfce.mousepad.desktop";
      "text/x-log" = "org.xfce.mousepad.desktop";
      "text/css" = "org.xfce.mousepad.desktop";
      "text/javascript" = "org.xfce.mousepad.desktop";
      "text/x-sql" = "org.xfce.mousepad.desktop";
      "text/x-readme" = "org.xfce.mousepad.desktop";
      "text/csv" = "org.xfce.mousepad.desktop";
      "text/tab-separated-values" = "org.xfce.mousepad.desktop";
      "text/x-tex" = "org.xfce.mousepad.desktop";
      "text/x-nix" = "org.xfce.mousepad.desktop";
      "application/x-shellscript" = "org.xfce.mousepad.desktop";
      "application/xml" = "org.xfce.mousepad.desktop";
      "application/json" = "org.xfce.mousepad.desktop";
      "application/x-yaml" = "org.xfce.mousepad.desktop";
      "application/toml" = "org.xfce.mousepad.desktop";
      "application/javascript" = "org.xfce.mousepad.desktop";
      "application/x-desktop" = "org.xfce.mousepad.desktop";

      # === Markdown Editor (Ghostwriter) ===
      "text/markdown" = "org.kde.ghostwriter.desktop";
      "text/x-markdown" = "org.kde.ghostwriter.desktop";

      # === Image Viewer (Gwenview) ===
      "image/png" = "org.kde.gwenview.desktop";
      "image/jpeg" = "org.kde.gwenview.desktop";
      "image/gif" = "org.kde.gwenview.desktop";
      "image/bmp" = "org.kde.gwenview.desktop";
      "image/x-bmp" = "org.kde.gwenview.desktop";
      "image/webp" = "org.kde.gwenview.desktop";
      "image/tiff" = "org.kde.gwenview.desktop";
      "image/x-tga" = "org.kde.gwenview.desktop";
      "image/x-ico" = "org.kde.gwenview.desktop";
      "image/vnd.microsoft.icon" = "org.kde.gwenview.desktop";
      "image/x-portable-pixmap" = "org.kde.gwenview.desktop";
      "image/x-portable-graymap" = "org.kde.gwenview.desktop";
      "image/x-portable-bitmap" = "org.kde.gwenview.desktop";
      "image/x-xpixmap" = "org.kde.gwenview.desktop";
      "image/x-xbitmap" = "org.kde.gwenview.desktop";
      "image/svg+xml" = "org.kde.gwenview.desktop";
      "image/svg+xml-compressed" = "org.kde.gwenview.desktop";
      "image/avif" = "org.kde.gwenview.desktop";
      "image/heif" = "org.kde.gwenview.desktop";
      "image/jxl" = "org.kde.gwenview.desktop";
      "image/x-eps" = "org.kde.gwenview.desktop";
      "image/x-pcx" = "org.kde.gwenview.desktop";

      # === Video Player (Haruna / MPV frontend) ===
      "video/mp4" = "org.kde.haruna.desktop";
      "video/x-matroska" = "org.kde.haruna.desktop";
      "video/webm" = "org.kde.haruna.desktop";
      "video/x-msvideo" = "org.kde.haruna.desktop";
      "video/quicktime" = "org.kde.haruna.desktop";
      "video/mpeg" = "org.kde.haruna.desktop";
      "video/x-flv" = "org.kde.haruna.desktop";
      "video/ogg" = "org.kde.haruna.desktop";
      "video/3gpp" = "org.kde.haruna.desktop";
      "video/3gpp2" = "org.kde.haruna.desktop";
      "video/x-ms-wmv" = "org.kde.haruna.desktop";
      "video/x-ogm+ogg" = "org.kde.haruna.desktop";
      "video/vnd.rn-realvideo" = "org.kde.haruna.desktop";
      "video/mp2t" = "org.kde.haruna.desktop";

      # === Music Player (Elisa) ===
      "audio/mpeg" = "org.kde.elisa.desktop";
      "audio/mp4" = "org.kde.elisa.desktop";
      "audio/flac" = "org.kde.elisa.desktop";
      "audio/x-flac" = "org.kde.elisa.desktop";
      "audio/ogg" = "org.kde.elisa.desktop";
      "audio/x-vorbis+ogg" = "org.kde.elisa.desktop";
      "audio/x-opus+ogg" = "org.kde.elisa.desktop";
      "audio/wav" = "org.kde.elisa.desktop";
      "audio/x-wav" = "org.kde.elisa.desktop";
      "audio/aac" = "org.kde.elisa.desktop";
      "audio/x-aac" = "org.kde.elisa.desktop";
      "audio/x-ms-wma" = "org.kde.elisa.desktop";
      "audio/webm" = "org.kde.elisa.desktop";
      "audio/x-matroska" = "org.kde.elisa.desktop";
      "audio/x-ape" = "org.kde.elisa.desktop";
      "audio/x-wavpack" = "org.kde.elisa.desktop";
      "audio/mp3" = "org.kde.elisa.desktop";
      "audio/aiff" = "org.kde.elisa.desktop";
      "audio/x-aiff" = "org.kde.elisa.desktop";
      "audio/x-musepack" = "org.kde.elisa.desktop";

      # === Document Viewer (Okular) ===
      "application/pdf" = "org.kde.okular.desktop";
      "application/epub+zip" = "org.kde.okular.desktop";
      "application/x-mobipocket-ebook" = "org.kde.okular.desktop";
      "application/x-fictionbook+xml" = "org.kde.okular.desktop";
      "application/x-cbz" = "org.kde.okular.desktop";
      "application/x-cbr" = "org.kde.okular.desktop";
      "application/x-cb7" = "org.kde.okular.desktop";
      "application/x-cbt" = "org.kde.okular.desktop";
      "application/vnd.ms-xpsdocument" = "org.kde.okular.desktop";
      "application/oxps" = "org.kde.okular.desktop";
      "image/vnd.djvu" = "org.kde.okular.desktop";
      "image/vnd.djvu+multipage" = "org.kde.okular.desktop";
      "application/postscript" = "org.kde.okular.desktop";
      "application/x-dvi" = "org.kde.okular.desktop";

      # === Archive Manager (Ark) ===
      "application/zip" = "org.kde.ark.desktop";
      "application/x-tar" = "org.kde.ark.desktop";
      "application/gzip" = "org.kde.ark.desktop";
      "application/x-gzip" = "org.kde.ark.desktop";
      "application/x-bzip2" = "org.kde.ark.desktop";
      "application/x-xz" = "org.kde.ark.desktop";
      "application/zstd" = "org.kde.ark.desktop";
      "application/x-zstd" = "org.kde.ark.desktop";
      "application/x-compressed-tar" = "org.kde.ark.desktop";
      "application/x-bzip2-compressed-tar" = "org.kde.ark.desktop";
      "application/x-xz-compressed-tar" = "org.kde.ark.desktop";
      "application/x-zstd-compressed-tar" = "org.kde.ark.desktop";
      "application/x-lzma-compressed-tar" = "org.kde.ark.desktop";
      "application/x-7z-compressed" = "org.kde.ark.desktop";
      "application/x-rar" = "org.kde.ark.desktop";
      "application/vnd.rar" = "org.kde.ark.desktop";
      "application/x-rpm" = "org.kde.ark.desktop";
      "application/x-deb" = "org.kde.ark.desktop";
      "application/x-lha" = "org.kde.ark.desktop";
      "application/x-lzop" = "org.kde.ark.desktop";
      "application/x-cpio" = "org.kde.ark.desktop";
      "application/x-archive" = "org.kde.ark.desktop";
      "application/x-lz4-compressed-tar" = "org.kde.ark.desktop";
      "application/x-java-archive" = "org.kde.ark.desktop";
      "application/x-arj" = "org.kde.ark.desktop";

      # === Drawing / Digital Art (Krita) ===
      "application/x-krita" = "org.kde.krita.desktop";
      "image/openraster" = "org.kde.krita.desktop";
      "application/x-photoshop" = "org.kde.krita.desktop";
      "image/x-psd" = "org.kde.krita.desktop";
      "image/x-xcf" = "org.kde.krita.desktop";

      # === Terminal (Ghostty) ===
      "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
    };
  };

  # Flatpak install handler desktop entry
  # Opens .flatpakref files in a small Ghostty terminal window for transparent installation
  xdg.dataFile."applications/com.github.kcalvelli.axios.flatpak-install.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=axiOS Flatpak Installer
    Comment=Install Flatpak applications from .flatpakref files
    Exec=${pkgs.ghostty}/bin/ghostty --class=com.github.kcalvelli.axios.flatpak-install -e axios-flatpak-install %f
    MimeType=application/vnd.flatpak.ref;application/vnd.flatpak.repo;
    NoDisplay=true
    Terminal=false
    Icon=com.mitchellh.ghostty
  '';

  systemd.user.services.kdeconnect = {
    Service.Environment = [ "XDG_MENU_PREFIX=plasma-" ];
  };

  # Configure Dolphin to use Ghostty as terminal emulator
  # Uses kwriteconfig6 to set only this key, preserving color scheme and other settings
  home.activation.configureDolphinTerminal = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file dolphinrc --group General --key TerminalApplication ghostty
  '';

  # Mask KDE Activity Manager (axiOS uses Niri workspaces, not KDE Activities)
  # This removes the "Activities" context menu item from Dolphin and other KDE apps
  systemd.user.services.plasma-kactivitymanagerd = {
    Unit.Description = "KDE Activity Manager (masked by axiOS)";
    Install = { };
    Service.ExecStart = "${pkgs.coreutils}/bin/true";
  };

  # Flatpak Flathub setup
  # Add Flathub remote for user-level flatpak installations
  # Runs during home-manager activation when network is available
  home.activation.setupFlathub = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Add Flathub remote for user flatpak (--if-not-exists makes it idempotent)
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
  '';
}
