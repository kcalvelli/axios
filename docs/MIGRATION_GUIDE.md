# Axios Migration Guide

This guide documents breaking changes and required migrations between Axios versions.

Axios uses [Calendar Versioning (CalVer)](https://calver.org/) with YYYY-MM-DD format.

## Table of Contents

- [2025-11-04 - Architectural Improvements](#2025-11-04---architectural-improvements)

---

## 2025-11-04 - Architectural Improvements

### Summary

Internal architectural improvements to reduce code duplication and improve module independence. **No action required from users** - all changes are backwards compatible.

### Breaking Changes

**None** - This release has no breaking changes.

### What Changed Internally

#### 1. Home Profile Refactoring
**What happened**: Created shared base module to eliminate code duplication between workstation and laptop profiles.

**Impact on your config**: None - external API unchanged
- `axios.homeModules.workstation` - works exactly as before
- `axios.homeModules.laptop` - works exactly as before

**Benefits you get automatically**:
- More consistent package versions between profiles
- Future package additions will be available in both profiles immediately

#### 2. Tailscale/Caddy Dependency Decoupling
**What happened**: Moved Tailscale-Caddy integration from networking module to services module.

**Impact on your config**: None - modules work identically

**Benefits you get automatically**:
- Tailscale now works without requiring services module
- Caddy integration still automatic when both modules enabled
- Clearer module independence

**Before** (still works):
```nix
axios.lib.mkSystem {
  modules.networking = true;  # Includes Tailscale
  modules.services = true;     # Includes Caddy
}
# Result: Both work together automatically
```

**After** (same result):
```nix
axios.lib.mkSystem {
  modules.networking = true;  # Includes Tailscale - now works standalone too
  modules.services = true;     # Includes Caddy - integrates with Tailscale automatically
}
# Result: Identical behavior, better module independence
```

**New use case enabled**:
```nix
# Tailscale without Caddy now works cleanly
axios.lib.mkSystem {
  modules.networking = true;  # Tailscale works independently
  modules.services = false;    # No Caddy needed
}
```

### Testing Your Configuration

Your existing configuration should work without any modifications. To verify:

```bash
# Update your axios input
cd ~/my-nixos-config
nix flake lock --update-input axios

# Test build (dry-run, doesn't rebuild)
sudo nixos-rebuild dry-build --flake .#HOSTNAME

# If successful, rebuild
sudo nixos-rebuild switch --flake .#HOSTNAME
```

### No Changes Required

✅ **Module names** - unchanged
✅ **Module options** - unchanged
✅ **Home profiles** - unchanged
✅ **mkSystem API** - unchanged
✅ **Example configurations** - still valid

### Questions?

If you encounter any issues after updating, please [open an issue](https://github.com/kcalvelli/axios/issues) with:
- Your flake.nix configuration
- Output of `nix flake metadata` in your config directory
- Any error messages

---

## Previous Versions

### 2024-XX-XX - Initial Release

No migration needed - initial version.

---

**Last Updated**: November 2025
