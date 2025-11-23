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
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams =
      [
        "panic=${toString cfg.rebootOnPanic}"
      ]
      ++ lib.optional cfg.treatOopsAsPanic "oops=panic";

    boot.crashDump.enable = cfg.enableCrashDump;
  };
}
