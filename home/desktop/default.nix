{ inputs, pkgs, ... }:

{
  imports = [
    ./theming.nix
    ./wallpaper.nix
    ./niri.nix
    ./syncthing.nix
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dsearch.homeModules.default
  ];

  # DankMaterialShell configuration
  programs.dankMaterialShell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

