{ lib, config, ... }:
{
  options = {
    system.memory.oomd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable systemd-oomd (Out-Of-Memory Daemon) to prevent system hangs
          caused by memory exhaustion. The daemon monitors memory pressure and
          kills memory-hogging processes before the system becomes unresponsive.
        '';
      };
    };
  };

  config = lib.mkIf config.system.memory.oomd.enable {
    # Enable systemd-oomd service
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };

    # Configure memory pressure thresholds
    # These settings determine when oomd starts killing processes
    systemd.slices = {
      # System slice: more conservative (system services)
      "system.slice" = {
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          ManagedOOMMemoryPressureLimit = "80%";
        };
      };

      # User slice: more aggressive (user applications like browsers)
      "user.slice" = {
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          ManagedOOMMemoryPressureLimit = "50%";
        };
      };

      # Root slice: last resort protection
      "-.slice" = {
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          ManagedOOMMemoryPressureLimit = "90%";
        };
      };
    };

    # Additional memory management settings
    boot.kernel.sysctl = {
      # Enable pressure stall information (required for oomd)
      "kernel.pressure.enable" = 1;

      # Tune OOM killer behavior
      "vm.oom_kill_allocating_task" = 0; # Kill the memory hog, not the allocating task
      "vm.overcommit_memory" = 0; # Heuristic overcommit
      "vm.panic_on_oom" = 0; # Don't panic, let oomd/kernel handle it
    };
  };
}
