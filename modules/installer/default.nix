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
