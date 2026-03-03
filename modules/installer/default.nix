{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.axios.installer;
  calamares-autostart = pkgs.makeAutostartItem {
    name = "calamares";
    package = pkgs.calamares-nixos;
  };
in
{
  options.axios.installer = {
    enable = lib.mkEnableOption "axiOS graphical installer (Calamares)";
  };

  config = lib.mkIf cfg.enable {
    # ── Desktop environment for the live session ──────────────
    services.xserver.desktopManager.gnome.enable = true;
    services.xserver.displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };

    # Auto-login as the nixos live user
    services.displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

    # Ensure Calamares (Qt app) uses Wayland backend when appropriate
    environment.variables.QT_QPA_PLATFORM = "$([[ $XDG_SESSION_TYPE = \"wayland\" ]] && echo \"wayland\")";

    # Disable GNOME welcome dialog and idle suspend in the live session
    services.gnome.gnome-initial-setup.enable = false;

    # ── Calamares installer ───────────────────────────────────
    programs.partition-manager.enable = true;

    environment.systemPackages = [
      pkgs.calamares-nixos
      calamares-autostart
      pkgs.calamares-axios-extensions
      pkgs.glibcLocales
    ];

    # Support all locales for the installer
    i18n.supportedLocales = [ "all" ];
  };
}
