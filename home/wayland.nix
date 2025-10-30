{ pkgs, inputs, config, ... }:
let
  # Wallpaper blur script for DankMaterialShell
  # This is a hook script called by Dank Hooks plugin with:
  # $1 = hook name ("onWallpaperChanged")
  # $2 = wallpaper path
  wallpaperBlurScript = ../scripts/wallpaper-blur.sh;
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
  home.packages = with pkgs; [
    # Launchers and input
    fuzzel
    wl-clipboard
    wtype

    # Audio control
    playerctl
    pavucontrol
    cava

    # Screenshot and screen tools
    grimblast
    grim
    slurp
    hyprpicker

    # Theming and appearance
    matugen
    colloid-gtk-theme
    colloid-icon-theme
    adwaita-icon-theme
    papirus-icon-theme
    adw-gtk3

    # Qt configuration
    kdePackages.qt6ct

    # Fonts
    nerd-fonts.fira-code
    inter
    material-symbols

    # System utilities
    baobab
    swappy
    qalculate-gtk
    swaybg
    imagemagick
    libnotify
    gnome-software
    gnome-text-editor
  ];

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

  # Ensure cache directory for wallpaper blur
  home.activation.createNiriCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.cache/niri
  '';
}

