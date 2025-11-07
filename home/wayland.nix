{ pkgs, ... }:
{
  imports = [
    ./dankmaterialshell.nix
  ];

  # Gnome keyring for credential management
  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # NOTE: Wayland desktop packages (fuzzel, wl-clipboard, theming, etc.) have been
  # moved to modules/applications.nix for system-level installation.
  # DankMaterialShell configuration has been moved to dankmaterialshell.nix.

  # KDE Connect for phone integration
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
}

