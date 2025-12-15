{
  inputs,
  pkgs,
  config,
  ...
}:

{
  imports = [
    ./theming.nix
    ./wallpaper.nix
    ./niri.nix
    ./gdrive-sync.nix
    ./pwa-apps.nix
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dsearch.homeModules.default
  ];

  # Enable PWA apps by default for desktop users
  axios.pwa.enable = true;

  # DankMaterialShell configuration
  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Systemd integration
    systemd = {
      enable = true; # Enable systemd user service
      restartIfChanged = true; # Auto-restart DMS on config changes
    };

    # Feature toggles (explicit configuration for clarity)
    enableSystemMonitoring = true; # System resource monitoring widgets
    enableClipboard = true; # Clipboard history with cliphist
    enableVPN = true; # VPN status widget
    enableBrightnessControl = true; # Screen/keyboard brightness controls
    enableColorPicker = true; # Color picker tool (hyprpicker)
    enableDynamicTheming = true; # Dynamic theme generation (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableSystemSound = true; # System sound effects
  };

  programs.dsearch = {
    enable = true;
  };

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

  # Flatpak Flathub setup
  # Add Flathub remote for user-level flatpak installations
  # Runs during home-manager activation when network is available
  home.activation.setupFlathub = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Add Flathub remote for user flatpak (--if-not-exists makes it idempotent)
    $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
  '';
}
