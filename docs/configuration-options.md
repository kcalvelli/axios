# Configuration Options

This document lists all configurable options in axiOS with their default values. All options can be overridden in your host configuration's `extraConfig` section.

## System Options

### Timezone (Required)

```nix
extraConfig = {
  axios.system.timeZone = "America/New_York";  # Required - no default
};
```

**Required**: ✅ Yes
**Default**: None (must be set by user)
**Type**: String (IANA timezone)
**Description**: System timezone. Must be explicitly set - axiOS has no regional defaults.

### Bluetooth

```nix
extraConfig = {
  axios.system.bluetooth.powerOnBoot = true;
};
```

**Default**: `true`
**Type**: Boolean
**Description**: Automatically power on Bluetooth adapters at boot. Set to `false` if you don't use Bluetooth or prefer manual control.

### Performance Tuning

#### Swappiness

```nix
extraConfig = {
  axios.system.performance.swappiness = 10;
};
```

**Default**: `10`
**Type**: Integer (0-100)
**Description**: VM swappiness parameter. Lower values prefer RAM over swap. Default optimized for development workloads with ample RAM.
- `0` = Avoid swap except under memory pressure
- `10` = Minimal swapping (development workstations)
- `60` = Default Linux value (balanced)
- `100` = Aggressive swapping (low-RAM systems)

#### Zram Swap Percentage

```nix
extraConfig = {
  axios.system.performance.zramPercent = 25;
};
```

**Default**: `25` (25% of RAM)
**Type**: Integer (percentage)
**Description**: Percentage of RAM to allocate for compressed zram swap. Provides fast swap without disk I/O.
- `25%` = Good balance for most systems
- `50%` = More compressed swap (low-RAM systems)
- `10%` = Minimal swap (high-RAM systems)

#### Network Optimizations

```nix
extraConfig = {
  axios.system.performance.enableNetworkOptimizations = true;
};
```

**Default**: `true`
**Type**: Boolean
**Description**: Enable BBR congestion control and optimized network buffers. Improves network performance for desktop/development use. Disable for servers or specialized network configurations.

**When enabled, applies:**
- BBR congestion control (modern, efficient)
- 1MB network buffer sizes
- TCP Fast Open
- Optimized TCP read/write memory

## Hardware Options

### Desktop Hardware

#### CPU Governor (Desktop)

```nix
extraConfig = {
  hardware.desktop.cpuGovernor = "powersave";
};
```

**Default**: `"powersave"`
**Type**: String
**Description**: CPU frequency governor for desktop systems. Modern AMD (amd-pstate-epp) and Intel drivers provide intelligent frequency scaling with powersave governor.

**Common values:**
- `"powersave"` = Intelligent scaling, lower power (recommended)
- `"performance"` = Maximum frequency always
- `"ondemand"` = Dynamic scaling based on load
- `"schedutil"` = Scheduler-based scaling

#### Logitech Peripheral Support

```nix
extraConfig = {
  hardware.desktop.enableLogitechSupport = false;
};
```

**Default**: `false`
**Type**: Boolean
**Description**: Enable Logitech Unifying receiver support and udev rules. Only enable if you use Logitech wireless peripherals.

### Laptop Hardware

#### CPU Governor (Laptop)

```nix
extraConfig = {
  hardware.laptop.cpuGovernor = "powersave";
};
```

**Default**: `"powersave"`
**Type**: String
**Description**: CPU frequency governor for laptop systems. Default optimized for battery life.

**Common values:**
- `"powersave"` = Better battery life (recommended for laptops)
- `"performance"` = Maximum performance, worse battery
- `"ondemand"` = Dynamic scaling
- `"schedutil"` = Scheduler-based scaling

### GPU Configuration

```nix
extraConfig = {
  axios.hardware.gpuType = "amd";  # Set automatically from hardware.gpu
  axios.hardware.isLaptop = false; # Set automatically from hardware.isLaptop
};
```

**Note**: These are automatically set from your `hardware.gpu` and `hardware.isLaptop` fields. You typically don't need to override them in extraConfig.

#### GPU Recovery (AMD only)

```nix
extraConfig = {
  axios.hardware.enableGPURecovery = false;
};
```

**Default**: `false`
**Type**: Boolean
**GPU**: AMD only
**Description**: Enable automatic GPU hang recovery for AMD GPUs. Adds kernel parameter `amdgpu.gpu_recovery=1`. Only enable if experiencing GPU hangs or stability issues.

**Important**: This option only works when `gpuType` is `"amd"`. An assertion will fail the build if enabled with other GPU types.

### CPU Configuration

```nix
extraConfig = {
  axios.hardware.cpuType = "amd";  # Set automatically from hardware.cpu
};
```

**Note**: Automatically set from your `hardware.cpu` field. Controls CPU-specific kernel modules (kvm-amd vs kvm-intel) and microcode updates.

## Boot Options

### Secure Boot

```nix
extraConfig = {
  boot.lanzaboote.enableSecureBoot = false;
};
```

**Default**: `false`
**Type**: Boolean
**Description**: Enable Lanzaboote secure boot support. Should be enabled AFTER initial installation when secure boot keys are enrolled.

**Important**: Fresh installations should leave this `false` until secure boot keys are set up.

## Module-Specific Options

### Graphics Module

Set in `hardware` section of host config:

```nix
hardware = {
  gpu = "amd";     # Options: "amd", "nvidia", "intel"
  isLaptop = false;
};
```

For Nvidia-specific options:

```nix
extraConfig = {
  hardware.nvidia = {
    open = lib.mkDefault true;  # Use open-source driver for RTX 20-series+
    package = pkgs.linuxPackages_latest.nvidiaPackages.beta;  # Override driver version
    # PRIME options (auto-disabled on desktops)
    prime.offload.enable = false;
    prime.sync.enable = false;
  };
};
```

### Virtualization Module

```nix
virt = {
  libvirt.enable = true;
  containers.enable = true;  # Podman
};
```

### AI Module

```nix
extraConfig = {
  services.ai.local = {
    enable = true;
    models = [ "qwen3-coder:30b" ];  # Ollama models to preload
    rocmOverrideGfx = "10.3.0";      # For AMD GPUs (gfx version)
    gui = true;                       # LM Studio
    cli = true;                       # OpenCode
  };
};
```

### Crash Diagnostics

```nix
extraConfig = {
  hardware.crashDiagnostics = {
    enable = true;
    rebootOnPanic = 30;        # Auto-reboot after 30s on kernel panic
    treatOopsAsPanic = true;   # Treat kernel errors as panics
    enableCrashDump = false;   # kdump (uses RAM)
  };
};
```

## Examples

### High-Performance Desktop (64GB RAM, Fast CPU)

```nix
extraConfig = {
  axios.system.timeZone = "America/Los_Angeles";

  # Aggressive performance tuning
  axios.system.performance = {
    swappiness = 1;              # Almost never swap (lots of RAM)
    zramPercent = 10;            # Minimal compressed swap
    enableNetworkOptimizations = true;
  };

  # Maximum CPU performance
  hardware.desktop.cpuGovernor = "performance";
};
```

### Battery-Optimized Laptop

```nix
extraConfig = {
  axios.system.timeZone = "America/New_York";

  # Conservative performance tuning
  axios.system.performance = {
    swappiness = 60;             # Default swapping
    zramPercent = 50;            # More compressed swap
    enableNetworkOptimizations = false;  # Disable for battery
  };

  # Bluetooth off by default (save battery)
  axios.system.bluetooth.powerOnBoot = false;

  # Powersave CPU governor (default, shown for clarity)
  hardware.laptop.cpuGovernor = "powersave";
};
```

### Server Configuration

```nix
extraConfig = {
  axios.system.timeZone = "UTC";

  # Server-appropriate tuning
  axios.system.performance = {
    swappiness = 10;             # Prefer RAM
    zramPercent = 25;            # Standard swap
    enableNetworkOptimizations = false;  # Use server-specific tuning instead
  };

  # Disable Bluetooth (not needed on servers)
  axios.system.bluetooth.powerOnBoot = false;

  # Performance governor for consistent latency
  hardware.desktop.cpuGovernor = "performance";
};
```

## Fixed Defaults (Not Configurable)

Some settings are intentionally fixed in axiOS:

### Boot Configuration
- Latest kernel: `boot.kernelPackages = pkgs.linuxPackages_latest`
- Quiet boot with Plymouth splash screen
- systemd in initrd
- zstd compression for zram

### Development Optimizations
- `fs.inotify.max_user_watches = 524288` (for IDEs)
- `vm.dirty_ratio = 3` (SSD-optimized)
- `vm.dirty_background_ratio = 2`

### Desktop Services (when desktop module enabled)
- Weekly TRIM for SSDs
- irqbalance for multi-core systems
- power-profiles-daemon disabled (conflicts with manual governor)

If you need to override any of these, you can use `lib.mkForce` in your extraConfig:

```nix
extraConfig = {
  # Override a fixed default
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_6;
};
```

## Finding More Options

axiOS uses NixOS options under the hood. To find additional NixOS options you can configure:

1. **NixOS Options Search**: https://search.nixos.org/options
2. **Local search**: `man configuration.nix`
3. **Check module source**: All axiOS modules are in `modules/` directory

Any NixOS option can be set in `extraConfig` - the options listed in this document are specifically the ones axiOS exposes for common customization.

## See Also

- [Hardware Quirks Guide](hardware-quirks.md) - Vendor-specific hardware configuration
- [Module Architecture](.claude/project.md) - How modules are structured
- [Constitution](../spec-kit-baseline/constitution.md) - Design decisions and constraints
