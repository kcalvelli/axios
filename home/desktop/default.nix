{ inputs, ... }:

{
  imports = [
    ./theming.nix
    ./wallpaper.nix
    ./niri.nix
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
  ];

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
