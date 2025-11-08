# Changelog

All notable changes to Axios will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/) (YYYY-MM-DD format).

## [Unreleased]

## [2025-11-08] - Desktop Consolidation & Module Cleanup

### Added
- **Containers Module Enhancements**
  - Added Docker alongside Podman (Winboat requires Docker)
  - Enabled Waydroid for Android app support
  - Added Winboat and FreeRDP packages
  - Automatic docker group membership for all normal users when containers enabled
- **Virtualization Improvements**
  - Added dynamic ownership configuration for libvirt/QEMU
  - Fixed permission denied errors when accessing ISO files in user directories
  - Added polkit support for better user permissions

### Changed
- **Major Module Refactoring**
  - Consolidated `wayland` and `niri` home modules into unified `desktop` module
  - Merged `wayland-theming` and `wayland-material` into single `desktop/theming.nix`
  - Consolidated `modules/wayland` into `modules/desktop`
  - Moved DankMaterialShell configuration to desktop default.nix
- **AI Module Restructuring**
  - Separated ollama and open-webui into independent modules
  - Merged caddy.nix into open-webui.nix (co-located with service it supports)
  - Consolidated packages.nix into AI module default.nix
  - Added separate enable options: `services.ai.ollama.enable` and `services.ai.openWebUI.enable`
- **Code Quality**
  - Removed all unused code detected by deadnix (27 files cleaned up)
  - Fixed deprecated NixOS options (qemuVerbatimConfig → qemu.verbatimConfig)
  - Removed deprecated OVMF configuration (now included by default)

### Fixed
- Restored required `config`, `osConfig`, and `inputs` to secrets module
- Fixed duplicate gnome-keyring.enable definition in desktop module
- Corrected import paths in profile modules (./profiles/base.nix → ./base.nix)
- Added required `axios.system.timeZone` to example configurations
- Fixed init app missing meta.description attribute

### CI/CD
- Removed fragile validation tests (too many breaking changes during active development)
- Updated example configurations to work with new module structure
- Simplified GitHub Actions to focus on flake structure validation

### Documentation
- Updated examples to reflect new desktop module structure
- Improved inline documentation for module organization
- Added clear comments about UEFI/OVMF being available by default

## [2024-XX-XX] - Initial Release

Initial release of Axios as a NixOS library.

### Added
- Core library API with `mkSystem` function
- System modules: system, desktop, development, graphics, networking, services, users, virtualization
- Home modules: wayland, workstation, laptop, AI tools
- Hardware support for AMD/Intel CPUs, AMD/Nvidia GPUs, System76/MSI hardware
- Niri compositor with DankMaterialShell integration
- AI module with Ollama, OpenWebUI, and Claude Code support
- Interactive config generator (`nix run github:kcalvelli/axios#init`)
- Comprehensive documentation and examples
- CI/CD with automated testing and binary cache

---

## Versioning Policy

Axios follows [Calendar Versioning (CalVer)](https://calver.org/) using **YYYY-MM-DD** format.

### Version Format

Releases are dated by when they were released:
- **2025-11-04**: Release on November 4, 2025
- **2025-12-15**: Release on December 15, 2025

### Release Cadence

Axios doesn't follow a fixed schedule. New releases when:
- Significant features are added
- Important bug fixes accumulate
- Breaking changes are necessary (rare)

### Breaking Changes

Breaking changes are avoided when possible and clearly documented:
- Renaming or removing exported modules (e.g., `flake.nixosModules.*`)
- Changing `mkSystem` API parameters or behavior
- Removing or renaming module options users might reference
- Changing default behaviors that affect user systems

### Non-Breaking Changes

Internal improvements that don't affect user configs:
- Internal module refactoring (implementation details)
- Adding new modules or options
- Improving error messages or validation
- Documentation updates
- Performance improvements
- Bug fixes that restore intended behavior

---

**See Also**: [MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) for detailed upgrade instructions
