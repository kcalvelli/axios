# Operations & Deployment

## Purpose
Defines the procedures for system installation, automated validation, and continuous integration.

## Components

### Installation (Init Script)
- **Tool**: `nix run .#init`
- **Pattern**: Uses `hardwareConfigPath` to reference the system's `hardware-configuration.nix` directly, avoiding the fragile extraction of boot/filesystem settings.
- **Support**: Secure Boot enrollment guidance and UEFI-only partitioning.
- **Implementation**: `scripts/init-config.sh`

### Continuous Integration (GitHub Actions)
- **Flake Check**: Validates flake structure and buildable outputs.
- **Formatting**: Enforces `nixfmt-rfc-style` on all Nix files.
- **DevShell Builds**: Ensures all development shells remain buildable.
- **Lock Updater**: Weekly automated dependency updates with PR generation.
- **Implementation**: `.github/workflows/`

### Deployment Patterns
- **Library Model**: axiOS is exported as a flake library. Downstream hosts import modules and call `mkSystem`.
- **Secrets Management**:
    - `agenix`: System-level secrets (SSH keys, config files).
    - Session Variables: AI API keys (Brave, GitHub).
- **Implementation**: `lib/default.nix`, `modules/secrets/`

### ADDED Crash Diagnostics
- **Purpose**: Capture crash data and enable automatic recovery from system freezes.
- **Options**:
    - `hardware.crashDiagnostics.enable`: Enable crash diagnostics (kernel params, pstore)
    - `hardware.crashDiagnostics.enableHardwareWatchdog`: Enable hardware watchdog timer (default: true)
    - `hardware.crashDiagnostics.rebootOnPanic`: Seconds to wait before auto-reboot on panic (default: 30)
    - `hardware.crashDiagnostics.enableCrashDump`: Enable kdump for post-crash analysis (default: false)
- **Implementation**: `modules/hardware/crash-diagnostics.nix`

## ADDED Requirements

### Requirement: Hardware Watchdog for Hard Freeze Recovery

Systems MUST have hardware watchdog enabled by default when crash diagnostics are enabled, to recover from hard freezes that bypass software detection.

#### Scenario: GPU hang locks PCIe bus

- **Given**: User has crash diagnostics enabled (`hardware.crashDiagnostics.enable = true`)
- **And**: Hardware watchdog is enabled (default)
- **When**: GPU hang occurs that locks the PCIe bus
- **And**: CPU cannot service interrupts (NMI watchdog cannot fire)
- **And**: Software-based detection (softlockup, GPU recovery) cannot trigger
- **Then**: systemd stops petting the hardware watchdog
- **And**: After RuntimeWatchdogSec (30s), hardware watchdog triggers panic
- **And**: After RebootWatchdogSec (60s), hardware forces reboot
- **And**: System recovers within ~90 seconds instead of requiring manual power cycle

#### Scenario: User disables hardware watchdog

- **Given**: User has set `hardware.crashDiagnostics.enableHardwareWatchdog = false`
- **When**: Hard system freeze occurs
- **Then**: System remains frozen until manual power cycle
- **And**: User must physically reset the system

### Implementation

```nix
# In crash-diagnostics.nix config section:
systemd.extraConfig = lib.mkIf cfg.enableHardwareWatchdog ''
  RuntimeWatchdogSec=30
  RebootWatchdogSec=60
  KExecWatchdogSec=60
'';
```

## Procedures
- **Spec-Driven Development**: All changes MUST follow the OpenSpec workflow.
    - **Tool**: `openspec` CLI.
    - **Workflow**: Create delta in `openspec/changes/`, update specs, implement, and archive.
- **Formatting**: Always run `nix fmt .` before committing.
- **Testing**: Use `./scripts/test-build.sh` for local validation of heavy changes.
- **Conventional Commits**: All PRs and commits should follow standard git conventions.

## Troubleshooting

### System rebooted unexpectedly

**Symptoms**: System rebooted without user action, clean boot in journal.

**Check hardware watchdog status**:
```bash
systemctl show | grep Watchdog
# Expected: RuntimeWatchdogUSec=30s, RebootWatchdogUSec=1min
```

**If triggered by hard freeze (pstore empty)**:
- This is expected behavior - watchdog recovered from freeze
- Investigate previous boot: `journalctl -b -1 | tail -100`
- Check for GPU/hardware issues

**If triggered unexpectedly (system was responsive)**:
- Check if systemd was blocked on I/O
- Review disk/storage health
- Consider increasing RuntimeWatchdogSec if false positives occur

### Verify crash diagnostics are active

```bash
# Check kernel params
cat /proc/cmdline | grep -E "panic|oops|watchdog|crashkernel"

# Check hardware watchdog
ls /dev/watchdog*

# Check systemd watchdog config
systemctl show | grep -i watchdog

# Check pstore
ls /sys/fs/pstore/
```
