# Changelog

All notable changes to Axios will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/) (YYYY-MM-DD format).

## [Unreleased]

## [2025-11-19] - DMS Integration & Upstream Module Architecture

### Changed
- **DankMaterialShell Integration**
  - Updated to DMS v0.6.2 with new NixOS module architecture
  - Removed dms-cli input (DMS now packages dmsCli directly)
  - Moved DMS NixOS modules to baseModules in lib/default.nix
  - Auto-detect greeter configHome from axios.user.name
  - Removed 9 redundant packages now provided by DMS:
    - wl-clipboard, cava, hyprpicker, matugen, qt6ct
    - Fonts: fira-code, inter, material-symbols
    - khal (calendar)
  - Removed redundant wl-paste clipboard spawn (DMS provides this)

### Added
- **PWA Module**
  - Added extensible PWA module for custom progressive web apps
  - Users can add custom PWAs with their own URLs and icons

### Fixed
- Added required tailscale domain to server example config
- Fixed duplicate DMS module import causing option declaration errors

## [2025-11-13] - MCP Integration & Home Module Architecture

### Added
- **MCP Server Enhancements**
- Integrated nix-devshell-mcp server for Nix development environment management
- **AI Tools Expansion**
- Added Google Jules CLI via npm
- Added Gemini CLI and integration
- Added Claude Desktop and additional Claude tools
- Added Claude usage monitoring to AI module
- Added Claude Code project context file (CLAUDE.md)

### Changed
- **Module Architecture Refactoring**
- Implemented CODE_REVIEW.md recommendations for home module architecture
- Added axios.system.enable option with mkIf guards for consistency
- Moved browser and calendar modules to desktop.enable conditional loading
- Fixed AI module to follow conditional import pattern at system level
- Cleaned up base profile to include only core tools (security, terminal)
- **AI Module Restructuring**
- Migrated from mcpo to mcp-servers-nix library for declarative MCP configuration
- Removed ollama and open-webui from AI module (these were overly opinionated for a library)
- Renamed 'code' from nix-ai-tools to 'coder' to avoid VSCode conflict
- Removed overlapping AI CLI tools, retained only essentials
- Removed spec-kit devshell, integrated spec-kit from nix-ai-tools
- **Dependency Updates**
- Updated flake inputs for latest features and fixes

### Fixed
- **AI Module Fixes**
- Fixed MCP server package names from mcp-servers-nix
- Enabled programs.claude-code module for proper MCP configuration
- Fixed brave-search and tavily to use npx for execution
- **Build System Fixes**
- Fixed deprecated system references to use stdenv.hostPlatform.system
- **Configuration Fixes**
- Fixed age identityPaths to use absolute paths
- **Home Module Fixes**
- Fixed AI module conditional loading (removed from base.nix)
- Fixed home module import paths after restructuring

### Removed
- **AI Module Cleanup**
- Removed mcp-chat custom package (experimental tool no longer needed)
- Removed ollama module (overly opinionated for a library distribution)
- Removed open-webui module (overly opinionated for a library distribution)

### Documentation
- Enhanced GEMINI.md with project overview and workflow improvements
- Added comprehensive CODE_REVIEW.md implementation documentation
- Updated documentation for new MCP server integrations

## [2025-11-08.1] - Theming & VSCode Integration Improvements

### Added
- **DankMaterialShell Enhancements**
- Added DankHooks plugin for enhanced functionality
- Integrated dsearch (DankMaterialShell search) feature
- Added VSCode extension registration system
- Implemented Base16 color scheme support for VSCode (Dank16)
- Added wallpaper-changed.sh script integration

### Changed
- **Theming Improvements**
- Simplified theming documentation for better clarity
- Disabled Material Code theme as DMS default
- Reverted to simple plugin installation per documentation
- Allow users to modify plugin settings via GUI
- Made Base16 VSCode extension files writable for proper detection

### Fixed
- Added config parameter to function signature in theming module
- Fixed wallpaper script path to reference deployed location in user home directory
- Removed material-code theme update from wallpaper hook (refactored approach)

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
