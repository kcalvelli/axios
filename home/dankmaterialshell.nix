{ pkgs, inputs, config, lib, ... }:
let
  # Fetch DankHooks plugin from the dms-plugins repo
  dmsPluginsRepo = pkgs.fetchFromGitHub {
    owner = "AvengeMedia";
    repo = "dms-plugins";
    rev = "5f36976676ece21d0c838c0639f193ecc77ea3f2";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Will be updated on first build
  };
  
  # Directory structure for DankMaterialShell
  dmsConfigDir = "${config.xdg.configHome}/DankMaterialShell";
  pluginsDir = "${dmsConfigDir}/plugins";
  
  # Consistent hash for the repo (matches DMS plugin manager)
  repoHash = builtins.substring 0 16 (builtins.hashString "sha256" "https://github.com/AvengeMedia/dms-plugins");
  
  # Wallpaper blur script
  wallpaperBlurScript = ../scripts/wallpaper-blur.sh;
in
{
  imports = [
    ./wayland-theming.nix
    ./wayland-material.nix
    ./niri.nix
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  # Enable DankMaterialShell
  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
    niri = {
      enableKeybinds = true;
      enableSpawn = true;
    };
  };

  # Install wallpaper management scripts
  home.file."scripts/wallpaper-changed.sh" = {
    source = wallpaperBlurScript;
    executable = true;
  };

  # Ensure cache directory for wallpaper blur
  home.activation.createNiriCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.cache/niri
  '';

  # Install and configure Dank Hooks plugin for wallpaper blur automation
  home.activation.dankHooksPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Setting up DankMaterialShell Dank Hooks plugin..."
    
    # Create plugin directory structure
    $DRY_RUN_CMD mkdir -p ${pluginsDir}/.repos/${repoHash}
    
    # Copy DankHooks plugin from the repo
    $DRY_RUN_CMD cp -r ${dmsPluginsRepo}/DankHooks ${pluginsDir}/.repos/${repoHash}/
    
    # Create symlink with space in name (as DMS expects)
    $DRY_RUN_CMD ln -sf ${pluginsDir}/.repos/${repoHash}/DankHooks ${pluginsDir}/"Dank Hooks"
    
    # Create meta file for the plugin
    cat > ${pluginsDir}/"Dank Hooks.meta" << 'EOF'
repo=https://github.com/AvengeMedia/dms-plugins
path=DankHooks
repodir=${repoHash}
EOF
    
    echo "  ✓ Dank Hooks plugin installed"
    echo ""
    echo "  📝 Next step: Configure the wallpaper hook in DankMaterialShell:"
    echo "     1. Open DankMaterialShell settings"
    echo "     2. Go to Dank Hooks plugin settings"
    echo "     3. Set 'Wallpaper Changed' to: $HOME/scripts/wallpaper-changed.sh"
    echo ""
  '';
}

