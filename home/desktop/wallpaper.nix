{ config, ... }:

let
  # Wallpaper change hook script for DankMaterialShell
  # This is a hook script called by Dank Hooks plugin with:
  # $1 = hook name ("onWallpaperChanged")
  # $2 = wallpaper path
  wallpaperChangedScript = ../../scripts/wallpaper-changed.sh;
in
{
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
