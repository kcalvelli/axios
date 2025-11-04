# Architectural Improvements Summary

**Date**: November 2025
**Version**: 2025-11-04 (Unreleased)
**Breaking Changes**: None

Note: Axios uses [Calendar Versioning (CalVer)](https://calver.org/) with YYYY-MM-DD format.

---

## Executive Summary

Internal architectural improvements to eliminate code duplication and improve module independence. **No action required from users** - all changes are backwards compatible.

---

## What Changed

### 1. Home Profile DRY Refactoring ✅

**Problem**: 52 duplicate lines between `workstation.nix` and `laptop.nix`

**Solution**: Created shared base profile

**Files Changed**:
- ✅ Created: `home/profiles/base.nix` (52 lines)
- ✅ Refactored: `home/workstation.nix` (75 → 25 lines)
- ✅ Refactored: `home/laptop.nix` (53 → 11 lines)

**Result**: 84 fewer lines, single source of truth for common packages

### 2. Tailscale/Caddy Dependency Decoupling ✅

**Problem**: Tailscale module coupled to Caddy, preventing independent use

**Solution**: Moved integration logic to Caddy module with conditional

**Files Changed**:
- ✅ Modified: `modules/networking/tailscale.nix` (removed Caddy reference)
- ✅ Modified: `modules/services/caddy.nix` (added conditional integration)

**Result**:
- Tailscale works without Caddy
- Caddy works without Tailscale
- Both integrate automatically when enabled

### 3. Module Discovery Decision ✅

**Considered**: Auto-discovery like pkgs/
**Decision**: Keep explicit listing for better discoverability
**Reason**: Module API should be self-documenting for library consumers

**Files Unchanged**:
- ✅ `modules/default.nix` - explicit list maintained
- ✅ `home/default.nix` - explicit list maintained

---

## Impact on Users

### What Users Need to Do

**Nothing.** This release is 100% backwards compatible.

### What Works Differently

**Nothing.** All modules work identically from user perspective.

### What's Better

1. **More maintainable codebase** - easier to add features
2. **Better module independence** - Tailscale works standalone
3. **Clearer architecture** - explicit dependencies

---

## Documentation Created

### For Users

1. **[docs/UPGRADE.md](UPGRADE.md)**
   - How to update axios
   - Troubleshooting upgrade issues
   - Rollback instructions

2. **[docs/MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)**
   - Version-by-version breaking changes
   - Required config modifications
   - Testing procedures

3. **[docs/RELEASES.md](RELEASES.md)**
   - User-friendly release notes
   - What's new summaries
   - Feature highlights

4. **[CHANGELOG.md](../CHANGELOG.md)**
   - Technical changelog
   - All changes documented
   - Semantic versioning policy

### Updated Documentation

1. **[docs/README.md](README.md)**
   - Added maintenance section
   - Linked upgrade guides
   - Reorganized for clarity

2. **[README.md](../README.md)**
   - Added maintenance documentation links
   - Reorganized documentation section

---

## Communication to Users

### Recommended Announcement

```markdown
## Axios 2025-11-04 Released - Internal Improvements

### TL;DR
✅ No breaking changes
✅ No action required
✅ Just update and rebuild

### What's New
- Better module independence (Tailscale works without Caddy)
- Cleaner codebase (-84 lines of duplication)
- New upgrade documentation

### How to Update
```bash
cd ~/my-nixos-config
nix flake lock --update-input axios
sudo nixos-rebuild switch --flake .#HOSTNAME
```

See [RELEASES.md](docs/RELEASES.md) for details.
```

### Communication Channels

**GitHub Release Notes**: Copy from `docs/RELEASES.md`

**Discord/Community**:
> Axios 2025-11-04 is out! Internal architectural improvements with zero breaking changes. Just `nix flake lock --update-input axios` and rebuild. Full details: https://github.com/kcalvelli/axios/blob/master/docs/RELEASES.md

**README Badge** (optional):
```markdown
[![Version](https://img.shields.io/badge/version-2025--11--04-blue)](docs/RELEASES.md)
[![Breaking Changes](https://img.shields.io/badge/breaking%20changes-none-green)](docs/MIGRATION_GUIDE.md)
```

---

## Testing Checklist

Before announcing release:

- [x] Main flake check passes: `nix flake check --no-build`
- [x] Example configs build: `examples/minimal-flake`
- [x] Example configs build: `examples/multi-host`
- [x] All modules validate
- [x] Documentation complete
- [ ] Tag release in git
- [ ] Update version references
- [ ] Create GitHub release
- [ ] Announce to community

---

## Future Considerations

### Next Release (2025-12-XX or later)

Consider:
- New modules (desktop environments, services)
- New hardware support
- Feature additions

### Future Breaking Changes

Only if necessary:
- API-breaking improvements
- Module renames/reorganization
- Deprecation removals
- Clearly marked in MIGRATION_GUIDE.md

### Ongoing Maintenance

Monitor:
- User feedback on module independence
- Request for more home profiles (server, minimal, etc.)
- Need for additional validation checks

---

## Questions?

Contact maintainer or open issues on GitHub.

**Repository**: https://github.com/kcalvelli/axios
**Issues**: https://github.com/kcalvelli/axios/issues
**Documentation**: https://github.com/kcalvelli/axios/tree/master/docs
