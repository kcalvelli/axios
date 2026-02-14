## ADDED Requirements

### Requirement: Multi-user definitions via axios.users
The system SHALL provide an `axios.users` option of type `attrsOf submodule` where each attribute key is a username and the value is a submodule with the following options:
- `fullName` (string, required) — User's display name
- `email` (string, default `""`) — Email address for git config and tools
- `isAdmin` (bool, default `false`) — Controls sudo/wheel access and nix trusted-users
- `homeProfile` (enum: `"workstation"`, `"laptop"`, `"minimal"`, or `null`, default `null`) — Per-user home-manager profile; null inherits the host's `homeProfile`
- `extraGroups` (list of strings, default `[]`) — Additional groups beyond auto-assigned ones

For each user defined in `axios.users`, the system SHALL automatically:
1. Create a `users.users.<name>` account with `isNormalUser = true`
2. Set the user's `description` to `fullName`
3. Assign groups from `axios.users.defaultExtraGroups`, excluding `wheel` if `isAdmin = false`, plus any user-specific `extraGroups`
4. Create XDG directories (Desktop, Documents, Downloads, Music, Pictures, Videos, Public, Templates)
5. Configure `home-manager.users.<name>` with the user's email and appropriate profile modules
6. Add admin users to `nix.settings.trusted-users`

#### Scenario: Single admin user
- **WHEN** `axios.users.keith = { fullName = "Keith"; email = "k@example.com"; isAdmin = true; }` is set
- **THEN** the system creates `users.users.keith` with `isNormalUser = true`, `description = "Keith"`, `extraGroups` including `wheel` and all module-based groups, adds `keith` to `nix.settings.trusted-users`, and configures `home-manager.users.keith` with email and host profile modules

#### Scenario: Multiple users with mixed admin status
- **WHEN** `axios.users` contains `keith = { isAdmin = true; ... }` and `traci = { isAdmin = false; ... }`
- **THEN** keith receives `wheel` in extraGroups and traci does not; both receive all other module-based groups; only keith appears in `nix.settings.trusted-users`

#### Scenario: Per-user home profile override
- **WHEN** host `homeProfile = "workstation"` and `axios.users.henry = { homeProfile = "minimal"; ... }`
- **THEN** henry's `home-manager.users.henry` imports the minimal profile modules, not the workstation modules; other users with `homeProfile = null` inherit workstation

#### Scenario: No users defined
- **WHEN** `axios.users` is empty (`{}`)
- **THEN** no user accounts are automatically created by the users module

### Requirement: Host-user association by name
Host configurations SHALL declare a `users` attribute containing a list of username strings. The `mkSystem` function SHALL accept a `configDir` attribute (the downstream flake's `self.outPath`) and resolve each username to the module path `configDir + "/users/<name>.nix"`. These modules SHALL be imported into the NixOS configuration automatically.

#### Scenario: Host with three users
- **WHEN** a host config specifies `users = [ "keith" "traci" "henry" ]` and `configDir` points to the downstream flake
- **THEN** `mkSystem` imports `<configDir>/users/keith.nix`, `<configDir>/users/traci.nix`, and `<configDir>/users/henry.nix` as NixOS modules

#### Scenario: Host with single user
- **WHEN** a host config specifies `users = [ "keith" ]`
- **THEN** only `<configDir>/users/keith.nix` is imported

#### Scenario: Missing user file
- **WHEN** a host config references `users = [ "nonexistent" ]` and `<configDir>/users/nonexistent.nix` does not exist
- **THEN** Nix evaluation fails with a clear error indicating the missing user file path

### Requirement: Canonical downstream config structure
axiOS SHALL prescribe the following directory structure for downstream configurations:
```
<config-dir>/
├── flake.nix
├── users/<username>.nix     (one per user)
├── hosts/<hostname>.nix     (one per host)
├── hosts/<hostname>/hardware.nix
├── secrets/                 (optional)
└── .gitignore
```
The init script SHALL generate this structure. Documentation SHALL reference this as the required layout.

#### Scenario: Init script generates canonical structure
- **WHEN** a user runs `nix run .#init` and provides hostname, user info, and module selections
- **THEN** the script creates the prescribed directory layout with `users/`, `hosts/`, and optionally `secrets/` directories

#### Scenario: Multi-host config follows convention
- **WHEN** a downstream config has two hosts (edge, mini) with different user sets
- **THEN** each host's `.nix` file specifies its `users` list, and all referenced users have corresponding files in `users/`

## REMOVED Requirements

### Requirement: Singular axios.user options
**Reason**: Replaced by `axios.users.<name>` multi-user interface. The singular model forced multi-user hosts to bypass the framework entirely.
**Migration**: Replace `axios.user = { name = "keith"; fullName = "Keith"; email = "k@example.com"; }` with a `users/keith.nix` file containing `axios.users.keith = { fullName = "Keith"; email = "k@example.com"; isAdmin = true; }`. Update host config to include `users = [ "keith" ]`.

### Requirement: userModulePath in host config
**Reason**: Replaced by `users` list + `configDir` resolution. The stringly-typed path wiring was error-prone and didn't support multiple users.
**Migration**: Remove `userModulePath` from host config. Add `users = [ "username" ]` list. Ensure flake passes `configDir = self.outPath` to `mkSystem`.
