## 1. Multi-User Module (modules/users.nix)

- [x] 1.1 Remove `axios.user` options (`name`, `fullName`, `email`) and all associated config logic
- [x] 1.2 Define `axios.users.<name>` as `attrsOf submodule` with options: `fullName` (str), `email` (str, default ""), `isAdmin` (bool, default false), `homeProfile` (enum "workstation"/"laptop"/"minimal"/null, default null), `extraGroups` (list of str)
- [x] 1.3 Implement per-user account creation: for each user in `axios.users`, create `users.users.<name>` with `isNormalUser = true`, `description = fullName`, and computed groups (module-auto-groups with `wheel` only for `isAdmin = true`, plus per-user `extraGroups`)
- [x] 1.4 Implement per-user XDG directory creation via `systemd.tmpfiles.rules` for all users in `axios.users`
- [x] 1.5 Implement per-user home-manager wiring: set `home-manager.users.<name>.axios.user.email` for each user
- [x] 1.6 Set `nix.settings.trusted-users` to list of usernames where `isAdmin = true`
- [x] 1.7 Keep `axios.users.autoGroups`, `axios.users.extraGroups`, and `axios.users.defaultExtraGroups` options (existing group computation logic stays)

## 2. Library Integration (lib/default.nix)

- [x] 2.1 Remove `userModulePath` handling from `buildModules` — delete the `userModule` variable and its inclusion in the module list
- [x] 2.2 Add `configDir` + `users` resolution: read `hostCfg.configDir` and `hostCfg.users`, construct `configDir + "/users/${name}.nix"` for each username, include as modules
- [x] 2.3 Implement per-user home profile wiring: for each user in `axios.users`, resolve their `homeProfile` (fall back to host `homeProfile` if null) and add appropriate profile modules to `home-manager.users.<name>.imports`
- [x] 2.4 Keep universal shared modules (secrets, AI, PIM, immich) in `home-manager.sharedModules` — these apply to all users regardless of profile
- [x] 2.5 Remove `userModulePath` from the `hostModule` function and from the final module list assembly
- [x] 2.6 Add validation assertion: if `hostCfg.users` is non-empty, `hostCfg.configDir` MUST be set

## 3. DMS Placeholder Robustness (home/desktop/)

- [x] 3.1 Define authoritative list of all DMS KDL config files in a single location (e.g., `home/desktop/dms.nix` or inline in `niri-keybinds.nix`): `alttab`, `binds`, `colors`, `cursor`, `layout`, `outputs`, `windowrules`, `wpblur`
- [x] 3.2 Generate `xdg.configFile."niri/dms/<name>.kdl"` empty placeholders for all files in the list, ensuring DMS-generated content takes precedence
- [x] 3.3 Remove existing hand-maintained individual placeholder entries and replace with list-driven generation
- [x] 3.4 Add comment referencing the DMS repo and explaining the placeholder pattern for future maintainers

## 4. Init Script & Templates (scripts/)

- [x] 4.1 Create new `user.nix.template` for per-user files using `axios.users.<name>` format with `fullName`, `email`, `isAdmin`, and `homeProfile` options
- [x] 4.2 Rewrite `flake.nix.template` with `mkHost` helper pattern: `configDir = self.outPath`, import host via `./hosts/${hostname}.nix`, support multiple hosts
- [x] 4.3 Rewrite `host.nix.template` to use `users = [ "{{USERNAME}}" ]` list instead of `userModulePath` parameter; remove function parameter for `userModulePath`
- [x] 4.4 Update `init-config.sh` to generate `users/<username>.nix` instead of root-level `user.nix`
- [x] 4.5 Add multi-user prompting loop to `init-config.sh`: after primary user, prompt "Add additional user? (y/n)", collect username/fullName/email/isAdmin for each
- [x] 4.6 Update `init-config.sh` to build the `users` list in the host config from all collected usernames
- [x] 4.7 Add hardware pre-flight checks to `init-config.sh`: detect NVIDIA GPU + kernel >= 6.19, display informational warning
- [x] 4.8 Remove generation of root-level `user.nix` (replaced by `users/` directory)

## 5. Example Configs Update

- [x] 5.1 Update any example configurations (minimal-flake, multi-host) referenced in CI to use the new canonical structure with `axios.users`, `configDir`, and `users` list
- [x] 5.2 Verify CI workflows (`flake-check.yml`) pass with updated example configs

## 6. Spec and Documentation Updates

- [x] 6.1 Update `openspec/specs/system/spec.md` User Management section with new multi-user interface
- [x] 6.2 Update `CLAUDE.md` and `.claude/project.md` with: new canonical config structure, `axios.users` pattern, `configDir` + `users` list in host configs, migration guide from old format
- [x] 6.3 Add downstream migration notes: step-by-step guide for converting `axios.user` → `axios.users`, `userModulePath` → `users` list, `user.nix` → `users/<name>.nix`

## 7. Validation and Formatting

- [x] 7.1 Run `nix fmt .` to format all modified Nix files
- [x] 7.2 Run `nix flake check --all-systems` to validate flake structure
- [ ] 7.3 Test with a sample canonical config: single-host single-user, single-host multi-user, multi-host with shared users
