# Hardware Quirks Guide

This guide shows how to configure hardware-specific quirks in your downstream configuration. axiOS is intentionally vendor-agnostic - all hardware-specific configuration belongs in your personal host configs, not in the framework.

## Philosophy

**axiOS provides:**
- Generic hardware modules (desktop, laptop, common)
- CPU-type awareness (AMD/Intel kernel modules, microcode)
- GPU-type awareness (AMD/Nvidia/Intel drivers)
- Form factor modules (desktop vs laptop)

**Your downstream config handles:**
- Vendor-specific hardware quirks
- Model-specific workarounds
- Peripheral-specific configuration
- Motherboard sensors and tuning

## Example: MSI Motherboard Sensors (Desktop)

**System:** AMD desktop with MSI motherboard
**Issue:** Fan and temperature sensors require specific kernel module
**Location:** `edge.nix` (downstream config)

```nix
extraConfig = {
  # MSI motherboard sensor support (nct6775 for fan/temp monitoring)
  boot.kernelModules = [ "nct6775" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ]; # Required for nct6775 on MSI boards
};
```

**Why this works:**
- `nct6775`: Super I/O sensor chip module for many MSI boards
- `acpi_enforce_resources=lax`: Allows kernel to access ACPI-reserved regions for sensor data

**Adaptation for your hardware:**
1. Find your motherboard's sensor chip (check `sensors-detect` or lm-sensors documentation)
2. Add the appropriate kernel module
3. Add any required kernel parameters for your specific chip

## Example: System76 Pangolin 12 (Laptop)

**System:** System76 Pangolin 12 laptop (AMD CPU, AMD GPU)
**Issues:** Multiple hardware-specific quirks
**Location:** `pangolin.nix` (downstream config)

```nix
extraConfig = {
  # System76 Pangolin 12 hardware integration
  hardware.system76 = {
    firmware-daemon.enable = true;  # Firmware updates
    power-daemon.enable = true;     # Power management
  };

  # Pangolin 12 specific hardware quirks
  boot = {
    # Load System76 ACPI module for keyboard backlight control
    kernelModules = [ "system76_acpi" ];

    # Disable PS/2 fallback touchpad (Pangolin 12 uses I2C touchpad)
    blacklistedKernelModules = [ "psmouse" ];

    # MediaTek MT7921/MT7922 Wi-Fi quirk for Pangolin 12
    extraModprobeConfig = ''
      options mt7921_common disable_clc=1
    '';
  };
};
```

**Why each quirk exists:**
1. **system76_acpi module**: Enables keyboard backlight control via System76 ACPI interface
2. **psmouse blacklist**: Pangolin 12's touchpad is I2C-based; PS/2 fallback causes conflicts
3. **mt7921_common disable_clc=1**: Disables calibration for MediaTek Wi-Fi, fixes connection stability

**Adaptation for your laptop:**
- Other System76 models: May need different quirks (check System76 docs)
- Dell/Lenovo/HP laptops: Check nixos-hardware repository for model-specific quirks
- Generic laptops: Usually don't need vendor-specific quirks

## Example: Logitech Wireless Peripherals (Optional)

**System:** Desktop with Logitech Unifying receiver
**Issue:** Wireless peripherals need udev rules and software support
**Location:** `edge.nix` (downstream config)

```nix
extraConfig = {
  # Enable Logitech peripheral support (Unifying receiver, etc.)
  hardware.desktop.enableLogitechSupport = true;
};
```

**What this enables:**
- `hardware.logitech.wireless`: Logitech Unifying receiver support
- Udev rules for hidraw access via `plugdev` group
- Graphical configuration tool (Solaar)

**Adaptation for your peripherals:**
- This is now **opt-in** in axiOS (defaults to false)
- Only enable if you have Logitech wireless peripherals
- For other brands, add appropriate udev rules in your extraConfig

## Common Hardware Quirk Patterns

### Pattern 1: Kernel Module Loading

```nix
boot.kernelModules = [
  "module-name"  # Replace with your specific module
];
```

**When to use:**
- Hardware requires a module not loaded automatically
- Sensors, special controllers, vendor-specific features

### Pattern 2: Kernel Module Blacklisting

```nix
boot.blacklistedKernelModules = [
  "problematic-module"  # Module that conflicts with correct driver
];
```

**When to use:**
- Kernel loads wrong driver for your hardware
- Fallback drivers cause conflicts with correct drivers

### Pattern 3: Module Parameters/Options

```nix
boot.extraModprobeConfig = ''
  options module-name parameter=value
'';
```

**When to use:**
- Hardware works but needs specific tuning
- Wi-Fi/Bluetooth quirks, GPU options, power management

### Pattern 4: Kernel Parameters

```nix
boot.kernelParams = [
  "parameter=value"  # Kernel command-line parameter
];
```

**When to use:**
- ACPI workarounds
- GPU-specific boot options
- Memory/CPU tuning

## Finding Quirks for Your Hardware

### Step 1: Check Official Sources

1. **nixos-hardware repository**: https://github.com/NixOS/nixos-hardware
   ```bash
   # Search for your laptop model
   find /nix/store/*nixos-hardware*/lib -name "*.nix" | grep -i "yourmodel"
   ```

2. **Vendor documentation**:
   - System76: https://github.com/system76/firmware-open
   - Framework: https://github.com/NixOS/nixos-hardware/tree/master/framework
   - Dell: Check nixos-hardware for XPS, Latitude models

3. **NixOS Wiki**: https://nixos.wiki/wiki/Laptop

### Step 2: Diagnose Issues

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

### Step 3: Test Quirks Temporarily

```bash
# Load a module temporarily (test before adding to config)
sudo modprobe module-name

# Blacklist a module temporarily
sudo rmmod problematic-module

# Test kernel parameter
# Add to GRUB menu at boot, test, then add to config if it works
```

### Step 4: Make Permanent

Once you've verified a quirk works, add it to your `extraConfig` section as shown in the examples above.

## When NOT to Add Quirks

**Don't add quirks for:**
- Things that work automatically (NixOS usually detects hardware correctly)
- Generic features (CPU/GPU type handled by axiOS hardware.cpu/hardware.gpu)
- Features provided by axiOS modules (desktop, laptop, graphics modules)

**Only add quirks for:**
- Vendor-specific hardware that needs special configuration
- Model-specific workarounds for known issues
- Peripherals requiring special drivers or rules

## Getting Help

If you're unsure what quirks your hardware needs:

1. **Check if it works first**: Most modern hardware works out-of-the-box in NixOS
2. **Search nixos-hardware**: Your exact model may already have a profile
3. **Check NixOS Discourse**: https://discourse.nixos.org
4. **Ask in NixOS Matrix/Discord**: Describe your hardware and what's not working

## Contributing Back

If you develop a quirk configuration that:
- Fixes a common hardware issue
- Works for multiple users with the same hardware
- Is well-tested and documented

Consider:
1. Submit to nixos-hardware repository (for hardware profiles)
2. Document in NixOS Wiki
3. Share in NixOS community forums

**Do NOT submit to axiOS** - the framework is intentionally vendor-agnostic. Quirks belong in downstream configs.

---

## Summary

- axiOS provides **generic** hardware support (form factor, CPU type, GPU type)
- **You** provide **specific** hardware quirks in your downstream config
- Use `extraConfig` section in your host config for all vendor/model-specific tweaks
- Test quirks temporarily before making them permanent
- Only add quirks for things that actually don't work without them

**Example structure in your config:**

```nix
extraConfig = {
  # Required: Set your timezone
  axios.system.timeZone = "America/New_York";

  # Optional: Hardware-specific quirks
  boot.kernelModules = [ "your-vendor-module" ];
  boot.blacklistedKernelModules = [ "conflicting-module" ];
  hardware.yourVendor = { enable = true; };

  # Optional: Additional services
  # services.yourService = { enable = true; };
};
```
