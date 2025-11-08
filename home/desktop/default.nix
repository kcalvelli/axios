{ inputs, pkgs, config, ... }:

{
  imports = [
    ./theming.nix
    ./wallpaper.nix
    ./niri.nix
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dsearch.homeModules.default
  ];

  # DankMaterialShell configuration
  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Install DankHooks plugin for wallpaper blur and other system event hooks
    plugins.dankHooks = {
      enable = true;
      src = ./dms-plugins/DankHooks;
    };
  };

  # Configure DankHooks plugin default settings (only if plugin_settings.json doesn't exist)
  home.activation.setDefaultPluginSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        pluginSettingsFile="$HOME/.config/DankMaterialShell/plugin_settings.json"
        if [ ! -f "$pluginSettingsFile" ]; then
          $DRY_RUN_CMD mkdir -p "$HOME/.config/DankMaterialShell"
          cat > "$pluginSettingsFile" << 'EOF'
    {
      "dankHooks": {
        "enabled": true,
        "wallpaperPath": "${config.home.homeDirectory}/scripts/wallpaper-changed.sh"
      }
    }
    EOF
        fi
  '';

  programs.dsearch = {
    enable = true;
  };

  # Desktop services
  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
}
