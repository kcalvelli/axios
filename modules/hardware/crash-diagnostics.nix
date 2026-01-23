{ config, lib, ... }:

let
  cfg = config.hardware.crashDiagnostics;
in
{
  options.hardware.crashDiagnostics = {
    enable = lib.mkEnableOption "kernel crash diagnostics and recovery";

    rebootOnPanic = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        Automatically reboot N seconds after a kernel panic.
        Set to 0 to disable automatic reboot (system will halt on panic).
        Default: 30 seconds for quick recovery.
      '';
    };

    enableCrashDump = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable kdump for post-crash analysis.

        WARNING: This reserves a portion of RAM for crash dumps.
        On systems with limited RAM, this may impact performance.

        When enabled, crash dumps are saved to /var/crash/ and can be
        analyzed with crash(8) or sent to kernel developers for debugging.
      '';
    };

    treatOopsAsPanic = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Treat kernel oops as fatal panics.

        When true, kernel oops (non-fatal errors) will trigger a panic,
        which can then trigger reboot or crash dump. This prevents
        systems from running in a degraded state after kernel errors.

        Default: true (more aggressive recovery, prevents zombie systems)
      '';
    };

    enableHardwareWatchdog = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable hardware watchdog timer via systemd.

        This provides last-resort recovery from hard system freezes that bypass
        all software-based detection (NMI watchdog, softlockup, GPU recovery).

        The hardware watchdog (e.g., sp5100-tco on AMD, iTCO on Intel) operates
        independently of the CPU and will force a reboot if systemd stops responding.

        How it works:
        - systemd pets /dev/watchdog every RuntimeWatchdogSec/2 (15 seconds)
        - If systemd freezes, hardware watchdog triggers after RuntimeWatchdogSec (30s)
        - If reboot hangs, hardware forces reset after RebootWatchdogSec (60s)

        Default: true (limits hard freeze downtime to ~90 seconds)
      '';
    };

    runtimeWatchdogSec = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        Hardware watchdog timeout in seconds.
        systemd will pet the watchdog at half this interval.
        If the system freezes, the watchdog triggers after this timeout.
        Default: 30 seconds.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "panic=${toString cfg.rebootOnPanic}"
    ]
    ++ lib.optional cfg.treatOopsAsPanic "oops=panic";

    boot.crashDump.enable = cfg.enableCrashDump;

    # Hardware watchdog via systemd
    # This provides last-resort recovery from hard freezes that bypass software detection
    systemd.extraConfig = lib.mkIf cfg.enableHardwareWatchdog ''
      RuntimeWatchdogSec=${toString cfg.runtimeWatchdogSec}
      RebootWatchdogSec=60
      KExecWatchdogSec=60
    '';
  };
}
