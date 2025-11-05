{ config, pkgs, ... }:
{
  systemd.user.services.vdirsyncer-sync = {
    Unit = {
      Description = "vdirsyncer: sync calendars/contacts";
      After = [ "network.target" ]; # optional for user units
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = "%h";
      # sync all pairs (covers Google + Orthocal HTTP ICS)
      ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
      # be nice to logs: only show real errors
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  systemd.user.timers.vdirsyncer-sync = {
    Unit.Description = "Run vdirsyncer sync every 5 minutes";
    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
      RandomizedDelaySec = "30s";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Optional but recommended: pick up new/renamed calendars & colors
  systemd.user.services.vdirsyncer-metasync = {
    Unit.Description = "vdirsyncer: metasync (names/colors)";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "%h";
      ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer metasync";
    };
  };

  systemd.user.timers.vdirsyncer-metasync = {
    Unit.Description = "Run vdirsyncer metasync daily";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

}
