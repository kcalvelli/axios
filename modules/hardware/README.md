# Hardware Module

Hardware-specific configurations for different system types.

## Purpose

Provides hardware configurations optimized for different form factors (desktop, laptop) with vendor-specific features enabled via nixos-hardware modules.

## Available Modules

### `common.nix` - Common Hardware
Base hardware configuration imported by both desktop and laptop modules.

**Features:**
- CPU microcode updates (AMD or Intel, based on `cpuType`)
- Enable all firmware

### `desktop.nix` - Desktop Hardware
Generic desktop workstation configuration.

**Auto-enabled for:**
- `hardware.vendor = "msi"`
- `formFactor = "desktop"` (with no specific vendor)

**Options:**
- `hardware.desktop.enable` - Enable desktop hardware config
- `hardware.desktop.cpuGovernor` - CPU frequency governor (default: `"powersave"`)
- `hardware.desktop.enableLogitechSupport` - Logitech Unifying receiver support (default: `false`)

**Features:**
- Standard kernel modules (kvm-amd/intel, nvme, xhci_pci, ahci, etc.)
- Desktop power management
- Desktop services (fstrim, irqbalance)
- Power profiles daemon disabled (not useful on desktops)

### `laptop.nix` - Laptop Hardware
Generic laptop configuration.

**Auto-enabled for:**
- `hardware.vendor = "system76"`
- `formFactor = "laptop"` (with no specific vendor)

**Options:**
- `hardware.laptop.enable` - Enable laptop hardware config
- `hardware.laptop.cpuGovernor` - CPU frequency governor (default: `"powersave"`)

**Features:**
- Standard kernel modules (kvm-amd/intel, nvme, xhci_pci)
- SSD TRIM service
- Power management optimized for battery life

### `crash-diagnostics.nix` - Crash Recovery
Automatic system recovery from kernel panics and freezes.

**Features:**
- Configurable reboot on kernel panic
- Kernel oops as panic option
- Optional crash dump (kdump)
- Hardware and runtime watchdog support

## Usage in Host Configuration

Hardware modules are automatically enabled based on vendor and form factor:

```nix
# MSI desktop - gets desktop hardware
{
  formFactor = "desktop";
  hardware.vendor = "msi";
}

# System76 laptop - gets laptop hardware
{
  formFactor = "laptop";
  hardware.vendor = "system76";
}

# Generic desktop - gets desktop hardware only
{
  formFactor = "desktop";
}

# Generic laptop - gets laptop hardware only
{
  formFactor = "laptop";
}
```

## Manual Control

If you need manual control, you can override in `extraConfig`:

```nix
extraConfig = {
  hardware.desktop = {
    cpuGovernor = "performance";         # Override CPU governor
    enableLogitechSupport = true;        # Enable Logitech peripherals
  };
};
```
