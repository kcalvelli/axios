# Changelog

All notable changes to Axios will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Calendar Versioning](https://calver.org/) (YYYY-MM-DD format).

## [Unreleased]

## [v2026.01.13] - 2026-01-13

Major release with 329 commits over 33 days. Includes new PIM and C64 modules, enhanced PWA workflow, and major desktop refinements.

### ⚠️ BREAKING CHANGES

- **MCP Secrets Management Removed**: `services.ai.secrets` options have been removed. Users must now configure API keys via `environment.sessionVariables`:
  ```nix
  environment.sessionVariables = {
    BRAVE_API_KEY = "your-api-key";
    GITHUB_TOKEN = "ghp_your-token";  # Optional, gh CLI handles this
  };
  ```

### Added

#### New Modules

- **PIM Module** (`modules/pim/`)
  - New dedicated module for Personal Information Management
  - Geary email client integration
  - GNOME Calendar and Contacts with GNOME Online Accounts integration
  - vdirsyncer for calendar/contact syncing
  - Supported backends: Gmail, IMAP/SMTP, CalDAV, CardDAV
  - **Note**: Outlook/Office365 integration currently not working
  - Uses Evolution Data Server (lightweight D-Bus service) without requiring full GNOME desktop
  - Enable via `modules.pim = true`

- **C64/Ultimate64 Integration** (`modules/c64/`)
  - Full support for Commodore 64 and Ultimate64 hardware
  - c64-stream-viewer: Real-time video/audio streaming from Ultimate64 hardware
  - c64term: Terminal emulator with authentic PETSCII colors and boot screen
  - ultimate64-mcp: MCP server for AI-driven control (file transfer, program execution)
  - Niri window rules for C64 applications
  - Enable via `modules.c64 = true`

#### AI & MCP Enhancements

- **System Prompts for AI Agents**
  - Comprehensive axios system prompt (auto-injected into Claude Code)
  - MCP server usage guides for AI agents
  - Dynamic tool discovery with mcp-cli documentation
  - Per-tool enablement (claude.enable, gemini.enable)
  - Unified AI coding experience
  - Custom instructions support via `~/.config/ai/prompts/axios.md`
  - Auto-injection into `~/.claude.json` during home-manager switch

- **MCP Examples**
  - Comprehensive MCP server configuration examples (`home/ai/mcp-examples.nix`)
  - 100+ ready-to-use server configurations
  - Examples for Notion, Slack, Jira, PostgreSQL, SQLite, Docker, and more

#### Desktop & PWA Enhancements

- **Enhanced PWA Workflow**
  - `add-pwa` script now auto-updates configuration
  - Auto-format with `nix fmt` after insertion
  - Smart insertion detection for axios project structure
  - Auto-sanitize manifest categories to Freedesktop standards
  - Improved icon fetching with better quality and transparency handling
  - 20+ PWA icons updated (Google suite, productivity apps)
  - Added new PWAs: Linear, Notion, Figma, Excalidraw, Flathub

- **Desktop Refinements**
  - Major Niri/KDE interoperability fixes (xdg-portals, kdialog, file choosers)
  - Dedicated keybindings guide (`home/desktop/niri-keybinds.nix`)
  - Improved window rules for various applications
  - Enhanced DMS outputs.kdl configuration
  - Mouse wheel bindings for column navigation
  - Fixed Qt platform environment variables
  - Portal configuration for KDE file choosers

#### Gaming & Graphics

- **Gaming Module Enhancements**
  - Binary compatibility via nix-ld for native Linux games
  - SDL2 family libraries (SDL2_image, SDL2_mixer, SDL2_ttf)
  - Graphics APIs (libGL, vulkan-loader)
  - Audio libraries (alsa-lib, openal, libpulseaudio)
  - Fixes "library not found" errors for indie games, Unity, MonoGame

- **Desktop Module**
  - USB device permissions for game controllers (Sony, Microsoft, Nintendo, Valve)
  - Normal users can access USB devices without root
  - Also benefits Arduino, dev boards, USB peripherals

- **Graphics Module**
  - vulkan-tools (vulkaninfo, vkcube) for all GPU types
  - Helps users verify GPU setup and debug graphics issues

#### Development

- **Development Module**
  - Inotify tuning for file watchers (fs.inotify.max_user_watches = 524288)
  - Fixes "ENOSPC: System limit for number of file watchers reached"
  - Critical for VS Code, Rider, WebStorm, hot-reload workflows

### Fixed

- **Graphics Module (Critical)**
  - Fixed nvidia/intel GPU support (was broken, AMD-only prior to this release)
  - Added missing `services.xserver.videoDrivers = ["nvidia"]` (critical for Nvidia to work!)
  - Added hardware.nvidia.nvidiaSettings and nvidia-settings package
  - Added power management defaults (disabled by default per NixOS wiki)
  - Graphics module now conditionally applies GPU-specific configuration:
    - AMD: radeontop, corectrl, amdgpu_top, HIP_PLATFORM
    - Nvidia: nvtopPackages.nvidia, nvidia-settings, proper driver loading
    - Intel: intel-gpu-tools, intel-media-driver
    - Common packages (clinfo, wayland-utils, vulkan-tools) available for all GPU types

- **Desktop**
  - Portal configuration for KDE file choosers
  - Numerous Niri window rules and keybindings fixes
  - Icon and desktop entry corrections
  - Fixed clipboard functionality with manual wl-paste spawn
  - Prevented duplicate DMS spawning with systemd service configuration

- **Scripts**
  - Improved robustness and error handling in add-pwa
  - Better edge case handling in configuration scripts

### Changed

- **AI Tools**
  - Removed copilot-cli (focus on Claude Code and Gemini CLI)
  - MCP secrets now configured via environment variables instead of agenix
  - Simplified MCP configuration for easier setup

- **Hardware Configuration**
  - New `hardwareConfigPath` option replacing `diskConfigPath` (backward compatible)
  - Init script now copies complete hardware-configuration.nix
  - Prevents missing VirtIO modules and boot configuration issues

### Documentation

- **Consolidated MCP Documentation**
  - Created comprehensive `docs/MCP_GUIDE.md` (complete setup and usage)
  - Created `docs/MCP_REFERENCE.md` (quick command reference)
  - Removed 6 redundant MCP documentation files
  - Clearer navigation and reduced duplication

- **New Documentation**
  - Added `docs/PWA_GUIDE.md` - Progressive Web Apps guide
  - Added `docs/MODULE_REFERENCE.md` - Complete module reference
  - Added `docs/APPLICATIONS.md` - Application catalog
  - Merged `docs/hardware-quirks.md` into `docs/TROUBLESHOOTING.md`

- **Migrated to OpenSpec SDD**
  - Moved from monolithic `spec-kit-baseline` to modular `openspec/`
  - Integrated delta-based development workflow
  - Updated AI agent instructions for spec-driven development
  - Documented C64/Ultimate64 module across all baseline files
  - Documented PIM module architecture and features
  - Updated MCP secrets management documentation
  - Added graphics module fixes and troubleshooting
  - Added system prompts architecture documentation
  - Updated hardware configuration pattern documentation

### Migration Guide

**For users with Brave Search or other MCP servers requiring API keys:**

Old configuration (no longer works):
```nix
services.ai.secrets.braveApiKeyPath = config.age.secrets.brave-api-key.path;
```

New configuration:
```nix
environment.sessionVariables = {
  BRAVE_API_KEY = "your-api-key";
};
```

**Note**: Log out and log back in after rebuilding for environment variables to take effect.

## [2025-12-11] - VM Support & Hardware Configuration Fix

### Added
- **Hardware Configuration Support**
  - Added `hardwareConfigPath` option for full hardware configuration
  - Init script now copies complete `hardware-configuration.nix` instead of extracting parts
  - Includes boot modules, kernel modules, filesystems, and swap in one file
  - Fixes VM boot failures caused by missing VirtIO kernel modules
  - Fixes boot issues on exotic hardware requiring specific kernel modules

### Changed
- **Init Script**
  - Simplified hardware config generation by copying full file instead of filtering
  - Renamed generated file from `disks.nix` to `hardware.nix` (clearer naming)
  - Removed complex AWK extraction logic that missed critical boot configuration
  - Updated templates to use `hardwareConfigPath` instead of `diskConfigPath`

### Fixed
- **VM Installation**
  - Fixed emergency boot in VMs due to missing VirtIO kernel modules
  - Fixed boot failures on hardware requiring specific initrd kernel modules
  - Documentation previously claimed kernel modules were extracted, but they weren't

### Documentation
- **Migration Guide**
  - Added comprehensive migration guide from `diskConfigPath` to `hardwareConfigPath`
  - Documented backward compatibility (both options supported)
  - Clarified UEFI-only requirement for axiOS (BIOS/MBR not supported)
  - Updated all examples and templates to use new `hardwareConfigPath`

### Backward Compatibility
- **No Breaking Changes**
  - `diskConfigPath` still works (legacy support maintained)
  - Existing configurations continue to work unchanged
  - Migration is optional but recommended

## [2025-12-04] - Idle Management & Comprehensive Documentation

### Added
- **Idle Management**
  - Implemented swayidle-based automatic screen power management
  - Default 30-minute timeout to power off monitors via `niri msg action power-off-monitors`
  - Managed via systemd user service (auto-starts with desktop session)
  - Fully configurable via home-manager `services.swayidle.timeouts`
  - Manual lock available via Super+Alt+L (DMS lock screen keybind)
- **Documentation**
  - Created comprehensive `docs/APPLICATIONS.md` with complete 80+ app catalog
  - Organized by category: desktop, development, terminal, gaming, virtualization, AI
  - Added application count summary and finding applications guide
  - Added PWA configuration examples

### Changed
- **Desktop Module**
  - Enhanced DankMaterialShell feature documentation
  - Added window rules for Brave picture-in-picture mode
  - Added window rules for DMS settings window
  - Fixed clipboard functionality with manual wl-paste spawn
  - Prevented duplicate DMS spawning with systemd service configuration
- **Documentation Overhaul**
  - Rewrote AI module documentation with two-tier architecture
  - Documented local LLM stack (Ollama, OpenCode)
  - Added ROCm acceleration details and 32K context window information
  - Expanded DankMaterialShell features (10+ specific features listed)
  - Added library philosophy section explaining design principles
  - Updated README with accurate application counts
  - Added comprehensive MCP server documentation

### Fixed
- **Desktop**
  - Restored clipboard functionality after DMS systemd service migration
  - Fixed duplicate DMS instance spawning
  - Optimized polkit agent configuration (consolidated to DMS built-in)

## [2025-11-21] - Immich 2.3.1 Custom Package

### Added
- **Custom Immich Package**
  - Added complete Immich 2.3.1 derivation in `pkgs/immich/`
  - Fixes critical rendering loop bug from version 2.2.3
  - Includes corePlugin manifest for workflow capabilities
  - Proper pnpmDeps hash for reproducible builds
  - Will be removed once nixpkgs updates to 2.3.1+

### Fixed
- **Immich Service**
  - Fixed browser freeze caused by new version notification rendering loop
  - Fixed 502 error from missing corePlugin manifest.json
  - Fixed externalDomain configuration for proper web app connectivity
  - Service now starts reliably and web app works correctly
- **Desktop Module**
  - Removed deprecated `programs.file-roller.enable` option
  - Added file-roller directly to system packages

### Changed
- Updated Immich service to use custom package from `pkgs.immich`
- Simplified Immich module by removing failed override attempts

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
- Enabled DMS NixOS module for system packages (matugen, hyprpicker, cava)
- Set quickshell package at NixOS level for proper theme worker operation

### Removed
- Removed dgop input (DMS now manages its own)

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
- Fixed brave-search to use npx for execution
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
