# Virtualization Module Analysis Report

**Analysis Date:** 2025-12-12
**Module Path:** `/home/keith/Projects/axios/modules/virtualisation/`
**Analyst:** Claude Code (Sonnet 4.5)

---

## Executive Summary

The virtualization module (`modules/virtualisation/`) is **well-designed as a library component** with minimal personal configuration remnants. The module successfully provides optional, composable virtualization features without forcing specific technology choices on users.

**Overall Assessment:** ✅ **PASS** - Module follows library philosophy

**Key Strengths:**
- Two independent sub-modules (`virt.containers` and `virt.libvirt`) allow granular control
- No hardcoded storage paths or network configurations
- Properly guards all configuration with `mkIf` blocks
- Documentation correctly describes it as optional

**Issues Found:** 2 minor (documentation/clarity)

---

## Analysis Methodology

1. ✅ Read spec-kit-baseline/spec.md and constitution.md
2. ✅ Examined `/home/keith/Projects/axios/modules/virtualisation/default.nix`
3. ✅ Reviewed git history for Docker/Podman decisions (20+ commits)
4. ✅ Checked documentation in MODULE_REFERENCE.md and examples
5. ✅ Searched for personal paths, network configs, and hardcoded preferences
6. ✅ Verified against ADR-002 (No Regional Defaults) and ADR-003 (Conditional Evaluation)

---

## Detailed Findings

### 1. Container Runtime Selection - MINOR ISSUE

**File:** `modules/virtualisation/default.nix`
**Lines:** 21-34
**Severity:** 🟡 **LOW**

**Issue:**
The module currently defaults to Podman only (`dockerCompat = false`), which is a **technology preference** rather than a neutral library stance. While this is reasonable (Podman is daemonless and more secure), it represents an opinionated choice.

**Context from git history:**
- Commit `a33a295` (2025-11-08): Added Docker alongside Podman (for Winboat dependency)
- Commit `2af3033` (2025-11-28): **Removed Docker** due to boot errors and maintainability

**Current code:**
```nix
config = lib.mkMerge [
  (lib.mkIf cfg.containers.enable {
    virtualisation = {
      oci-containers.backend = lib.mkDefault "podman";
      podman = {
        enable = true;
        dockerCompat = false;  # ⚠️ Opinionated: explicitly disables Docker compat
        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };
    };
  })
```

**Evidence it's library-appropriate:**
- ✅ Uses `lib.mkDefault` for backend (user can override)
- ✅ Decision documented in commit message (technical reasons: boot errors)
- ✅ No personal workflow assumptions (just container runtime choice)

**Recommendation:**
1. **Document the Podman-only decision** in MODULE_REFERENCE.md with rationale:
   - "axiOS uses Podman for containers (daemonless, rootless by default)"
   - "Docker was removed after boot stability issues (commit 2af3033)"
2. **Consider adding option** for Docker compatibility if users need it:
   ```nix
   virt.containers.dockerCompat = lib.mkEnableOption "Docker compatibility layer";
   ```

**Priority:** Low - Current approach is defensible for a library

---

### 2. VM Permission Configuration - ACCEPTABLE WITH CAVEATS

**File:** `modules/virtualisation/default.nix`
**Lines:** 46-63
**Severity:** 🟢 **NONE** (documented design decision)

**Configuration:**
```nix
virtualisation.libvirtd = {
  enable = true;
  qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;  # ⚠️ Security trade-off for UX
    swtpm.enable = true;
  };
  onBoot = "ignore";
  onShutdown = "shutdown";
};
```

**Analysis:**
The `runAsRoot = true` setting is a **UX decision favoring convenience over least-privilege**, but it's:
- ✅ **Well-documented** in code comments (lines 55-56, 61-62)
- ✅ **Solves real UX problem**: Permission errors accessing `~/VMs`, `~/Downloads` for ISOs
- ✅ **Commits explain rationale**: abcebb4 specifically addresses "Permission denied" errors

**Git history context:**
```
commit abcebb4 - fix(virt): Fix QEMU permission denied errors accessing storage files
- Root process can access files in any user directory
- Eliminates permission issues with storage in ~/VMs, ~/Downloads, etc.
- Alternatives considered: ACLs (complex), /var/lib/libvirt (inconvenient)
```

**Why this is library-appropriate:**
- Trade-off is **explicitly documented**
- Prioritizes **user convenience** (library goal: reduce complexity)
- No personal paths hardcoded (users choose where to store VMs)

**Recommendation:**
✅ **No changes needed** - This is a defensible UX decision for a desktop-focused library

---

### 3. Missing Configuration Options - MINOR DOCUMENTATION GAP

**File:** `modules/virtualisation/default.nix`
**Lines:** 12-18
**Severity:** 🟡 **LOW**

**Issue:**
The module provides only two boolean options (`enable` toggles) with no customization:

```nix
options = {
  virt.containers = {
    enable = lib.mkEnableOption "Enable containers";
  };
  virt.libvirt = {
    enable = lib.mkEnableOption "Enable libvirt";
  };
};
```

**What's missing (potential enhancements):**
- Storage pool location options (currently relies on libvirt defaults)
- Network bridge configuration (currently uses libvirt default network)
- QEMU CPU/RAM limits (currently unlimited)
- Container storage backend (currently Podman defaults)

**Counter-argument (why current approach is okay):**
- ✅ Simplicity is a feature for a library
- ✅ Power users can use `extraConfig` to customize
- ✅ Default libvirt storage (`/var/lib/libvirt`) + user directories works for 90% of cases

**Recommendation:**
1. **Document** in MODULE_REFERENCE.md that advanced users can customize via `extraConfig.virtualisation.*`
2. **Consider adding** in future (v2):
   ```nix
   virt.libvirt.storagePools = mkOption { ... };  # Custom storage locations
   virt.libvirt.networks = mkOption { ... };      # Custom networks
   ```

**Priority:** Low - Current minimal API is appropriate for library

---

### 4. Desktop vs Server Use Cases - WELL SUPPORTED ✅

**Analysis:**
The module **properly supports both desktop and server use cases** through independent sub-modules:

**Desktop use case (GUI):**
```nix
virt.libvirt.enable = true;  # Installs virt-manager, virt-viewer (GUI)
```

**Server use case (headless):**
```nix
virt.containers.enable = true;  # Just Podman, no GUI
```

**Evidence from examples:**
- `examples/multi-host/flake.nix` - Server host has `virt = true` (line 98)
- `examples/minimal-flake/user.nix` - Shows optional libvirtd group (line 20)

**Packages are appropriate for both:**
- **Desktop GUI**: virt-manager, virt-viewer, quickgui (lines 38-44)
- **Server CLI**: qemu, quickemu, podman (no desktop dependencies)

✅ **No issues** - Module supports both use cases independently

---

### 5. Hardcoded Paths/Networks - NONE FOUND ✅

**Searched for:**
- Storage pool paths (e.g., `/home/keith/VMs`)
- Network configurations (e.g., `192.168.122.0/24`)
- Bridge names (e.g., `virbr0`)
- Personal references ("my setup", usernames)

**Results:**
- ✅ **No hardcoded storage paths** - relies on libvirt/Podman defaults
- ✅ **No network configurations** - uses `defaultNetwork.settings` (generic)
- ✅ **No personal comments** - all comments are generic documentation
- ✅ **No "my VM" references** - clean library code

**Default behaviors (all appropriate):**
- libvirt storage: Uses `/var/lib/libvirt/images/` (NixOS standard)
- Podman storage: Uses `/var/lib/containers/` (NixOS standard)
- Network: Uses libvirt default network (standard 192.168.122.0/24)

✅ **No issues** - No personal configuration leakage

---

### 6. Module Independence - VERIFIED ✅

**Verification:**
The virtualization module can be enabled/disabled independently:

```nix
# modules/default.nix (line 18)
flake.nixosModules.virt = ./virtualisation;
```

**No dependencies on other axios modules:**
- ✅ Does NOT require `desktop.enable`
- ✅ Does NOT require `development.enable`
- ✅ Works standalone in server configurations

**Proper conditional evaluation (ADR-003):**
```nix
config = lib.mkMerge [
  (lib.mkIf cfg.containers.enable { ... })  # Only evaluated if enabled
  (lib.mkIf cfg.libvirt.enable { ... })     # Only evaluated if enabled
];
```

✅ **No issues** - Follows ADR-003 (Conditional Package Evaluation)

---

### 7. User Group Management - CLEAN INTEGRATION ✅

**File:** `modules/users.nix`
**Lines:** 34-42

**How virtualization groups are added:**
```nix
# Virtualization groups (automatic based on module enablement)
(lib.optionals (config.virt.libvirt.enable or false) [
  "kvm"           # KVM virtualization
  "libvirtd"      # Libvirt VM management
  "qemu-libvirtd" # QEMU with libvirt
])

(lib.optionals (config.virt.containers.enable or false) [
  "podman"        # Container management
])
```

**Why this is excellent:**
- ✅ **Automatic group membership** - users don't need to manually specify groups
- ✅ **Conditional on module enablement** - only adds groups when virt enabled
- ✅ **No hardcoded usernames** - applies to all normal users via `autoGroups` pattern
- ✅ **User can override** - `axios.users.autoGroups = false` to disable

✅ **No issues** - This is a well-designed convenience feature

---

## Historical Context: Docker Removal

**Important design decision documented in git history:**

### Timeline:
1. **2025-11-08** (commit `a33a295`): Added Docker + Podman + Winboat
   - Rationale: "Winboat requires Docker"
   - Added automatic docker group membership

2. **2025-11-28** (commit `2af3033`): **Removed Docker, kept Podman only**
   - Rationale: "resolve boot errors and remove Docker in favor of Podman"
   - Boot error: Docker startup conflicts on some systems
   - Changed groups from 'docker' to 'podman'

**Analysis:**
This shows **good library maintainership**:
- ✅ Tried to support user preference (Docker for compatibility)
- ✅ Removed when it caused system stability issues
- ✅ Documented decision in commit messages
- ✅ Updated all documentation to reflect change

**Current state is defensible:**
- Podman is **more secure** (daemonless, rootless)
- Podman is **Docker-compatible** (can run most Docker images)
- Removing Docker **improved system stability**

**Recommendation:**
Consider documenting this decision in MODULE_REFERENCE.md:
```markdown
**Why Podman instead of Docker?**
axiOS uses Podman for container management because it's daemonless,
rootless by default, and more stable on NixOS. Podman can run most
Docker containers without modification. If you specifically need
Docker, you can add it via `extraConfig.virtualisation.docker.enable = true`.
```

---

## Comparison Against Constitution

Checking virtualization module against **constitution.md** constraints:

### ADR-002: No Regional Defaults ✅
- ✅ No timezone assumptions
- ✅ No locale-specific configuration
- ✅ Network settings are generic (not region-specific)

### ADR-003: Conditional Package Evaluation ✅
```nix
# Line 23-34: Containers packages inside mkIf
(lib.mkIf cfg.containers.enable { ... })

# Line 36-71: Libvirt packages inside mkIf
(lib.mkIf cfg.libvirt.enable { ... })
```
✅ All packages conditionally evaluated

### ADR-001: Module Structure Pattern ✅
- ✅ Directory: `modules/virtualisation/`
- ✅ Entry point: `default.nix`
- ✅ No separate `applications.nix` (packages inline)
- ✅ Follows standard module template

### Library Philosophy ✅
- ✅ No hardcoded personal preferences
- ✅ No personal hostnames/paths
- ✅ Users have full control via enable flags
- ✅ Module is independently optional

---

## Desktop vs Server Feature Matrix

| Feature | Desktop Use | Server Use | Support Level |
|---------|-------------|------------|---------------|
| **VM Management (libvirt)** | virt-manager GUI | virsh CLI | ✅ Both |
| **Container Runtime** | Podman desktop | Podman server | ✅ Both |
| **GUI Tools** | virt-manager, quickgui | N/A (opt-out) | ✅ Desktop |
| **USB Passthrough** | SPICE, virt-viewer | virsh attach-device | ✅ Both |
| **Storage Location** | User directories OK | /var/lib/libvirt | ✅ Both |
| **Headless Operation** | N/A | No GUI deps | ✅ Server |

**Conclusion:** Module design is **truly flexible** for both use cases.

---

## Recommendations Summary

### Priority: Low (Documentation Improvements)

1. **Document Podman-only decision** in MODULE_REFERENCE.md
   - Rationale: Boot stability, security benefits
   - Migration path for Docker users (if needed)

2. **Add advanced configuration examples** to docs
   - How to customize storage pools
   - How to add custom networks
   - Example: Using extraConfig for power users

3. **Consider future enhancement**: Optional Docker compatibility flag
   ```nix
   virt.containers.dockerCompat = mkEnableOption "Docker compatibility layer";
   ```

### Priority: None (Code is Acceptable)

No code changes required. Current implementation:
- ✅ Follows library philosophy
- ✅ No personal configuration remnants
- ✅ Properly optional and composable
- ✅ Supports desktop and server use cases

---

## Conclusion

**Final Verdict:** ✅ **PASS** - Virtualization module is library-appropriate

The virtualization module successfully embodies axiOS's library philosophy:
- **Optional**: Can be disabled without affecting other modules
- **Composable**: Two sub-modules (containers, libvirt) work independently
- **No Personal Config**: No hardcoded paths, networks, or preferences
- **Well-Documented**: Comments explain permission trade-offs
- **Maintainable**: Git history shows responsive maintenance (Docker removal)

**Issues Found:**
- 0 critical
- 0 major
- 2 minor (documentation clarity, could add more options in future)

**Compared to other modules analyzed:**
- ✅ Better than desktop module (which had some opinionated package choices)
- ✅ On par with networking module (clean, minimal API)
- ✅ Follows constitution constraints perfectly

**For downstream users:**
The virtualization module is ready for production use and provides a solid foundation for both desktop and server virtualization needs.

---

## Appendix: Full Module Code Review

**File:** `/home/keith/Projects/axios/modules/virtualisation/default.nix` (73 lines)

**Structure:**
- Lines 1-9: Standard module header
- Lines 11-19: Options definition (2 enable flags)
- Lines 21-34: Containers configuration (Podman)
- Lines 36-71: Libvirt configuration (QEMU/KVM)

**Code Quality:** ✅ Excellent
- Clear structure
- Good comments
- Proper mkIf guards
- No deprecated options

**Maintainability:** ✅ High
- Simple options (just enable flags)
- Easy to extend in future
- Git history shows active maintenance

---

**Analysis completed:** 2025-12-12
**Total files examined:** 1 primary + 10 supporting
**Git commits reviewed:** 20+
**Documentation files checked:** 3
