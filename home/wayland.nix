{ pkgs, inputs, config, ... }:
let
  # Wallpaper blur script for DankMaterialShell
  wallpaperBlurScript = pkgs.writeShellScript "wallpaper-blur" ''
    #!/usr/bin/env bash
    
    # Get the current wallpaper path from gsettings
    WALLPAPER=$(gsettings get org.gnome.desktop.background picture-uri | tr -d "'")
    WALLPAPER=''${WALLPAPER#file://}
    
    # Check if wallpaper exists
    if [ ! -f "$WALLPAPER" ]; then
        echo "Wallpaper not found: $WALLPAPER"
        exit 1
    fi
    
    # Output paths
    OUTPUT_DIR="$HOME/.cache/niri"
    BLUR_OUTPUT="$OUTPUT_DIR/overview-blur.jpg"
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    # Generate blurred version using ImageMagick
    # Blur: 0x8 provides a nice smooth blur
    # Quality: 85 balances file size and quality
    magick "$WALLPAPER" -blur 0x8 -quality 85 "$BLUR_OUTPUT"
    
    echo "Blurred wallpaper saved to: $BLUR_OUTPUT"
    
    # Notify user
    notify-send "Wallpaper Updated" "Blurred version created for overview mode"
  '';
  
  # Material code theme update script
  updateMaterialThemeScript = pkgs.writeShellScript "update-material-code-theme" ''
    #!/usr/bin/env bash
    
    # Get the accent color from gsettings (set by Dank Hooks)
    ACCENT=$(gsettings get org.gnome.desktop.interface gtk-theme | grep -o 'material-.*' | cut -d'-' -f2)
    
    if [ -z "$ACCENT" ]; then
        echo "No material theme accent found"
        exit 0
    fi
    
    # Update VSCode material theme if installed
    VSCODE_CONFIG="$HOME/.config/Code/User/settings.json"
    if [ -f "$VSCODE_CONFIG" ]; then
        # Use jq to update the material theme accent
        jq ".\"material-theme.accentPrevious\" = \"$ACCENT\"" "$VSCODE_CONFIG" > "$VSCODE_CONFIG.tmp"
        mv "$VSCODE_CONFIG.tmp" "$VSCODE_CONFIG"
        echo "Updated VSCode material theme accent to: $ACCENT"
    fi
  '';
in
{
  imports = [
    ./wayland-theming.nix
    ./wayland-material.nix
    ./niri.nix
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
  ];

  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.system}.default;
  };

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # Wayland desktop packages
  home.packages = let
    packages = import ./packages.nix { inherit pkgs; };
  in
    packages.launchers
    ++ packages.audio
    ++ packages.screenshot
    ++ packages.themes
    ++ packages.fonts
    ++ packages.qt
    ++ packages.utilities;

  # Wayland services
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # Wallpaper management scripts for DankMaterialShell
  home.file."scripts/wallpaper-changed.sh" = {
    source = wallpaperBlurScript;
    executable = true;
  };

  home.file."scripts/update-material-code-theme.sh" = {
    source = updateMaterialThemeScript;
    executable = true;
  };

  # Ensure cache directory for wallpaper blur
  home.activation.createNiriCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.cache/niri
  '';
}

