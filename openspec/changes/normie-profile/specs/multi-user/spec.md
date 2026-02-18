## MODIFIED Requirements

### Requirement: homeProfile enum and resolution

The `homeProfile` option SHALL use the enum `"standard"` | `"normie"` for both per-user and host-level profile selection. The host-level default SHALL be `"standard"`.

#### Scenario: User with explicit normie profile

- **WHEN** `axios.users.users.traci.homeProfile = "normie"` is set
- **AND** the host's `homeProfile` is `"standard"`
- **THEN** Traci's home-manager imports the normie profile module
- **AND** other users without explicit `homeProfile` inherit the host's `"standard"` profile

#### Scenario: User inherits host default

- **WHEN** `axios.users.users.keith.homeProfile` is null (default)
- **AND** the host's `homeProfile` is `"standard"`
- **THEN** Keith's home-manager imports the standard profile module

#### Scenario: Host default is normie

- **WHEN** the host's `homeProfile` is `"normie"`
- **AND** a user has `homeProfile = null`
- **THEN** that user gets the normie profile

#### Scenario: Profile resolution in lib/default.nix

- **WHEN** `buildModules` resolves per-user profiles
- **THEN** `profile = hostCfg.homeProfile or "standard"` is used as the default
- **AND** `"standard"` maps to `self.homeModules.standard`
- **AND** `"normie"` maps to `self.homeModules.normie`

## REMOVED Requirements

### Requirement: workstation/laptop/minimal homeProfile values
**Reason**: Consolidated into `"standard"` (replaces workstation and laptop) and `"normie"` (new). The only difference between workstation and laptop was Solaar autostart, which is now hardware-conditional. The `"minimal"` value was defined in the enum but never implemented.
