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
    inputs.dankMaterialShell.homeModules.dank-material-shell
    inputs.dsearch.homeModules.default
  ];

  # Enable PWA apps by default for desktop users
  axios.pwa.enable = true;

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

  # Required to allow kdeconnect to show dolphin when browse device is selected
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/kdeconnect" = "org.kde.dolphin.desktop";
    };
  };

  systemd.user.services.kdeconnect = {
    Service.Environment = [ "XDG_MENU_PREFIX=gnome-" ];
  };

  # Trayscale (Tailscale system tray) - autostart if Tailscale is enabled
  systemd.user.services.trayscale = lib.mkIf (osConfig.services.tailscale.enable or false) {
    Unit = {
      Description = "Trayscale - Tailscale system tray";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.trayscale}/bin/trayscale --hide-window";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Flatpak Flathub setup
  # Add Flathub remote for user-level flatpak installations
  # Runs during home-manager activation when network is available
  home.activation.setupFlathub = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Add Flathub remote for user flatpak (--if-not-exists makes it idempotent)
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
  '';
}
