{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.enable {
    
    # === Core Flatpak Services ===
    services.flatpak.enable = true;

    # === Flatpak Utilities & Store ===
    environment.systemPackages = with pkgs; [
      # The Store (Qt-based, native look)
      kdePackages.discover

      # The Janitor (Manage remotes and delete leftover user data)
      warehouse
    ];

    # === Flathub Remote Setup ===
    # Adds Flathub automatically on first boot/rebuild
    system.activationScripts.setupFlathubSystem = {
      text = ''
        ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
      '';
      deps = [ "etc" ];
    };
  };
}