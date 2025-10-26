{ lib, homeModules, pkgs, config, ... }:
{
  imports = [
    ./niri.nix
  ];

  # Define Wayland options
  options.wayland = {
    enable = lib.mkEnableOption "Enable Wayland compisitors and related services";
  };

  # Configure wayland if enabled
  config = lib.mkIf config.wayland.enable {
    # Enable DankMaterialShell greeter with niri
    programs.dankMaterialShell.greeter = {
      enable = true;
      compositor.name = "niri";
      # Note: configHome will be set automatically to the first normal user's home
      # or can be overridden in host configuration if needed
    };

    # GNOME Keyring for credentials
    services.gnome.gnome-keyring.enable = true;
    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };

    niri.enable = true;

    programs = {
      xwayland.enable = true;
      nautilus-open-any-terminal.enable = true;
      nautilus-open-any-terminal.terminal = "ghostty";
      evince.enable = true;
      file-roller.enable = true;
      gnome-disks.enable = true;
      seahorse.enable = true;
    };

    services = {
      gnome = {
        sushi.enable = true;
      };
      accounts-daemon.enable = true;
      gvfs.enable = true;
    };

    # === Wayland Packages ===
    environment.systemPackages = with pkgs; [
      # System desktop applications
      mate.mate-polkit
      wayvnc
      xwayland-satellite
      brightnessctl

      # Icon themes
      colloid-icon-theme
      adwaita-icon-theme
      papirus-icon-theme

      # File manager and extensions
      nautilus
      code-nautilus
    ];

    # Enable some homeManager stuff
    home-manager.sharedModules = with homeModules; [
      wayland
    ];
  };
}
