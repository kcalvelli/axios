{ pkgs, inputs, config, ... }:
let
  # Package wallpaper scripts from axios
  wallpaperBlurScript = pkgs.writeShellScript "wallpaper-blur" (builtins.readFile ../../scripts/wallpaper-blur.sh);
  updateMaterialThemeScript = pkgs.writeShellScript "update-material-code-theme" (builtins.readFile ../../scripts/update-material-code-theme.sh);
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

