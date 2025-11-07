# Upgrading Axios

Quick guide for updating your Axios-based NixOS configuration to the latest version.

Axios uses [Calendar Versioning (CalVer)](https://calver.org/) with YYYY-MM-DD format.

## TL;DR - Latest Version

**Current Version**: 2025-11-04 (Unreleased)
**Breaking Changes**: None
**Action Required**: None - just update and rebuild

```bash
# Update axios
cd ~/my-nixos-config
nix flake lock --update-input axios

# Rebuild
sudo nixos-rebuild switch --flake .#HOSTNAME
```

---

## Standard Upgrade Process

### 1. Check What's New

Before upgrading, check for breaking changes:
- **[GitHub Releases](https://github.com/kcalvelli/axios/releases)** - Release notes and changelogs

### 2. Update Axios Input

```bash
cd ~/my-nixos-config
nix flake lock --update-input axios
```

### 3. Review the Lock File Changes

```bash
git diff flake.lock
```

Look for the axios input changes to confirm the new version.

### 4. Test Build (Recommended)

Test without actually switching:

```bash
# Dry run - shows what would change
sudo nixos-rebuild dry-build --flake .#HOSTNAME

# Build but don't activate
sudo nixos-rebuild build --flake .#HOSTNAME
```

### 5. Apply Update

```bash
sudo nixos-rebuild switch --flake .#HOSTNAME
```

### 6. Verify System

After rebuilding:
- Check that your desktop environment loads
- Verify critical services are running
- Test any custom configurations

```bash
# Check service status
systemctl status display-manager
systemctl --failed

# Check home-manager activation
systemctl --user status
```

---

## Rollback if Needed

If something breaks, rollback to previous generation:

```bash
# List available generations
sudo nixos-rebuild list-generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB menu
# (available at boot time)
```

---

## Version-Specific Upgrade Notes

### Upgrading to 2025-11-04

**Breaking Changes**: None

**What Changed**:
- Internal refactoring for home profiles (no config changes needed)
- Improved Tailscale/Caddy module independence (no config changes needed)

**Steps**:
1. Standard upgrade process above
2. No config modifications required
3. Everything should work identically

---

## Upgrade Checklist

Use this checklist when upgrading:

- [ ] Check [GitHub Releases](https://github.com/kcalvelli/axios/releases) for changes
- [ ] Backup important data (optional but recommended)
- [ ] Update flake.lock: `nix flake lock --update-input axios`
- [ ] Review lock file changes: `git diff flake.lock`
- [ ] Test build: `sudo nixos-rebuild dry-build --flake .#HOSTNAME`
- [ ] Apply update: `sudo nixos-rebuild switch --flake .#HOSTNAME`
- [ ] Verify system functionality
- [ ] Commit changes: `git add flake.lock && git commit -m "Update axios to YYYY-MM-DD"`

---

## Troubleshooting Upgrades

### Build Fails After Update

1. **Check error message** - often indicates missing config
2. **Review release notes** - check for required changes
3. **Search issues** - [GitHub Issues](https://github.com/kcalvelli/axios/issues)
4. **Rollback** - use `--rollback` flag to revert

### New Module Options Required

Some updates may add required options:

```nix
# If you see: "The option `foo.bar` is used but not defined"
# Add the required option to your config:
extraConfig = {
  foo.bar = "value";
};
```

### Evaluation Errors

If you see evaluation errors:

```bash
# Try evaluating to see detailed error
nix eval .#nixosConfigurations.HOSTNAME.config.system.build.toplevel --show-trace
```

### Cache Issues

If downloads are slow or failing:

```bash
# Clear nix cache
nix-collect-garbage

# Update all inputs
nix flake update
```

---

## Staying Updated

### Watch Releases

- Star the [axios repository](https://github.com/kcalvelli/axios)
- Watch releases for notifications
- Review changelog before major upgrades

### Update Frequency

Recommended update schedule:
- **Security updates**: As soon as available
- **Feature updates**: Monthly or as needed
- **Major versions**: When you need new features (test in VM first)

### Pinning Versions

If you need stability, pin to specific commits:

```nix
# flake.nix
inputs.axios.url = "github:kcalvelli/axios/COMMIT_HASH";
```

Or pin to tags/branches:

```nix
# Pin to specific version tag (using CalVer date)
inputs.axios.url = "github:kcalvelli/axios/2024-12-15";

# Pin to stable branch (if available)
inputs.axios.url = "github:kcalvelli/axios/stable";
```

---

## Getting Help

If you encounter issues:

1. **Check documentation**: [docs/](../docs/)
2. **Search issues**: [GitHub Issues](https://github.com/kcalvelli/axios/issues)
3. **Ask community**: [NixOS Discourse](https://discourse.nixos.org/)
4. **Report bugs**: [New Issue](https://github.com/kcalvelli/axios/issues/new)

When reporting upgrade issues, include:
- Version you're upgrading from and to
- Your flake.nix configuration
- Full error message
- Output of `nix flake metadata`

---

**Last Updated**: November 2025
