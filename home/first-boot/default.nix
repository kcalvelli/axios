{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cairn.firstBoot;
in
{
  options.cairn.firstBoot = {
    enable = lib.mkEnableOption "Cairn first-boot wizard" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.cairn-first-boot ];

    systemd.user.services.cairn-first-boot = {
      Unit = {
        Description = "Cairn First-Boot Wizard";
        After = [ "graphical-session.target" ];
        ConditionPathExists = "!%h/.cache/cairn-first-boot-done";
      };

      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.cairn-first-boot}/bin/cairn-first-boot";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
