# Hardware & Graphics Support

## Purpose
Ensures optimal hardware performance and driver support across different GPU vendors while maintaining a unified module interface.

## Components

### GPU Driver Engine
- **Interface**: `hardware.gpu` option in host configuration.
- **Nvidia**: Automatically sets video drivers, enables `nvidiaSettings`, and configures Beta packages if needed.
- **AMD**: Enables `amdgpu` kernel modules, provides `amdgpu_top`, and supports optional GPU recovery (`axios.hardware.enableGPURecovery`).
- **Intel**: VA-API acceleration and `intel-gpu-tools`.
- **Implementation**: `modules/graphics/default.nix`

### Hardware Profiles
- **Desktop**: Performance-oriented tuning (`hardware.desktop.cpuGovernor = "powersave"` by default for modern drivers).
- **Laptop**: Battery-aware tuning with TLP or similar profiles.
- **Implementation**: `modules/hardware/desktop.nix`, `modules/hardware/laptop.nix`

### Peripherals
- **Gaming**: Controller support (Udev rules) and binary compatibility layer (`nix-ld`) for native Linux games.
- **Logitech**: Solaar/Udev rules support for Unifying receivers.

## UPDATED Requirements

### Requirement: AMD GPU Hang Recovery (Enabled by Default)

AMD GPUs MUST have hang recovery enabled by default to prevent system freezes from GPU hangs.

#### Scenario: GPU hang with recovery enabled (default)

- **Given**: User has AMD GPU (gpuType = "amd")
- **And**: `axios.hardware.enableGPURecovery` is enabled (default: true for AMD)
- **When**: GPU hangs due to queue oversubscription or compute timeout
- **Then**: Kernel detects hang within lockup_timeout (5 seconds)
- **And**: Kernel resets GPU instead of freezing entire system
- **And**: User can recover session without power cycle

#### Scenario: User explicitly disables GPU recovery

- **Given**: User has AMD GPU
- **And**: User has set `axios.hardware.enableGPURecovery = false`
- **When**: GPU hangs due to heavy workload
- **Then**: System may freeze completely
- **And**: User must power cycle to recover

### Requirement: GPU Lockup Timeout Configuration

When GPU recovery is enabled, axios MUST also configure lockup timeout for faster detection.

#### Implementation

```nix
boot.kernelParams = lib.optionals (isAmd && config.axios.hardware.enableGPURecovery) [
  "amdgpu.gpu_recovery=1"       # Enable GPU reset on hang
  "amdgpu.lockup_timeout=5000"  # Detect hangs within 5 seconds
];
```

## Constraints
- **Wayland Compatibility**: Kernels are configured with `nvidia_drm.modeset=1` automatically for Nvidia.
- **Library Reference**: Use `pkgs.stdenv.hostPlatform.system` for system-specific packages.
- **GPU Recovery**: AMD GPUs have hang recovery enabled by default; users can disable if experiencing false-positive resets.
- **Hardware Watchdog**: For complete freeze protection, enable `hardware.crashDiagnostics.enable` which activates the hardware watchdog timer as a last-resort recovery mechanism (see ops/spec.md).

## Troubleshooting

### Hard system freeze on AMD GPU (if recovery was disabled)

**Symptoms**: Complete system lockup requiring power cycle, no pstore crash data.

**Cause**: GPU hang that freezes the compositor, which freezes the entire system.

**Fix**: Ensure GPU recovery is enabled (this is now the default):
```nix
axios.hardware.enableGPURecovery = true;  # default for AMD
```

### GPU resets unexpectedly

**Symptoms**: Screen flickers, applications crash, "GPU reset" in dmesg.

**Cause**: GPU hang detected by lockup_timeout, kernel performed reset.

**Investigation**:
1. Check dmesg for hang cause: `dmesg | grep -i amdgpu`
2. Check if VRAM was oversubscribed: `amdgpu_top` during workload
3. Review AI model sizes vs available VRAM (see AI spec)

**If false positives**: Disable recovery (not recommended):
```nix
axios.hardware.enableGPURecovery = false;
```

### System rebooted unexpectedly (hardware watchdog)

**Symptoms**: System rebooted without user action, no kernel panic in pstore, journal shows clean boot.

**Cause**: Hardware watchdog triggered due to complete system freeze. This is **expected behavior** when:
- GPU hang locks PCIe bus
- Kernel unable to service interrupts
- All software-based detection failed

**Investigation**:
1. Check previous boot's final logs: `journalctl -b -1 | tail -100`
2. Look for GPU-related warnings before freeze
3. Check if pstore is empty: `ls /sys/fs/pstore/` (empty = hard freeze, not panic)

**This is working as intended** - the hardware watchdog limited downtime to ~90 seconds instead of requiring manual intervention.

**If watchdog triggers frequently**: Investigate GPU stability (check VRAM usage, reduce AI model sizes, check thermals).
