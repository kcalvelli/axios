## MODIFIED Requirements

### Requirement: User Management
- **Implementation**: `modules/users.nix`
- **Options**: `axios.users.<name>.{fullName, email, isAdmin, homeProfile, extraGroups}` — multi-user interface with per-user submodules.
- **Features**: Automatic group membership based on enabled modules with admin/non-admin distinction via `isAdmin` flag. Per-user home-manager profile selection (workstation/laptop/minimal/null). XDG directory creation for all defined users. Admin users added to `nix.settings.trusted-users`. User modules resolved from canonical `users/<name>.nix` structure via `configDir`.
- **Removed**: `axios.user.name`, `axios.user.fullName`, `axios.user.email` (singular interface), `userModulePath` (stringly-typed path wiring).

#### Scenario: Multi-user host configuration
- **WHEN** a host defines multiple users via `axios.users` with different admin levels and home profiles
- **THEN** each user gets appropriate system account, groups (with/without wheel), per-user home-manager profile imports, and XDG directories

#### Scenario: Host declares users by name
- **WHEN** a host config contains `users = [ "keith" "traci" ]` and `configDir` is provided
- **THEN** `mkSystem` imports `users/keith.nix` and `users/traci.nix` from the config directory and wires them into the NixOS configuration

## ADDED Requirements

### Requirement: Systematic DMS placeholder generation
The desktop module SHALL maintain an authoritative list of all DMS (dankMaterialShell) KDL configuration files that niri's config includes via `include` directives. For each file in this list, the system SHALL create an empty placeholder file at `~/.config/niri/dms/<name>.kdl` via home-manager if the file does not already exist. This ensures the niri compositor can start successfully on first boot before DMS has generated its configuration.

#### Scenario: Fresh install first boot
- **WHEN** a new system boots for the first time with the desktop module enabled and DMS has never run
- **THEN** all DMS KDL placeholder files exist at `~/.config/niri/dms/` and niri starts without `include` errors

#### Scenario: DMS has already generated configs
- **WHEN** DMS has previously run and populated `~/.config/niri/dms/*.kdl` with real content
- **THEN** the placeholder mechanism does not overwrite existing DMS-generated files

#### Scenario: DMS adds new config files in a future version
- **WHEN** a new version of DMS introduces additional KDL include files
- **THEN** updating the authoritative list in axiOS and rebuilding creates the new placeholders

### Requirement: Init script multi-user support
The init script (`nix run .#init`) SHALL support creating configurations for multiple users. After gathering the primary user's information (marked as admin), the script SHALL prompt whether to add additional users. For each additional user, it SHALL collect username, full name, email, and admin status. The script SHALL generate individual `users/<username>.nix` files using the `axios.users.<name>` format and a `flake.nix` that uses the canonical `mkHost` pattern with `configDir`.

#### Scenario: Single user setup
- **WHEN** the user runs `nix run .#init` and declines to add additional users
- **THEN** the script generates `users/<username>.nix` with `isAdmin = true` and a `flake.nix` using the canonical pattern

#### Scenario: Multi-user setup
- **WHEN** the user adds 3 additional users during init
- **THEN** the script generates 4 `users/<username>.nix` files and a host config with `users = [ "primary" "user2" "user3" "user4" ]`

#### Scenario: Additional user as non-admin
- **WHEN** an additional user is added with admin = no
- **THEN** the generated `users/<username>.nix` sets `isAdmin = false`

### Requirement: Init script hardware pre-flight validation
The init script SHALL perform hardware compatibility checks after gathering configuration and before generating files. It SHALL warn about known issues including NVIDIA GPU with kernel >= 6.19. Warnings SHALL be informational (not blocking) and include suggested workarounds.

#### Scenario: NVIDIA GPU detected with known kernel incompatibility
- **WHEN** the init script detects an NVIDIA GPU and the running kernel is >= 6.19
- **THEN** the script displays a warning about NVIDIA driver incompatibility and notes that axiOS will pin the kernel to 6.18

#### Scenario: All hardware checks pass
- **WHEN** no known hardware issues are detected
- **THEN** the script proceeds without warnings
