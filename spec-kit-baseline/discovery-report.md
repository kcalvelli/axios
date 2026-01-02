# Discovery Report

## Repository Overview
- **Type**: Single Repository (Nix Flake Library)
- **Primary Languages**: Nix (100% - 73 .nix files)
- **Repository Age**: First commit 2025-10-22 (approximately 1 month old)
- **Activity Level**: High - 409 commits (231 in Nov 2025, 178 in Oct 2025)

## Technology Stack Inventory

### Languages & Runtimes
- **Nix**: [Unstable channel] - Primary language for all system and module definitions (evidence: flake.nix:7)
- **Shell/Bash**: Used for helper scripts and initialization (evidence: scripts/init-config.sh)

### Frameworks & Libraries
- **NixOS**: [unstable] - Base operating system framework
- **home-manager**: [master] - User environment management (evidence: flake.nix:22-25)
- **flake-parts**: [latest] - Flake organization framework (evidence: flake.nix:13-16)
- **agenix**: [master] - Secrets management (evidence: flake.nix:27-30)
- **lanzaboote**: [master] - Secure boot support (evidence: flake.nix:42-48)
- **DankMaterialShell**: [v0.6.2] - Niri-based Wayland shell (evidence: flake.nix:81-84)
- **niri**: [latest] - Wayland compositor (evidence: flake.nix:91-94)
- **ghostty**: [latest] - Terminal emulator (evidence: flake.nix:66-73)
- **quickshell**: [latest] - Shell widget framework (evidence: flake.nix:76-79)

### AI & Development Tools
- **AI CLI tools**: All from nixpkgs (claude-code, claude-code-acp, claude-code-router, copilot-cli, gemini-cli-bin, spec-kit, opencode)
- **mcp-servers-nix**: [latest] - MCP server configuration library (evidence: flake.nix:100-103)
- **mcp-journal**: [latest] - System journal MCP server (evidence: flake.nix:98)
- **nix-devshell-mcp**: [latest] - Nix devshell MCP server (evidence: flake.nix:99)

### Build & Development Tools
- **devshell**: [latest] - Development environment framework (evidence: flake.nix:32-35)
- **fenix**: [latest] - Rust toolchain for dev shells (evidence: flake.nix:59)
- **zig-overlay**: [latest] - Zig toolchain for dev shells (evidence: flake.nix:58)
- **rust-overlay**: [latest] - Rust overlay for build tools (evidence: flake.nix:106-109)
- **nixpkgs-fmt**: Nix code formatter (evidence: flake.nix:137)

### Infrastructure & Deployment
- **nixos-hardware**: [master] - Hardware-specific configurations (evidence: flake.nix:9-11)
- **vscode-server**: [latest] - Remote development support (evidence: flake.nix:55)
- **Cachix**: Build cache (niri.cachix.org, numtide.cachix.org) (evidence: flake.nix:113-124)

## Repository Metrics
- **Total Files**: 73 Nix files
- **Module Files**: 12 NixOS modules in modules/
- **Home Module Files**: 9 home-manager modules in home/
- **DevShells**: 3 development environments (rust, zig, qml)
- **Examples**: 2 example configurations (minimal-flake, multi-host)
- **Documentation Files**: 12+ README files across different directories
- **CI Workflows**: 6 GitHub Actions workflows

## Entry Points

### Services/Servers
- **NixOS Modules**: Exposed via `inputs.axios.nixosModules.<name>`
  - system: System configuration (locale, users, timezone)
  - desktop: Desktop environment setup
  - development: Development tools and environments
  - hardware: Hardware configurations (desktopHardware, laptopHardware)
  - graphics: GPU configuration (NVIDIA, AMD, Intel)
  - networking: Network services (samba, tailscale)
  - pim: Personal Information Management (email, calendar, contacts)
  - users: User account management
  - virt: Virtualization (libvirt, containers)
  - gaming: Gaming configuration
  - ai: AI tools and services
  - secrets: Secrets management
  - services: System services (Immich, PWA apps, Caddy, etc.)

### CLI Commands
- **init**: `nix run github:kcalvelli/axios#init` - Interactive configuration generator (evidence: flake.nix:141-148)
- **fmt**: `nix fmt` - Format Nix code with nixpkgs-fmt
- **flake check**: `nix flake check` - Validate flake structure
- **devshell**: `nix develop .#<rust|zig|qml>` - Enter development environments

### APIs
- **Flake Library**: `inputs.axios.lib` - Helper functions for downstream configurations (evidence: flake.nix:160-164)
  - Located in ./lib directory
  - Provides utility functions for building NixOS configurations

## Module Structure

### NixOS Modules (`modules/`)
- `modules/system/`: System-level configuration (locale, timezone, users)
- `modules/desktop/`: Desktop environment (GNOME, KDE, Niri)
- `modules/development/`: Development tools and environments
- `modules/gaming/`: Gaming-specific configuration
- `modules/graphics/`: GPU drivers and configuration
- `modules/hardware/`: Hardware-specific configs (desktop, laptop)
- `modules/networking/`: Network services (samba.nix, tailscale.nix)
- `modules/pim/`: Personal Information Management (email, calendar, contacts)
- `modules/secrets/`: Secrets management integration
- `modules/services/`: System services (immich.nix, caddy.nix, etc.)
- `modules/virtualisation/`: Virtualization support
- `modules/ai/`: AI tools integration

### Home Manager Modules (`home/`)
- `home/desktop/`: Desktop home configuration (niri.nix, wallpaper.nix, theming.nix, pwa-apps.nix, gdrive-sync.nix)
- `home/profiles/`: User profiles (base.nix, workstation.nix, laptop.nix)
- `home/ai/`: AI tools home configuration (default.nix, mcp.nix)
- `home/terminal/`: Terminal configuration (fish.nix, git.nix, ghostty.nix, starship.nix, tools.nix)
- `home/browser/`: Browser configuration
- `home/calendar/`: Calendar integration
- `home/secrets/`: Home-level secrets
- `home/security/`: Security tools
- `home/resources/`: Static resources (pwa-icons/, wallpapers/)

### Custom Packages (`pkgs/`)
- `pkgs/pwa-apps/`: Progressive Web App package builder

### DevShells (`devshells/`)
- `devshells/rust.nix`: Rust development environment with fenix
- `devshells/zig.nix`: Zig development environment
- `devshells/qml.nix`: Qt/QML development environment

### Library Functions (`lib/`)
- Helper functions for building NixOS configurations
- Module composition utilities

### Scripts (`scripts/`)
- `scripts/init-config.sh`: Interactive configuration generator
- `scripts/wallpaper-changed.sh`: Wallpaper change handler
- `scripts/fmt.sh`: Code formatting helper
- `scripts/templates/`: Configuration templates

### Examples (`examples/`)
- `examples/minimal-flake/`: Minimal axiOS configuration example
- `examples/multi-host/`: Multi-host configuration example

## Dependency Graph Summary

### Internal Dependencies
This is a library/framework project - no internal dependencies between modules (modules are independently importable).

### External Service Dependencies
- **Cachix**: Build artifact caching (niri.cachix.org, numtide.cachix.org)
- **GitHub**: Source repository and CI/CD
- **Upstream Flakes**: 20+ flake inputs for various functionality

## Test Coverage Indicators
- **Test Frameworks**: None explicitly configured (typical for Nix projects)
- **Test Approach**: CI-based validation
- **Coverage Tooling**: N/A (Nix evaluation is deterministic)

### CI Validation Workflows
1. **flake-check.yml**: Validates flake structure with `nix flake check --all-systems`
2. **formatting.yml**: Checks Nix code formatting with `nix fmt -- --check`
3. **test-init-script.yml**: Tests init script functionality
4. **flake-lock-updater.yml**: Weekly automated dependency updates (Mondays 6 AM UTC)
5. **flake-lock-updater-direct.yml**: Alternative direct-commit workflow (disabled)

## Change Hotspots
Recent activity shows heavy development in:
1. **Immich Module**: Custom package creation and bug fixes (v2.3.1)
2. **DMS Integration**: Updated to v0.6.2 with module architecture changes
3. **AI Module**: Expanding MCP server support and AI tool integration
4. **Home Modules**: Desktop, terminal, and profile configurations
5. **Networking**: Tailscale and Samba configuration refinements

## Versioning Strategy
- **Versioning Scheme**: [EXPLICIT] Calendar Versioning (YYYY.MM.DD format)
- **Recent Tags**: v2025.11.21, v2025.11.19, v2025.11.18, v2025.11.13
- **Release Frequency**: High - multiple releases per month
- **Changelog**: Maintained in CHANGELOG.md following Keep a Changelog format

## License
**License Type**: [EXPLICIT] MIT License (evidence: LICENSE file, README.md:98-99)
**Copyright**: (c) 2023 Keith Calvelli
**Permissions**: Use, copy, modify, merge, publish, distribute, sublicense, sell
**Conditions**: Include copyright notice and license in all copies
**Limitations**: No warranty provided

This is a permissive open-source license allowing both personal and commercial use.

## Unknowns & Ambiguities
- [TBD] Test strategy for module functionality beyond CI validation
- [TBD] Production deployment patterns for users of this library
- [TBD] Contribution guidelines (CONTRIBUTING.md not found)
- [TBD] Documentation website or hosted docs location
- [TBD] User telemetry or analytics (if any)
- [TBD] Support channels or community forums

## Project Classification
**[EXPLICIT]** This is a **library/framework project**, NOT an end-user application. It provides:
- Reusable NixOS modules
- Home-manager configurations
- Development shells
- Helper functions
- Template configurations

Users import this as a flake input into their own NixOS configurations.
