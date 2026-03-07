{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.axios.firstBoot;
in
{
  options.axios.firstBoot = {
    enable = lib.mkEnableOption "axiOS first-boot wizard" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.axios-first-boot ];

    systemd.user.services.axios-first-boot = {
      Unit = {
        Description = "axiOS First-Boot Wizard";
        After = [ "graphical-session.target" ];
        ConditionPathExists = "!%h/.cache/axios-first-boot-done";
      };

      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.axios-first-boot}/bin/axios-first-boot";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
