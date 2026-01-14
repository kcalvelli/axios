# Project: axiOS

## Goal
axiOS provides a modular NixOS framework and library for building reproducible NixOS systems with modern desktop environments, development tools, and curated configurations - enabling users to maintain simple configurations while axiOS handles system complexity.

## System Overview
axiOS is a Nix flake library that provides reusable NixOS and home-manager modules for building customized NixOS systems. Rather than being an end-user distribution, it functions as a framework that downstream users import into their own flake configurations.

The project emphasizes modularity, reproducibility, and user control - providing opinionated defaults while allowing complete customization. Users maintain minimal configuration files (typically ~30-60 lines) while axiOS provides comprehensive system configuration including desktop environments, development tools, networking, security, and services.

axiOS is NOT a personal configuration repository - it's a library designed for multiple users with different needs, avoiding hardcoded personal or regional preferences.

## User Types
1. **NixOS Configuration Maintainers**: Primary users who import axiOS into their own flake configurations to build customized NixOS systems
2. **Module Developers**: Contributors who extend axiOS by adding new modules or improving existing ones
3. **Home Lab Enthusiasts**: Users who leverage self-hosted services (Immich, Caddy, Tailscale integration)
4. **Developers**: Users who benefit from pre-configured development environments and tools
5. **Desktop Users**: Users seeking a polished Wayland desktop experience with Niri and DankMaterialShell

## Tech Stack
- **Languages**: Nix (primary), Bash (helper scripts)
- **Frameworks**: NixOS, home-manager, flake-parts
- **Tools**: Nix flakes, nixfmt-rfc-style, devshell, agenix, lanzaboote

## Constitution & Non-Negotiable Rules

### Philosophy
- **Library First**: This is a library/framework, NOT a personal configuration.
- **Independence**: Modules MUST be independently importable and free of inter-module dependencies.
- **Conditional Evaluation**: All packages/configs MUST be inside `lib.mkIf cfg.enable { ... }` blocks.
- **No Regional Defaults**: Timezones and locales must be explicitly configured by the user.

### Code Style
- **Formatter**: `nixfmt-rfc-style` (enforced via `nix fmt .`).
- **Naming**: Kebab-case for files, camelCase for options and variables.
- **Structure**: Directory-based modules with `default.nix`.

### Architectural Decision Records (Key Summary)
- **ADR-004**: Use `pkgs.stdenv.hostPlatform.system` instead of `system`.
- **ADR-007**: Services register reverse proxy routes via `selfHosted.caddy.routes.<name>`.
- **ADR-008**: ALL flake inputs MUST follow the main nixpkgs input (`follows = "nixpkgs"`).

### Security & Documentation
- **Sanitization**: Documentation and examples MUST NOT expose personal or sensitive information (domains, hostnames, network IDs). Use placeholders like `example-tailnet.ts.net`.
