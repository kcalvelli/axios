# axiOS System Module Analysis - Personal Configuration Audit

**Analysis Date:** 2025-12-12
**Reviewed By:** Claude Code
**Constitution Reference:** ADR-002 (No Regional Defaults)

## Executive Summary

The system module has been analyzed for personal configuration remnants per the constitution's requirement that "this is a library/framework, NOT a personal configuration." The analysis found **3 medium-severity issues** and **2 low-severity items** that should be addressed to fully comply with the library philosophy.

**Overall Assessment:** MOSTLY COMPLIANT with minor issues

---

## Critical Findings (Severity: High)

**NONE FOUND** - No critical violations of the library philosophy.

---

## Medium Severity Issues

### 1. Hardcoded Bluetooth Auto-Power Behavior
**File:** `/home/keith/Projects/axios/modules/system/bluetooth.nix:4`
**Issue:** Bluetooth is configured to automatically power on at boot without user configurability.

```nix
hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;  # <- HARDCODED PERSONAL PREFERENCE
};
```

**Severity:** MEDIUM
**Rationale:**
- Some users may want Bluetooth off by default for privacy/battery reasons (laptops)
- Desktop users might want it on; laptop users might not
- This is a personal preference being imposed on all axiOS users

**Recommendation:**
```nix
# Suggested fix
options.axios.system.bluetooth = {
  enable = lib.mkEnableOption "Bluetooth support";
  powerOnBoot = lib.mkOption {
    type = lib.types.bool;
    default = false;  # Conservative default
    description = "Automatically power on Bluetooth at boot";
  };
};

config = lib.mkIf cfg.bluetooth.enable {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = cfg.bluetooth.powerOnBoot;
  };
};
```

---

### 2. Hardcoded Memory/Swap Configuration
**File:** `/home/keith/Projects/axios/modules/system/boot.nix:53, 86-89`
**Issue:** Swap and memory management settings are tuned for a specific use case without configurability.

```nix
# Line 53: Hardcoded swappiness
"vm.swappiness" = 10; # Prefer RAM over swap for better dev performance

# Lines 86-89: Hardcoded zram configuration
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 25;  # <- Fixed at 25% for all systems
};
```

**Severity:** MEDIUM
**Rationale:**
- `swappiness = 10` is optimized for "dev performance" (personal use case)
- 25% zram may be inappropriate for different memory sizes:
  - 8GB system: 2GB zram (reasonable)
  - 64GB system: 16GB zram (potentially excessive)
- Different users have different workloads (gaming, servers, development)

**Recommendation:**
```nix
options.axios.system.memory = {
  swappiness = lib.mkOption {
    type = lib.types.int;
    default = 60;  # Linux kernel default
    description = "VM swappiness value (0-100)";
  };

  zram = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable zram swap";
    };

    memoryPercent = lib.mkOption {
      type = lib.types.int;
      default = 25;
      description = "Percentage of RAM to use for zram";
    };
  };
};
```

---

### 3. Hardcoded Network Tuning for Desktop/Development Workload
**File:** `/home/keith/Projects/axios/modules/system/boot.nix:35-56`
**Issue:** Network kernel parameters are tuned specifically for "desktop/development" workloads.

```nix
# Network & kernel tunables optimized for desktop/development
boot.kernel.sysctl = {
  # BBR congestion control (modern, efficient)
  "net.core.default_qdisc" = "fq";
  "net.ipv4.tcp_congestion_control" = "bbr";

  # Desktop-appropriate network buffers
  "net.core.rmem_max" = 1048576; # 1MB
  # ... more hardcoded values

  # Development workload optimizations
  "fs.inotify.max_user_watches" = 524288; # For IDEs and dev tools
  "vm.swappiness" = 10; # Prefer RAM over swap for better dev performance
};
```

**Severity:** MEDIUM
**Rationale:**
- Comment explicitly says "optimized for desktop/development"
- These settings may not be appropriate for:
  - Server workloads (would want different TCP tuning)
  - Laptop battery optimization (different priorities)
  - Gaming-focused systems (different performance priorities)
- BBR congestion control is a specific algorithmic choice
- Buffer sizes are hardcoded for a specific use case

**Recommendation:**
- Extract network tuning to a separate optional module (e.g., `modules/system/network-tuning.nix`)
- Make it opt-in with profiles: `axios.system.networkProfile = "desktop" | "server" | "minimal"`
- Or remove entirely and let users configure sysctl via `extraConfig`

---

## Low Severity Issues

### 4. Default Locale Set to en_US.UTF-8
**File:** `/home/keith/Projects/axios/modules/system/locale.nix:19`
**Issue:** Locale defaults to `en_US.UTF-8` rather than requiring user to set it.

```nix
locale = lib.mkOption {
  type = lib.types.str;
  default = "en_US.UTF-8";  # <- US-centric default
  description = ''
    Default system locale.
    UTF-8 locales are recommended for compatibility.
  '';
};
```

**Severity:** LOW (Borderline acceptable)
**Rationale:**
- Constitution ADR-002 states "NO regional defaults" and "users MUST set timezone"
- However, `en_US.UTF-8` is widely considered the "neutral" default in Linux
- Unlike timezone, there's a strong technical reason (UTF-8 compatibility)
- Constitution explicitly allows this: "axios.system.locale - Defaults to en_US.UTF-8 but configurable"

**Recommendation:**
- **KEEP AS-IS** - This is acceptable per constitution.md
- en_US.UTF-8 is the de facto standard for internationalized systems
- Users who need different locales can easily override
- Optional: Add assertion warning if locale != UTF-8 variant

---

### 5. Initial Password "changeme"
**File:** `/home/keith/Projects/axios/modules/users.nix:166`
**Issue:** New users get initial password "changeme" by default.

```nix
users.users.${userCfg.name} = {
  isNormalUser = lib.mkDefault true;
  description = lib.mkDefault userCfg.fullName;
  initialPassword = lib.mkDefault "changeme";  # <- Hardcoded password
  extraGroups = lib.mkDefault cfg.defaultExtraGroups;
};
```

**Severity:** LOW
**Rationale:**
- Initial passwords are a necessary evil for NixOS declarative user management
- This is wrapped in `lib.mkDefault` so it can be overridden
- Alternative would be no password (locked account) or requiring user to set it
- Security concern: predictable default password

**Recommendation:**
- **Option 1:** Change to `initialHashedPassword = null` (locked account, requires manual `passwd` or SSH key)
- **Option 2:** Keep but add loud documentation warning
- **Option 3:** Generate random password and display it during first boot (complex)
- **Preferred:** Option 1 - safer default, users must explicitly set password

---

## Positive Findings (Constitution Compliance)

### Timezone Configuration - COMPLIANT
**File:** `/home/keith/Projects/axios/modules/system/locale.nix:7-15, 30-35`

```nix
timeZone = lib.mkOption {
  type = lib.types.str;
  description = ''
    System timezone (e.g., "America/New_York", "Europe/London", "Asia/Tokyo").
    This is a required setting.
  '';
  example = "America/New_York";
};

config = {
  assertions = [
    {
      assertion = cfg.timeZone != "";
      message = "axios.system.timeZone must be set in your host configuration";
    }
  ];
};
```

**Status:** EXCELLENT - Fully compliant with ADR-002
- NO default timezone
- Assertion prevents users from skipping configuration
- Examples use multiple regions (not just US-centric)

---

### No Hardcoded Keyboard Layouts - COMPLIANT
**Search:** `xkb|keyboard|layout|console.keyMap|services.xserver.xkb`
**Result:** No keyboard layout configuration found in system module

**Status:** COMPLIANT
- axiOS doesn't impose keyboard layout preferences
- Users configure via their own `extraConfig` or desktop environment

---

### No Personal User Accounts - COMPLIANT
**Files:** All system modules
**Result:** No hardcoded usernames, email addresses, or personal identifiers

**Status:** COMPLIANT
- Uses `axios.user.name` variable for dynamic user creation
- No remnants like "keith", "calvelli", or personal emails
- Example values use generic placeholders ("user@example.com")

---

## Files Analyzed

### System Module Files
1. `/home/keith/Projects/axios/modules/system/default.nix` - Core system configuration
2. `/home/keith/Projects/axios/modules/system/locale.nix` - Timezone/locale settings
3. `/home/keith/Projects/axios/modules/system/boot.nix` - Boot and kernel configuration
4. `/home/keith/Projects/axios/modules/system/memory.nix` - OOM daemon configuration
5. `/home/keith/Projects/axios/modules/system/bluetooth.nix` - Bluetooth settings
6. `/home/keith/Projects/axios/modules/system/sound.nix` - Audio configuration
7. `/home/keith/Projects/axios/modules/system/printing.nix` - Print services
8. `/home/keith/Projects/axios/modules/system/nix.nix` - Nix daemon settings

### User Management
9. `/home/keith/Projects/axios/modules/users.nix` - User account management

---

## Recommendations Summary

### High Priority (Should Fix)
1. **Make Bluetooth power-on configurable** (bluetooth.nix)
2. **Make swap/zram settings configurable** (boot.nix)
3. **Extract or make network tuning opt-in** (boot.nix)

### Medium Priority (Consider)
4. **Change initial password to null** (locked account) for better security (users.nix)

### Low Priority (Optional)
5. **Keep en_US.UTF-8 locale default** - This is acceptable per constitution

---

## Conclusion

The axiOS system module is **largely compliant** with the library philosophy stated in constitution.md. The most critical requirement (no timezone defaults) is properly enforced with assertions.

However, there are **3 medium-severity violations** where personal preferences or specific use-case optimizations have been hardcoded:
- Bluetooth auto-power
- Memory/swap tuning for development workloads
- Network tuning for desktop/development scenarios

These should be made configurable with sensible defaults to truly serve as a library framework rather than an opinionated personal configuration.

**Compliance Score: 7.5/10**
- Excellent: Timezone, keyboard, locale handling
- Good: No personal identifiers, clean user management
- Needs Work: Bluetooth, memory, network tuning configurability
