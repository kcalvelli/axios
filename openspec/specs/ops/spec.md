# Operational Procedures

## Purpose
Defines the lifecycle management, CI/CD pipelines, and maintenance workflows for axiOS.

## Procedures

### CI/CD Pipeline
- **Platform**: GitHub Actions.
- **Stages**:
  - `flake-check`: Structural validation.
  - `formatting`: Style check.
  - `test-init-script`: Functional validation of the bootstrap script.
- **Automation**: Weekly `flake.lock` updates every Monday at 6 AM UTC.

### Deployment
- **Method**: Atomic system rebuilds via `nixos-rebuild switch --flake .#hostname`.
- **Rollback**: Previous system generations accessible via GRUB/systemd-boot or `--rollback` flag.

### Maintenance
- **Secrets**: Managed via `agenix`. Public keys stored in `flake.nix`.
- **Cache**: Binary caching via Cachix (`niri`, `numtide`).

### Observability
- **Logging**: Accessed via `journalctl` or the `journal` MCP server.
- **Monitoring**: `claude-monitor` for AI session resource tracking.
