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

    # Systemd integration
    systemd = {
      enable = true; # Enable systemd user service
      restartIfChanged = true; # Auto-restart DMS on config changes
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
