# Operations & Deployment

## Purpose
Defines the procedures for system installation, automated validation, and continuous integration.

## Components

### Installation (Init Script)
- **Tool**: `nix run .#init`
- **Pattern**: Uses `hardwareConfigPath` to reference the system's `hardware-configuration.nix` directly, avoiding the fragile extraction of boot/filesystem settings.
- **Support**: Secure Boot enrollment guidance and UEFI-only partitioning.
- **Implementation**: `scripts/init-config.sh`

### Continuous Integration (GitHub Actions)
- **Flake Check**: Validates flake structure and buildable outputs.
- **Formatting**: Enforces `nixfmt-rfc-style` on all Nix files.
- **DevShell Builds**: Ensures all development shells remain buildable.
- **Lock Updater**: Weekly automated dependency updates with PR generation.
- **Implementation**: `.github/workflows/`

### Deployment Patterns
- **Library Model**: axiOS is exported as a flake library. Downstream hosts import modules and call `mkSystem`.
- **Secrets Management**:
    - `agenix`: System-level secrets (SSH keys, config files).
    - Session Variables: AI API keys (Brave, GitHub).
- **Implementation**: `lib/default.nix`, `modules/secrets/`

## Procedures
- **Formatting**: Always run `nix fmt .` before committing.
- **Testing**: Use `./scripts/test-build.sh` for local validation of heavy changes.
- **Conventional Commits**: All PRs and commits should follow standard git conventions.
