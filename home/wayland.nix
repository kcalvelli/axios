{ pkgs, inputs, config, ... }:
let
  # Package wallpaper scripts from axios
  wallpaperScripts = pkgs.runCommand "axios-wallpaper-scripts" {} ''
    mkdir -p $out/bin
    cp ${../../scripts/wallpaper-blur.sh} $out/bin/wallpaper-blur.sh
    cp ${../../scripts/update-material-code-theme.sh} $out/bin/update-material-code-theme.sh
    chmod +x $out/bin/*
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
    source = "${wallpaperScripts}/bin/wallpaper-blur.sh";
    executable = true;
  };

  home.file."scripts/update-material-code-theme.sh" = {
    source = "${wallpaperScripts}/bin/update-material-code-theme.sh";
    executable = true;
  };

  # Ensure cache directory for wallpaper blur
  home.activation.createNiriCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.cache/niri
  '';
}

