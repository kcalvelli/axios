{ inputs, pkgs, ... }:

{
  imports = [
    ./theming.nix
    ./wallpaper.nix
    ./niri.nix
    ./gdrive-sync.nix
    ./pwa-apps.nix
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dsearch.homeModules.default
  ];

  # Enable PWA apps by default for desktop users
  axios.pwa.enable = true;

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

