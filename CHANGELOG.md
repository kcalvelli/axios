# Changelog

All notable changes to Axios will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/) (YYYY-MM-DD format).

## [Unreleased]

### Changed
- Internal refactoring of home profiles to eliminate code duplication
- Improved Tailscale/Caddy module independence for better composability

### Internal
- Created `home/profiles/base.nix` as shared base for workstation and laptop profiles
- Moved Tailscale-Caddy integration logic from networking module to services module
- Reduced codebase by ~84 lines of duplicate code while improving maintainability

### Documentation
- Added MIGRATION_GUIDE.md for tracking breaking changes between versions
- Added CHANGELOG.md for tracking all changes

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
