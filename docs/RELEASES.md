# Axios Release Notes

User-friendly summaries of what's new in each Axios release.

Axios uses [Calendar Versioning (CalVer)](https://calver.org/) with YYYY-MM-DD format.

---

## 2025-11-04 - Architectural Improvements (Unreleased)

### 🎯 TL;DR

**No action required** - Internal improvements with zero breaking changes. Just update and rebuild.

```bash
cd ~/my-nixos-config
nix flake lock --update-input axios
sudo nixos-rebuild switch --flake .#HOSTNAME
```

### ✨ What's New

#### Better Module Independence
Modules are now more loosely coupled and can work independently:

- **Tailscale without Caddy**: Networking module now works standalone
- **Automatic integration**: Caddy still automatically integrates with Tailscale when both enabled
- **Clearer dependencies**: No hidden coupling between modules

#### Cleaner Codebase
Internal refactoring reduced code duplication:

- Home profiles (workstation/laptop) now share common base
- 84 fewer lines of duplicate code
- Easier to maintain and extend

### 📋 What Stayed the Same

✅ All module names unchanged
✅ All module options unchanged
✅ mkSystem API unchanged
✅ Example configurations still valid
✅ No config modifications needed

### 🔍 Technical Details

For developers and advanced users:

**Home Profiles**:
- Created `home/profiles/base.nix` with shared packages
- `workstation.nix` and `laptop.nix` now import base
- Easier to add packages to both profiles

**Module Dependencies**:
- Moved Tailscale-Caddy integration from `networking/tailscale.nix` to `services/caddy.nix`
- Uses conditional logic: `lib.mkIf config.services.tailscale.enable`
- Proper separation of concerns

### 📚 Documentation

New documentation files:
- `docs/UPGRADE.md` - How to upgrade Axios
- `docs/MIGRATION_GUIDE.md` - Breaking changes (none this release)
- `CHANGELOG.md` - Technical changelog
- `docs/RELEASES.md` - User-friendly release notes (this file)

### 🐛 Bug Fixes

None - this is a refactoring release.

### ⚠️ Known Issues

None

### 🙏 Credits

Thanks to the NixOS community for feedback on module organization patterns.

---

## 2024-XX-XX - Initial Release

Initial release of Axios as a NixOS library and framework.

### Features

#### Core Library
- `mkSystem` function for building NixOS configurations
- Simple API requiring ~30 lines of user config
- Comprehensive validation with helpful error messages
- Interactive config generator

#### System Modules
- **system**: Core utilities, sound, printing, boot configuration
- **desktop**: Desktop environment with Niri compositor
- **wayland**: Wayland support with DankMaterialShell
- **development**: Developer tools and environments
- **graphics**: AMD/Nvidia GPU support
- **networking**: Network services, Tailscale, Avahi, Samba
- **services**: Optional services (Caddy, MQTT, Home Assistant, ntopng)
- **gaming**: Steam, GameMode, gaming optimizations
- **ai**: Ollama, OpenWebUI, Claude Code integration
- **users**: User management and home-manager integration
- **virtualisation**: VM and container support

#### Hardware Support
- AMD and Intel CPUs
- AMD and Nvidia GPUs
- System76 and MSI specific hardware
- Generic desktop and laptop configurations
- SSD optimizations

#### Home Manager Modules
- **wayland**: User-level Wayland configuration
- **workstation**: Full desktop profile with gaming
- **laptop**: Mobile-optimized profile
- **ai**: AI tools integration (Claude Code, MCP servers)

#### Desktop Experience
- Niri compositor with tiling workflow
- DankMaterialShell for modern UI
- Material Design theming
- PWA support (Gmail, Messages, Drive, etc.)
- Ghostty terminal with Nerd Fonts
- Fish shell with Starship prompt
- LazyVim configuration

#### Developer Experience
- Development shells: Rust, Zig, QML, Spec
- VSCode integration
- Git configuration
- Neovim with LazyVim

#### Documentation
- Comprehensive installation guide
- Library usage documentation
- Application catalog
- Package organization guide
- Quick reference
- Troubleshooting guide

#### Infrastructure
- GitHub Actions CI/CD
- Automated flake checks
- Example configuration testing
- Binary cache via Cachix
- Automatic flake.lock updates

---

## Release Schedule

Axios uses [Calendar Versioning (CalVer)](https://calver.org/) with **YYYY-MM-DD** format.

New releases are published when:
- Significant features are added
- Important bug fixes accumulate
- Breaking changes are necessary (rare)

Releases are dated by publication date, not by development time.

---

## Getting Updates

### Follow Releases

1. Star the [axios repository](https://github.com/kcalvelli/axios)
2. Watch → Custom → Releases
3. Check this file before updating

### Update Command

```bash
# Update axios input
cd ~/my-nixos-config
nix flake lock --update-input axios

# Review what changed
cat $(nix build github:kcalvelli/axios#docs --no-link --print-out-paths)/RELEASES.md

# Apply update
sudo nixos-rebuild switch --flake .#HOSTNAME
```

---

**See Also**:
- [UPGRADE.md](UPGRADE.md) - Detailed upgrade instructions
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Breaking changes
- [CHANGELOG.md](../CHANGELOG.md) - Technical changelog
