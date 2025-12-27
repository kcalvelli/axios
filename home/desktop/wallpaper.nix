{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.axios.wallpapers;

  # Wallpaper change hook script for DankMaterialShell
  # This is a hook script called by Dank Hooks plugin with:
  # $1 = hook name ("onWallpaperChanged")
  # $2 = wallpaper path
  wallpaperChangedScript = ../../scripts/wallpaper-changed.sh;

  # Directory containing curated wallpapers
  wallpapersDir = ../resources/wallpapers;

  # Get list of wallpaper files
  wallpaperFiles = builtins.filter (
    name: lib.hasSuffix ".jpg" name || lib.hasSuffix ".png" name || lib.hasSuffix ".jpeg" name
  ) (builtins.attrNames (builtins.readDir wallpapersDir));

  # Generate home.file entries for each wallpaper
  wallpaperFileEntries = builtins.listToAttrs (
    map (filename: {
      name = "Pictures/Wallpapers/${filename}";
      value = {
        source = wallpapersDir + "/${filename}";
      };
    }) wallpaperFiles
  );
in
{
  options.axios.wallpapers = {
    enable = lib.mkEnableOption "curated wallpaper collection";

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically set a new random wallpaper when the wallpaper collection changes.
        If false, wallpaper files will still be updated, but the active wallpaper won't change.
      '';
    };
  };

  config = lib.mkMerge [
    # Base wallpaper configuration (always enabled)
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

    # Wallpaper collection (conditional)
    (lib.mkIf cfg.enable {
      # Deploy curated wallpapers to ~/Pictures/Wallpapers
      home.file = wallpaperFileEntries;

      # Set random wallpaper on first activation or when collection changes
      home.activation.setRandomWallpaper = lib.mkIf cfg.autoUpdate (
        config.lib.dag.entryAfter [ "writeBoundary" ] ''
          WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
          HASH_FILE="$HOME/.cache/axios-wallpaper-collection-hash"

          # Create a hash of the wallpaper collection (sorted filenames)
          if [ -d "$WALLPAPER_DIR" ]; then
            CURRENT_HASH=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -printf "%f\n" | sort | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)

            # Read previous hash if it exists
            PREVIOUS_HASH=""
            if [ -f "$HASH_FILE" ]; then
              PREVIOUS_HASH=$(cat "$HASH_FILE")
            fi

            # If hash changed (or first run), set a new random wallpaper
            if [ "$CURRENT_HASH" != "$PREVIOUS_HASH" ]; then
              # Get list of wallpapers
              wallpapers=("$WALLPAPER_DIR"/*.{jpg,png,jpeg})

              # Check if any wallpapers exist (glob expansion check)
              if [ -f "''${wallpapers[0]}" ]; then
                # Select random wallpaper
                random_index=$((RANDOM % ''${#wallpapers[@]}))
                random_wallpaper="''${wallpapers[$random_index]}"

                # Set wallpaper using dms
                $DRY_RUN_CMD ${pkgs.dankMaterialShell}/bin/dms ipc call wallpaper set "$random_wallpaper" || true

                # Save the new hash
                $DRY_RUN_CMD mkdir -p "$(dirname "$HASH_FILE")"
                $DRY_RUN_CMD echo "$CURRENT_HASH" > "$HASH_FILE"

                if [ -n "$VERBOSE" ]; then
                  echo "axiOS: Wallpaper collection changed, set new random wallpaper: $random_wallpaper"
                fi
              fi
            fi
          fi
        ''
      );
    })
  ];
}
