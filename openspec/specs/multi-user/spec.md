# Multi-user Support

## Purpose
Provides the multi-user interface for axiOS, replacing the singular `axios.user` with a scalable `axios.users.users.<name>` submodule system. Enables hosts to declare multiple users with per-user configuration, admin controls, and home-manager profile selection.

## Components

### Multi-user Definitions via axios.users
- **Implementation**: `modules/users.nix`
- **Options**: `axios.users.users.<name>` (attrsOf submodule) with:
  - `fullName` (string, required) — User's display name
  - `email` (string, default `""`) — Email address for git config and tools
  - `isAdmin` (bool, default `false`) — Controls sudo/wheel access and nix trusted-users
  - `homeProfile` (enum: `"standard"`, `"normie"`, or `null`, default `null`) — Per-user home-manager profile; null inherits the host's `homeProfile`
  - `extraGroups` (list of strings, default `[]`) — Additional groups beyond auto-assigned ones

For each user defined in `axios.users.users`, the system automatically:
1. Creates a `users.users.<name>` account with `isNormalUser = true`
2. Sets the user's `description` to `fullName`
3. Assigns groups from `axios.users.defaultExtraGroups`, excluding `wheel` if `isAdmin = false`, plus any user-specific `extraGroups`
4. Creates XDG directories (Desktop, Documents, Downloads, Music, Pictures, Videos, Public, Templates)
5. Configures `home-manager.users.<name>` with the user's email and appropriate profile modules
6. Adds admin users to `nix.settings.trusted-users`

### Host-user Association by Name
- **Implementation**: `lib/default.nix` (mkSystem/buildModules)
- **Mechanism**: Host configurations declare a `users` attribute containing a list of username strings. The `mkSystem` function accepts a `configDir` attribute (the downstream flake's `self.outPath`) and resolves each username to the module path `configDir + "/users/<name>.nix"`. These modules are imported into the NixOS configuration automatically.

### Canonical Downstream Config Structure
axiOS prescribes the following directory structure for downstream configurations:
```
<config-dir>/
├── flake.nix
├── users/<username>.nix     (one per user)
├── hosts/<hostname>.nix     (one per host)
├── hosts/<hostname>/hardware.nix
├── secrets/                 (optional)
└── .gitignore
```
The init script generates this structure. Documentation references this as the required layout.

## Requirements

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

## Migration from Singular Interface

### Removed: axios.user options
**Reason**: Replaced by `axios.users.users.<name>` multi-user interface. The singular model forced multi-user hosts to bypass the framework entirely.
**Migration**: Replace `axios.user = { name = "keith"; fullName = "Keith"; email = "k@example.com"; }` with a `users/keith.nix` file containing `axios.users.users.keith = { fullName = "Keith"; email = "k@example.com"; isAdmin = true; }`. Update host config to include `users = [ "keith" ]`.

### Removed: userModulePath in host config
**Reason**: Replaced by `users` list + `configDir` resolution. The stringly-typed path wiring was error-prone and didn't support multiple users.
**Migration**: Remove `userModulePath` from host config. Add `users = [ "username" ]` list. Ensure flake passes `configDir = self.outPath` to `mkSystem`.

### Removed: workstation/laptop/minimal homeProfile values
**Reason**: Consolidated into `"standard"` (replaces workstation and laptop) and `"normie"` (new). The only difference between workstation and laptop was Solaar autostart, which is now hardware-conditional. The `"minimal"` value was defined in the enum but never implemented.
