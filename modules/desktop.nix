{ lib, pkgs, config, ... }:
{
  imports = [
    ./wayland.nix
  ];

  wayland.enable = true;

  # === Wayland Environment Variables ===
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # == Use Flathub as the only repo in GNOME Software ==
      GNOME_SOFTWARE_REPOS_ENABLED = "flathub";
      GNOME_SOFTWARE_USE_FLATPAK_ONLY = "1";      
    };
  };

  # === Desktop Services ===
  # Services needed by all WMs/DEs
  services = {
    udisks2.enable = true;
    system76-scheduler.enable = true;
    flatpak.enable = true;
    fwupd.enable = true;
    upower.enable = true;
    libinput.enable = true;
    acpid.enable = true;
    power-profiles-daemon.enable = lib.mkDefault (
      !config.hardware.system76.power-daemon.enable
    );
  };

  # === Desktop Programs ===
  programs = {
    corectrl.enable = true;
    kdeconnect.enable = true;
    dconf.enable = true;
    localsend = {
      enable = true;
      openFirewall = true;
    };
  };

  # === XDG Portal Configuration ===
  xdg = {
    mime.enable = true;
    icons.enable = true;
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = [ "gnome" "gtk" ];
    };
  };

  # === Desktop Applications ===
  environment.systemPackages = with pkgs; [
    # VPN
    mullvad-vpn
    # Streaming
    obs-studio
  ];
}
