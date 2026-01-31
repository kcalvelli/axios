# Troubleshooting Guide

## Build Failures: "getting attributes of path" Errors

### Symptoms
```
error: getting attributes of path '/nix/store/...-stdenv-linux': No such file or directory
error: getting attributes of path '/nix/store/...-gnu-config-...': No such file or directory
```

### Root Causes
1. **FlakeHub References** - Expired FlakeHub account causing corrupted flake.lock entries
2. **Nix Store Corruption** - Missing or inconsistent store paths
3. **Determinate Nix Issues** - Transitive dependencies pulling in FlakeHub

### Solutions (Try in Order)

#### 1. Remove FlakeHub References
Already done in axios as of commit `0728065`. Verify your config:

```bash
cd ~/my-nixos-config
cat flake.lock | jq '[.nodes | to_entries[] | select(.value.locked.url != null and (.value.locked.url | contains("flakehub")))] | length'
# Should output: 0
```

If not zero:
```bash
nix flake lock --override-input axios /path/to/axios
```

#### 2. Clean Nix Store
```bash
# Aggressive garbage collection
nix-collect-garbage -d

# Verify store integrity  
nix-store --verify --check-contents

# Delete specific problematic paths
nix-store --delete /nix/store/PROBLEMATIC-PATH
```

#### 3. Restart Nix Daemon
```bash
sudo systemctl restart nix-daemon.service
```

#### 4. Nuclear Option: Fresh Build Environment
If corruption persists:

```bash
# Backup your configuration
cd ~/my-nixos-config
git commit -am "backup before store rebuild"

# Clear all build artifacts
nix-collect-garbage -d
sudo nix-collect-garbage -d

# Rebuild with fresh downloads
sudo nixos-rebuild switch --flake .#hostname --option tarball-ttl 0
```

#### 5. Downgrade from Determinate Nix (Last Resort)
If Determinate Nix itself is causing issues:

```bash
# Switch to standard Nix
# Remove determinate from your flake inputs
# Re-enable after the issue is resolved
```

## Prevention

### Use PR-Based Updates
- Review flake.lock changes before merging
- Test updates locally before deploying
- Check for FlakeHub references in PRs

### Pin Stable Versions
For critical systems:
```nix
inputs.axios.url = "github:kcalvelli/axios/KNOWN-GOOD-COMMIT";
```

### Monitor Store Health
Regular verification:
```bash
# Weekly check
nix-store --verify --check-contents

# Monthly cleanup
nix-collect-garbage --delete-older-than 30d
```

## Known Issues

### FlakeHub After Account Expiration
- **Status:** RESOLVED (removed from axios)
- **Commit:** 0728065
- **Date:** 2025-10-29

### Determinate Input
- **Status:** DISABLED (commented out)
- **Reason:** Pulls in FlakeHub transitive dependencies
- **Impact:** NixOS module not imported, daemon still works
- **Future:** Can re-enable when FlakeHub-free version available

### DMS Keybindings Stop Working After `rebuild-switch`

- **Status:** KNOWN LIMITATION
- **Affects:** DMS-provided keybindings (Mod+Space, Mod+V, media keys, etc.)
- **Does NOT affect:** axiOS keybindings (Mod+B, Mod+T, etc.) or Niri window management keys

**Symptom:** After running `rebuild-switch` (or `nixos-rebuild switch`), DMS keybindings like the application launcher (Mod+Space), clipboard manager (Mod+V), and media keys stop responding. axiOS and Niri keybindings continue to work normally.

**Cause:** DMS keybindings work by invoking `dms ipc call ...`, which discovers the running DMS instance via a quickshell IPC socket keyed to the nix store path. After a rebuild, the `dms` CLI updates to a new store path but the running DMS instance is still registered under the old path. The CLI can't find the running instance:

```
No running instances for "/nix/store/<new-hash>-dms-shell-.../share/quickshell/dms/shell.qml"
```

**Workaround:** Log out and back in (or reboot). This restarts DMS with the new store path so the CLI and running instance match.

## Hardware-Specific Issues

axiOS provides generic hardware support (CPU/GPU types, form factors), but vendor-specific quirks belong in your downstream configuration via the `extraConfig` section.

### Common Hardware Quirk Patterns

#### Pattern 1: Kernel Module Loading

```nix
extraConfig = {
  boot.kernelModules = [ "module-name" ];
};
```

**When to use**: Hardware requires a module not loaded automatically (sensors, controllers, vendor features).

#### Pattern 2: Kernel Module Blacklisting

```nix
extraConfig = {
  boot.blacklistedKernelModules = [ "problematic-module" ];
};
```

**When to use**: Kernel loads wrong driver causing conflicts.

#### Pattern 3: Module Parameters

```nix
extraConfig = {
  boot.extraModprobeConfig = ''
    options module-name parameter=value
  '';
};
```

**When to use**: Hardware needs specific tuning (Wi-Fi/Bluetooth quirks, GPU options, power management).

#### Pattern 4: Kernel Parameters

```nix
extraConfig = {
  boot.kernelParams = [ "parameter=value" ];
};
```

**When to use**: ACPI workarounds, GPU boot options, memory/CPU tuning.

### Example: MSI Motherboard Sensors

**Issue**: Fan and temperature sensors require specific kernel module

```nix
extraConfig = {
  boot.kernelModules = [ "nct6775" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
};
```

### Example: System76 Pangolin 12 Laptop

**Issues**: Multiple hardware-specific quirks

```nix
extraConfig = {
  hardware.system76 = {
    firmware-daemon.enable = true;
    power-daemon.enable = true;
  };

  boot = {
    kernelModules = [ "system76_acpi" ];
    blacklistedKernelModules = [ "psmouse" ];
    extraModprobeConfig = ''
      options mt7921_common disable_clc=1
    '';
  };
};
```

### Example: Logitech Wireless Peripherals

**Issue**: Wireless peripherals need udev rules

```nix
extraConfig = {
  hardware.desktop.enableLogitechSupport = true;
};
```

### Finding Quirks for Your Hardware

1. **Check nixos-hardware repository**: https://github.com/NixOS/nixos-hardware
   ```bash
   find /nix/store/*nixos-hardware*/lib -name "*.nix" | grep -i "yourmodel"
   ```

2. **Vendor documentation**:
   - System76: https://github.com/system76/firmware-open
   - Framework: https://github.com/NixOS/nixos-hardware/tree/master/framework
   - Dell: Check nixos-hardware for XPS, Latitude models

3. **NixOS Wiki**: https://nixos.wiki/wiki/Laptop

### Diagnosing Hardware Issues

```bash
# Check loaded kernel modules
lsmod

# Detect sensors
sudo sensors-detect

# Check hardware detection
lspci -v          # PCI devices
lsusb -v          # USB devices
dmesg | grep -i error  # Kernel errors
```

### Testing Quirks Temporarily

```bash
# Load a module temporarily (test before adding to config)
sudo modprobe module-name

# Blacklist a module temporarily
sudo rmmod problematic-module

# Test kernel parameter at boot (GRUB menu) before making permanent
```

### When NOT to Add Quirks

**Don't add quirks for**:
- Things that work automatically (NixOS detects most hardware)
- Generic features (CPU/GPU type handled by axios hardware.cpu/hardware.gpu)
- Features provided by axios modules (desktop, laptop, graphics modules)

**Only add quirks for**:
- Vendor-specific hardware needing special configuration
- Model-specific workarounds for known issues
- Peripherals requiring special drivers or udev rules

## Getting Help

If issues persist after trying all solutions:

1. Check axios repository issues: https://github.com/kcalvelli/axios/issues
2. Document your error with:
   - Full error message
   - Output of `nix --version`
   - Output of `cat flake.lock | jq '.nodes | keys'`
   - Recent changes to your configuration

3. Consider rollback to last working generation:
   ```bash
   sudo nixos-rebuild switch --rollback
   ```
