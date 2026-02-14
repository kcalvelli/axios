## Why

Yesterday's install of a new host with multiple users exposed critical gaps in the axiOS new-host experience. We pushed 6 hotfix commits to master — missing DMS placeholders, broken NVIDIA kernel module, missing AMD VA-API config, deprecated xorg references. The multi-user setup required a 196-line hand-rolled `users/mini.nix` that bypasses the `axios.user` framework entirely, with 3 copies of the same PWA config and manual group filtering.

The root cause is twofold: (1) axiOS has no multi-user model — `axios.user` supports exactly one user, forcing multi-user hosts to work around the framework; (2) axiOS doesn't prescribe how downstream configs should be structured — every host evolves its own wiring pattern, and `userModulePath` is a stringly-typed hack that breaks the moment you need more than one user.

This is a **breaking change** that establishes axiOS as a convention-over-configuration framework with a prescribed downstream config structure.

## What Changes

### Canonical Downstream Config Structure
- **BREAKING**: axiOS prescribes the following structure for all downstream configs:
  ```
  ~/.config/nixos_config/
  ├── flake.nix              # Uses axios-prescribed pattern
  ├── users/                 # One file per user, referenced by name
  │   ├── keith.nix          # axios.users.keith = { ... }
  │   └── traci.nix
  ├── hosts/                 # One file + directory per host
  │   ├── edge.nix           # hostConfig with users = [ "keith" ]
  │   ├── edge/
  │   │   └── hardware.nix   # Copy of hardware-configuration.nix
  │   ├── mini.nix           # hostConfig with users = [ "keith" "traci" ... ]
  │   └── mini/
  │       └── hardware.nix
  ├── secrets/               # Optional agenix secrets
  └── .gitignore
  ```

### Multi-User Management
- **BREAKING**: Replace `axios.user` (singular) with `axios.users.<name>` (attrset of user submodules)
- **BREAKING**: Remove `userModulePath` from host config — replaced by `users` (list of usernames) and `configDir` (flake self path); `mkSystem` resolves `users/<name>.nix` automatically
- Each user definition supports: `fullName`, `email`, `isAdmin` (controls wheel group), `homeProfile` (workstation/laptop/minimal), `extraGroups`
- Host configs declare `users = [ "keith" "traci" ]` — axiOS imports the corresponding user files
- Automatic group assignment per-user based on `isAdmin` and enabled system modules
- Per-user home-manager profile selection

### Init Script Overhaul
- Init script generates the canonical structure with `users/` directory
- Multi-user prompting: primary admin user + optional additional users
- Hardware pre-flight checks (NVIDIA kernel compat, etc.)
- Updated flake template with `configDir` pattern

### Fresh Install Robustness
- Systematic DMS placeholder generation from authoritative list
- All first-boot file-existence assumptions audited and fixed

## Capabilities

### New Capabilities
- `multi-user`: Multi-user management framework with per-user definitions, admin/non-admin roles, host-user association, and composable user modules resolved from canonical directory structure

### Modified Capabilities
- `system`: User management rebuilt around `axios.users.<name>` (removing `axios.user`); `mkSystem` gains `configDir` + `users` list resolution; init script generates canonical structure with multi-user support; DMS placeholder robustness

## Impact

- **BREAKING — modules/users.nix**: Complete rewrite — `axios.user` removed, `axios.users.<name>` submodule added
- **BREAKING — lib/default.nix**: `userModulePath` removed; `mkSystem` accepts `configDir` + resolves `users` list to module paths; per-user home profile wiring
- **BREAKING — scripts/init-config.sh**: Generates canonical structure with `users/` directory, multi-user flow, hardware pre-flight
- **BREAKING — scripts/templates/**: All templates rewritten for new structure
- **BREAKING — Downstream configs**: Must restructure to canonical layout — `user.nix` → `users/<name>.nix`, `userModulePath` → `users` list, `axios.user` → `axios.users`
- **home/desktop/niri-keybinds.nix**: Systematic DMS placeholder generation
- **openspec/specs/system/spec.md**: User management section rewritten
