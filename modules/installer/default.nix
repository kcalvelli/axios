{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.axios.installer;

  # Wrap calamares to run under XWayland (xcb) — it ships without the
  # Qt Wayland plugin, so we just let it be an X11 app via xwayland-satellite.
  # libxcb-cursor is required by the Qt xcb platform plugin at runtime.
  calamares-wrapped =
    pkgs.runCommand "calamares-wrapped"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p $out/bin $out/share
        cp -rs ${pkgs.calamares-nixos}/share/* $out/share/ 2>/dev/null || true
        makeWrapper ${pkgs.calamares-nixos}/bin/calamares $out/bin/calamares \
          --prefix LD_LIBRARY_PATH : "${pkgs.xcb-util-cursor}/lib" \
          --set QT_QPA_PLATFORM xcb
      '';

  calamares-autostart = pkgs.makeAutostartItem {
    name = "calamares";
    package = calamares-wrapped;
  };
in
{
  options.axios.installer = {
    enable = lib.mkEnableOption "axiOS graphical installer (Calamares)";
  };

  config = lib.mkIf cfg.enable {
    # ── Niri + DMS live session ───────────────────────────────
    programs.niri.enable = true;
    programs.xwayland.enable = true;
    programs.dconf.enable = true;

    # DMS system-level (no greeter — live ISO auto-logins directly)
    programs.dank-material-shell = {
      enable = true;
      quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      greeter.enable = lib.mkForce false;
    };

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "niri";
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # greetd auto-login — skip greeter entirely for live session
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "niri-session";
        user = "nixos";
      };
    };

    # Keyring and portal support
    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config.niri.default = [
        "gnome"
        "gtk"
      ];
    };

    # Niri binary cache for the ISO build
    nix.settings = {
      substituters = [ "https://niri.cachix.org" ];
      trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
    };

    # ── Home-manager for nixos live user (minimal DMS config) ─
    home-manager.users.nixos = {
      imports = [
        inputs.niri.homeModules.niri
        inputs.dankMaterialShell.homeModules.niri
        inputs.dankMaterialShell.homeModules.dank-material-shell
      ];

      home.stateVersion = "24.11";

      programs.niri = {
        package = lib.mkForce pkgs.niri;
        settings = {
          prefer-no-csd = true;
          hotkey-overlay.skip-at-startup = true;
          # Enable xwayland-satellite so X11 apps (Calamares) can run
          spawn-at-startup = [
            {
              command = [
                "dbus-update-activation-environment"
                "--systemd"
                "DISPLAY"
                "WAYLAND_DISPLAY"
                "XDG_CURRENT_DESKTOP"
                "XDG_SESSION_TYPE"
                "XDG_SESSION_DESKTOP"
                "NIXOS_OZONE_WL"
              ];
            }
          ];
        };
      };

      programs.dank-material-shell = {
        enable = true;
        quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
        systemd.enable = false;
        niri = {
          enableKeybinds = true;
          enableSpawn = true;
        };
      };
    };

    # ── Calamares installer ───────────────────────────────────
    programs.partition-manager.enable = true;

    environment.systemPackages = [
      calamares-wrapped
      calamares-autostart
      pkgs.calamares-axios-extensions
      pkgs.glibcLocales
      pkgs.xwayland-satellite
    ];

    # Support all locales for the installer
    i18n.supportedLocales = [ "all" ];
  };
}
