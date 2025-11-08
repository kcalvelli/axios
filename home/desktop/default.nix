{ inputs, pkgs, ... }:

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

  # Configure DankHooks plugin settings
  xdg.configFile."DankMaterialShell/plugin_settings.json".text = builtins.toJSON {
    dankHooks = {
      enabled = true;
      wallpaperPath = toString (pkgs.writeShellScript "wallpaper-changed" (builtins.readFile ./scripts/wallpaper-changed.sh));
    };
  };

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
