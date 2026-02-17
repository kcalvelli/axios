# Glossary

## Purpose
This glossary defines domain-specific terms, acronyms, and technical concepts used throughout the axiOS codebase. Understanding these terms is essential for working with the system.

## Domain Terminology

### axiOS
**Definition**: A modular NixOS framework and library that provides reusable modules, packages, and configurations for building NixOS systems

**Usage**: Repository name, flake name, module prefix
- Code: `inputs.axios.nixosModules.<module>`
- CLI: `nix run github:kcalvelli/axios#init`

**Related Terms**: NixOS, Flake, Module

**Evidence**: flake.nix:2, README.md:1

### Module
**Definition**: A self-contained NixOS or home-manager configuration unit that provides specific functionality and can be independently imported

**Usage**: Primary building block of axiOS
- Pattern: Directory with `default.nix` containing options and config
- Import: `imports = [ inputs.axios.nixosModules.desktop ];`

**Related Terms**: NixOS Module, Home Module, Enable Option

**Evidence**: modules/default.nix, .claude/project.md:60-66

### Home Module
**Definition**: A home-manager module that configures user environment settings (distinct from system-level NixOS modules)

**Usage**: User environment configuration
- Location: `home/` directory
- Access: `inputs.axios.homeModules.<name>`

**Related Terms**: Home Manager, User Environment, Module

**Evidence**: home/default.nix

### Enable Option
**Definition**: A boolean module option that controls whether a module's configuration is applied

**Usage**: All modules follow this pattern
- Option: `<module>.enable = true;`
- Guard: `config = lib.mkIf cfg.enable { ... };`

**Related Terms**: Module, Configuration, mkIf

**Evidence**: All module default.nix files

### DevShell
**Definition**: A Nix development environment with project-specific toolchains and tools

**Usage**: Temporary development environment
- Access: `nix develop .#<shell-name>`
- Types: rust, zig, qml

**Related Terms**: Development Environment, Nix Shell

**Evidence**: devshells/

### Flake
**Definition**: A Nix project with explicit inputs/outputs and lock file for reproducibility

**Usage**: Project structure format
- Entry: `flake.nix`
- Lock: `flake.lock`

**Related Terms**: Nix, Reproducibility, Input, Output

**Evidence**: flake.nix

### Flake Input
**Definition**: An external dependency declared in a flake (typically another flake or git repository)

**Usage**: Dependencies for the project
- Declaration: `inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";`
- Usage: `inputs.nixpkgs.legacyPackages.${system}.<package>`

**Related Terms**: Flake, Dependency, nixpkgs

**Evidence**: flake.nix:4-110

### Flake Output
**Definition**: A value exported by a flake for consumption by other flakes or commands

**Usage**: Exposed functionality
- Types: nixosModules, homeModules, packages, apps, devShells
- Access: `inputs.axios.nixosModules.desktop`

**Related Terms**: Flake, Module, Package

**Evidence**: flake.nix:127-165, modules/default.nix, home/default.nix

### Aspect File
**Definition**: Additional .nix files within a module directory that provide specific functionality (imported by default.nix)

**Usage**: Organize module code by concern
- Example: `modules/networking/samba.nix`, `modules/networking/tailscale.nix`
- Import: Automatically by modules/networking/default.nix

**Related Terms**: Module, Module Structure

**Evidence**: .claude/project.md:65, modules/networking/, modules/services/

### Base Profile
**Definition**: Common home-manager configuration shared by all user profiles

**Usage**: Foundation for workstation and laptop profiles
- Location: `home/profiles/base.nix`
- Extended by: workstation.nix, laptop.nix

**Related Terms**: Profile, Home Module

**Evidence**: home/profiles/base.nix

### Profile
**Definition**: Pre-composed collection of home modules for specific use cases (workstation, laptop)

**Usage**: Quick setup for common configurations
- Types: workstation, laptop
- Access: `inputs.axios.homeModules.workstation`

**Related Terms**: Home Module, Base Profile

**Evidence**: home/profiles/

### DMS
**Definition**: DankMaterialShell - A Material Design shell with custom theming built on quickshell

**Usage**: Desktop shell environment
- Integration: NixOS module from upstream
- Version: v0.6.2

**Related Terms**: Niri, Quickshell, Desktop

**Evidence**: flake.nix:81-84, CHANGELOG.md:36-46

### Niri
**Definition**: A scrollable tiling Wayland compositor with overview mode

**Usage**: Primary Wayland compositor for axiOS desktop
- Configuration: home/desktop/niri.nix
- Upstream: github:sodiboo/niri-flake

**Related Terms**: Wayland, Compositor, DMS

**Evidence**: flake.nix:91-94, README.md:40

### MCP
**Definition**: Model Context Protocol - A protocol for integrating context providers with AI assistants

**Usage**: AI tool integration
- Servers: git, github, filesystem, journal, etc.
- Config: `programs.claude-code.mcpServers`

**Related Terms**: MCP Server, Claude Code, AI Tools

**Evidence**: home/ai/mcp.nix, flake.nix:98-103

### MCP Server
**Definition**: A service that provides context to AI assistants via the Model Context Protocol

**Usage**: Extend AI assistant capabilities
- Examples: mcp-journal (systemd logs), mcp-dav (calendar/contacts), github
- Configuration: Declarative via `programs.claude-code.mcpServers`

**Related Terms**: MCP, Claude Code, Context Provider

**Evidence**: home/ai/mcp.nix

### agenix
**Definition**: Age-based secrets management for NixOS

**Usage**: Encrypted secrets in configuration
- Encryption: age encryption
- Storage: `/run/secrets/`
- Config: `age.secrets.<name>.file = ./secrets/<name>.age;`

**Related Terms**: Secrets, Age, Encryption

**Evidence**: flake.nix:27-30, modules/secrets/, home/secrets/

### Cachix
**Definition**: Binary cache service for Nix packages

**Usage**: Fast package downloads (avoid building from source)
- Caches: niri.cachix.org, numtide.cachix.org
- Config: flake.nix nixConfig section

**Related Terms**: Binary Cache, Nix Store, Substituter

**Evidence**: flake.nix:112-124

### Disko
**Definition**: Declarative disk partitioning for NixOS

**Usage**: Automated disk setup
- Templates: Pre-defined partition layouts
- Use case: Initial system installation

**Related Terms**: Disk Partitioning, Installation

**Evidence**: flake.nix:50-53, README.md:54

### Immich
**Definition**: Self-hosted photo and video backup solution with mobile app

**Usage**: Photo management service
- Package: Uses nixpkgs version
- Service: modules/services/immich.nix
- Access: HTTPS via Caddy + Tailscale

**Related Terms**: Photo Backup, Self-Hosted, Caddy

**Evidence**: modules/services/immich.nix, CHANGELOG.md:13-18

### Lanzaboote
**Definition**: Secure Boot support for NixOS

**Usage**: UEFI Secure Boot integration
- Purpose: Boot with signature verification

**Related Terms**: Secure Boot, UEFI

**Evidence**: flake.nix:42-48


### PWA
**Definition**: Progressive Web App - Web application that can be installed and run standalone

**Usage**: Custom web app installations
- Package: pkgs/pwa-apps/
- Config: home/desktop/pwa-apps.nix

**Related Terms**: Web Application, Desktop Application

**Evidence**: pkgs/pwa-apps/, home/desktop/pwa-apps.nix, CHANGELOG.md:49

### C64
**Definition**: Commodore 64 - An 8-bit home computer introduced by Commodore International in 1982, one of the best-selling single computer models of all time

**Usage**: Retro computing integration in axiOS
- Module: modules/c64/
- Enable: `modules.c64 = true`

**Related Terms**: Ultimate64, PETSCII, Retro Computing

**Evidence**: modules/c64/default.nix

### Ultimate64
**Definition**: FPGA-based hardware reimplementation of the Commodore 64, providing cycle-exact compatibility with original hardware plus modern features like HDMI output, network connectivity, and USB support

**Usage**: Hardware platform for C64 module
- Streaming: c64-stream-viewer streams video/audio from Ultimate64
- MCP: ultimate64-mcp server provides AI-driven control
- Requirements: Device must be accessible on local network

**Related Terms**: C64, FPGA, Retro Computing

**Evidence**: modules/c64/default.nix, home/ai/mcp.nix

### PETSCII
**Definition**: PET Standard Code of Information Interchange - The character set used by Commodore computers, including unique graphics characters and control codes

**Usage**: C64 terminal emulator character rendering
- Tool: c64term displays authentic PETSCII characters
- Features: Period-accurate colors, boot screen, graphics characters

**Related Terms**: C64, ASCII, Character Encoding

**Evidence**: modules/c64/default.nix (c64term terminal emulator)

### Syncthing
**Definition**: Peer-to-peer file synchronization tool that syncs files between devices without a central server

**Usage**: XDG directory sync across axiOS hosts
- Transport: Tailscale MagicDNS (no external discovery or relays)
- Module: modules/syncthing/default.nix
- Config: `axios.syncthing` namespace

**Related Terms**: Tailscale, XDG, MagicDNS

**Evidence**: modules/syncthing/default.nix

## Technical Terminology

### mkIf
**Definition**: NixOS function that conditionally applies configuration based on a boolean condition

**Context**: Core pattern for conditional module evaluation
- Usage: `config = lib.mkIf cfg.enable { ... };`
- Purpose: Prevent disabled modules from evaluating

**Related Terms**: Module, Enable Option, Conditional Evaluation

**Evidence**: .claude/project.md:63-64, all module files

### mkEnableOption
**Definition**: NixOS function that creates a boolean enable option with standard description

**Context**: Standard pattern for module enable flags
- Usage: `enable = lib.mkEnableOption "Description";`
- Result: Creates `<module>.enable` option

**Related Terms**: Module, Enable Option

**Evidence**: All module default.nix files

### mkOption
**Definition**: NixOS function that declares a configuration option with type, default, and description

**Context**: Define module configuration parameters
- Usage: `option = lib.mkOption { type = types.str; default = "value"; };`

**Related Terms**: Module Options, Configuration

**Evidence**: Module default.nix files with complex options

### mkForce
**Definition**: NixOS function that forces a configuration value, overriding other definitions

**Context**: Resolve option conflicts
- Usage: `option = lib.mkForce value;`
- Priority: Highest priority (overrides defaults and normal assignments)

**Related Terms**: mkDefault, Option Priority

**Evidence**: Constitution.md troubleshooting section

### mkDefault
**Definition**: NixOS function that sets a default value that can be overridden

**Context**: Provide overridable defaults
- Usage: `option = lib.mkDefault value;`
- Priority: Lower than normal assignment

**Related Terms**: mkForce, Option Priority

**Evidence**: Constitution.md troubleshooting section

### Derivation
**Definition**: A Nix build recipe that describes how to build a package

**Context**: Fundamental build unit in Nix
- Result: Package in Nix store
- Hash: Content-addressed

**Related Terms**: Nix Store, Package, Build

**Evidence**: pkgs/pwa-apps/default.nix, pkgs/default.nix

### Nix Store
**Definition**: Content-addressed, immutable storage for Nix packages and build artifacts

**Context**: `/nix/store/` directory
- Format: `/nix/store/<hash>-<name>-<version>/`
- Immutable: Read-only after build

**Related Terms**: Derivation, Package, Content-Addressed

**Evidence**: Nix fundamental concept

### NixOS Generation
**Definition**: A complete NixOS system configuration snapshot that can be booted or activated

**Context**: System versioning and rollback
- Storage: Boot menu entries
- Rollback: `nixos-rebuild switch --rollback`

**Related Terms**: Rollback, System Configuration

**Evidence**: Runbook.md deployment section

### Substituter
**Definition**: A binary cache server that provides pre-built Nix packages

**Context**: Avoid building from source
- Examples: cache.nixos.org, niri.cachix.org
- Config: `extra-substituters` in nix.conf

**Related Terms**: Cachix, Binary Cache

**Evidence**: flake.nix:113-116

### Home Manager
**Definition**: Tool for managing user environments declaratively with Nix

**Context**: User-level configuration
- Config: home.nix or home modules
- Scope: User packages, dotfiles, services

**Related Terms**: Home Module, User Environment

**Evidence**: flake.nix:22-25

### Wayland
**Definition**: Modern display server protocol (replacement for X11)

**Context**: Display technology
- Compositor: Niri
- Protocols: Layer-shell, XDG shell

**Related Terms**: Niri, Compositor, X11

**Evidence**: modules/desktop/, Wayland ecosystem

## Acronyms

### CI/CD
**Expansion**: Continuous Integration / Continuous Deployment

**Definition**: Automated testing and deployment pipeline

**Usage**: GitHub Actions workflows
- CI: flake-check, formatting, test-init-script
- CD: N/A (library project)

**Evidence**: .github/workflows/

### TLS
**Expansion**: Transport Layer Security

**Definition**: Cryptographic protocol for secure communication

**Usage**: HTTPS certificates
- Provider: Tailscale (automatic cert management)
- Services: Caddy reverse proxy

**Evidence**: modules/networking/tailscale.nix, modules/services/caddy.nix

### HTTPS
**Expansion**: Hypertext Transfer Protocol Secure

**Definition**: HTTP over TLS for secure web communication

**Usage**: Self-hosted services
- Cert: Tailscale TLS
- Server: Caddy

**Evidence**: modules/services/caddy.nix

### CLI
**Expansion**: Command-Line Interface

**Definition**: Text-based interface for commands

**Usage**: Terminal tools, AI assistants
- Examples: claude-code CLI, gemini CLI
- Context: Terminal module

**Evidence**: modules/ai/, home/terminal/

### API
**Expansion**: Application Programming Interface

**Definition**: Interface for programmatic access

**Usage**: External service integration
- Examples: GitHub API (MCP server), Brave Search API
- Keys: Managed via agenix

**Evidence**: home/ai/mcp.nix (API key references)

### GPU
**Expansion**: Graphics Processing Unit

**Definition**: Specialized processor for graphics and parallel computation

**Usage**: Hardware acceleration
- Drivers: NVIDIA, AMD, Intel
- Module: modules/graphics/

**Evidence**: modules/graphics/, README.md:45

### VM
**Expansion**: Virtual Machine

**Definition**: Emulated computer system

**Usage**: Testing and virtualization
- Tech: QEMU, KVM
- Module: modules/virtualisation/

**Evidence**: modules/virtualisation/, runbook.md (VM testing)

### PAM
**Expansion**: Pluggable Authentication Modules

**Definition**: Authentication framework for Unix systems

**Usage**: System authentication
- Context: User login, sudo

**Evidence**: UNIX system fundamentals

### UEFI
**Expansion**: Unified Extensible Firmware Interface

**Definition**: Modern firmware interface (replacement for BIOS)

**Usage**: Secure Boot support
- Integration: Lanzaboote

**Evidence**: flake.nix:42-48 (lanzaboote)

## Business Concepts

### Library/Framework
**Definition**: A collection of reusable components for building systems (NOT an end-user application)

**Technical Representation**: Nix flake with modules, packages, and helper functions
- Entry: User imports as flake input
- Usage: User composes modules in their own configuration

**Evidence**: .claude/project.md:1, README.md:13

### Module Composition
**Definition**: Pattern of combining independent modules to build complete systems

**Technical Representation**: User's flake.nix imports multiple axiOS modules
- Independence: Modules don't depend on each other
- Flexibility: Enable only what's needed

**Evidence**: Constitution.md ADR-001

### Self-Hosted Services
**Definition**: Services run on user's own hardware (vs. cloud SaaS)

**Technical Representation**: Immich, Caddy services configured locally
- Control: User owns data
- Privacy: Data stays local

**Evidence**: README.md:60, modules/services/

### Declarative Configuration
**Definition**: System configuration specified as desired state (vs. imperative commands)

**Technical Representation**: Nix expressions define complete system
- Reproducible: Same config = same system
- Versioned: Git-tracked configuration

**Evidence**: NixOS fundamental concept

## NixOS-Specific Terms

### nixpkgs
**Definition**: The Nix packages collection - repository of ~80,000 packages

**Context**: Primary package source
- Channel: unstable (axiOS uses latest)
- URL: github:NixOS/nixpkgs/nixpkgs-unstable

**Related Terms**: Package, Nix

**Evidence**: flake.nix:7

### nixpkgs-unstable
**Definition**: Rolling release channel of nixpkgs with latest packages

**Context**: Bleeding edge packages (vs. stable channel)
- Trade-off: Latest features vs. potential breakage
- axiOS choice: Unstable for modern packages

**Evidence**: flake.nix:7

### System Rebuild
**Definition**: Process of building and activating a new NixOS configuration

**Context**: Apply configuration changes
- Command: `nixos-rebuild switch`
- Atomic: Old generation preserved

**Related Terms**: NixOS Generation, Activation

**Evidence**: Runbook.md operations

### Content-Addressed Storage
**Definition**: Storage system where content location is determined by its cryptographic hash

**Context**: Nix store design
- Path: Hash of build inputs + outputs
- Integrity: Tampering changes hash

**Related Terms**: Nix Store, Hash

**Evidence**: Nix fundamental concept

### flake-parts
**Definition**: Framework for organizing Nix flakes with modular structure

**Context**: Flake organization tool
- Usage: axiOS uses for clean flake structure
- Benefit: Compose flake outputs from multiple files

**Evidence**: flake.nix:13-16

## Deprecated Terms

### dms-cli Input
**Status**: Deprecated as of v2025.11.19

**Replaced By**: DMS packages dmsCli directly

**Migration**: Removed input, DMS NixOS module provides tools

**Evidence**: CHANGELOG.md:38-40

### ollama Module
**Status**: Deprecated/Removed

**Replaced By**: None (deemed overly opinionated)

**Migration**: Users should configure ollama directly if needed

**Evidence**: CHANGELOG.md mentions removal

## Term Relationships

### Hierarchies
- **NixOS Configuration**
  - **System Modules** (modules/)
    - Enable Options
    - Configuration
  - **Home Modules** (home/)
    - User Environment
    - Dotfiles
- **Flake**
  - **Inputs** (dependencies)
  - **Outputs** (exports)
    - Modules
    - Packages
    - Apps
    - DevShells

### Synonyms
- **Flake Input** = **Dependency** (in flake context)
- **Module** = **Configuration Unit** (in NixOS context)
- **Substituter** = **Binary Cache** (Nix terminology)

## Common Abbreviations in Code

- `cfg`: Configuration variable (module option values)
- `pkgs`: Package set (nixpkgs)
- `lib`: NixOS library functions
- `osConfig`: System configuration (in home-manager)
- `inputs`: Flake inputs
- `self`: Current flake
- `system`: Target system architecture (deprecated, use `pkgs.stdenv.hostPlatform.system`)

## Unknowns
- [TBD] Complete MCP server inventory and capabilities
- [TBD] All Niri compositor configuration options
- [TBD] Complete DMS widget set
- [TBD] Gaming module package list
- [TBD] Virtualization module container runtime specifics
