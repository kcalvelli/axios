## MODIFIED Requirements

### Requirement: System Monitoring Tools

The system module SHALL provide btop as the standard system monitor, replacing gtop. htop SHALL be retained as a lightweight fallback for constrained environments (SSH, recovery, minimal terminals).

#### Scenario: System module provides btop instead of gtop
- **WHEN** `axios.system.enable = true`
- **THEN** `environment.systemPackages` MUST contain btop
- **AND** `environment.systemPackages` MUST NOT contain gtop

#### Scenario: htop retained as lightweight fallback
- **WHEN** `axios.system.enable = true`
- **THEN** `environment.systemPackages` MUST contain htop

### Requirement: Cachix CLI conditional on system enable

The cachix CLI package SHALL be installed inside the `lib.mkIf config.axios.system.enable` guard, not unconditionally. Cache substituters are configured separately and work without the CLI binary.

#### Scenario: Cachix installed conditionally
- **WHEN** `axios.system.enable = true`
- **THEN** cachix MUST be available in `environment.systemPackages`

#### Scenario: Cachix not installed when system disabled
- **WHEN** `axios.system.enable = false`
- **THEN** cachix MUST NOT be in `environment.systemPackages`
