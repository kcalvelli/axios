{ lib, homeModules, pkgs, config, ... }:
{
  # Define Wayland options
  options = {
    wayland = {
      enable = lib.mkEnableOption "Enable Wayland compisitors and related services";
    };
    niri = {
      enable = lib.mkEnableOption "Enable Niri";
    };
  };

  # Configure wayland if enabled
  config = lib.mkIf config.wayland.enable {
    # === Wayland Environment Variables ===
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # == Use Flathub as the only repo in GNOME Software ==
      GNOME_SOFTWARE_REPOS_ENABLED = "flathub";
      GNOME_SOFTWARE_USE_FLATPAK_ONLY = "1";
    };

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
      niri.enable = true;
      xwayland.enable = true;
      dconf.enable = true;
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
