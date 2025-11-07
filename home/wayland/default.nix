{ pkgs, inputs, config, ... }:
let
  # Wallpaper change hook script for DankMaterialShell
  # This is a hook script called by Dank Hooks plugin with:
  # $1 = hook name ("onWallpaperChanged")
  # $2 = wallpaper path
  wallpaperChangedScript = ../scripts/wallpaper-changed.sh;
in
{
  imports = [
    ./theming.nix
    ../niri
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
  ];

  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # NOTE: Wayland desktop packages (fuzzel, wl-clipboard, theming, etc.) have been
  # moved to modules/applications.nix for system-level installation.
  # This module now focuses purely on Wayland configuration and services.

  # Wayland services
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # Wallpaper management scripts for DankMaterialShell
  home.file."scripts/wallpaper-changed.sh" = {
    source = wallpaperChangedScript;
    executable = true;
  };

  # Ensure cache directory for wallpaper blur
  home.activation.createNiriCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.cache/niri
  '';
}

