# Development Tools

## Purpose
Provides pre-configured development environments and a modern terminal experience.

## Components

### Development Shells (env)
- **Environments**: Rust (Fenix), Zig, QML (Qt6), .NET 9.
- **Implementation**: `devshells/`, `devshells.nix`

### Terminal Experience
- **Emulator**: Ghostty (GPU accelerated).
- **Shell**: Fish with Starship prompt.
- **Tools**: bat, eza, fd, ripgrep (modern CLI replacements).
- **Implementation**: `home/terminal/`

### Configuration Generator
- **App**: `init` (nix run .#init).
- **Function**: Interactive configuration bootstrapping.
- **Implementation**: `scripts/init-config.sh`
