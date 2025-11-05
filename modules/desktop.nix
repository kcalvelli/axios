{ lib, pkgs, config, ... }:
{
  imports = [
    ./applications.nix
    ./wayland.nix
  ];

  wayland.enable = true;

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
  # Note: Most desktop applications are in applications.nix
  # This section is for desktop-specific tools
  environment.systemPackages = with pkgs; [
    # VPN
    protonvpn-gui
    # Streaming
    obs-studio
  ];
}
