## 1. Module Scaffolding

- [x] 1.1 Create `modules/syncthing/default.nix` with module options: `axios.syncthing.enable`, `axios.syncthing.user`, `axios.syncthing.devices` (attrsOf submodule with `id`, `tailscaleName`, `addresses`), and `axios.syncthing.folders` (attrsOf submodule with `devices`, `pathOverride`, `ignorePatterns`; name constrained to XDG enum)
- [x] 1.2 Register module in `modules/default.nix`: add `syncthing = ./syncthing;` to `flake.nixosModules`

## 2. Core Implementation

- [x] 2.1 Implement XDG name-to-path resolution lookup table mapping folder names (`documents`, `music`, `pictures`, `videos`, `downloads`, `templates`, `desktop`, `publicshare`) to paths relative to user's home directory, with `pathOverride` support
- [x] 2.2 Implement `config` block: map `axios.syncthing` options to `services.syncthing` settings — set `user`, `group`, `dataDir`, `configDir`, and `settings.options` (disable global/local announce, relays, NAT)
- [x] 2.3 Implement device mapping: transform `axios.syncthing.devices` to `services.syncthing.settings.devices` with MagicDNS address derivation (`tcp://<name>.<tailscale-domain>:22000`), supporting `tailscaleName` override and `addresses` escape hatch
- [x] 2.4 Implement folder mapping: transform `axios.syncthing.folders` to `services.syncthing.settings.folders` with resolved XDG paths and device associations
- [x] 2.5 Add assertions: `axios.syncthing.user` must be set when module is enabled; `networking.tailscale.domain` must be set when any device uses MagicDNS addressing (no explicit `addresses` override)

## 3. Module Registration

- [x] 3.1 Add `syncthing` to `flaggedModules` in `lib/default.nix`: `++ lib.optional (hostCfg.modules.syncthing or false) syncthing`
- [x] 3.2 Add auto-enable wiring in `lib/default.nix` hostModule `dynamicConfig`: `(lib.optionalAttrs (hostCfg.modules.syncthing or false) { axios.syncthing.enable = true; })`

## 4. Remove Google Drive Sync

- [x] 4.1 Delete `home/desktop/gdrive-sync.nix`
- [x] 4.2 Remove gdrive-sync import from `home/desktop/default.nix`

## 5. Formatting and Validation

- [x] 5.1 Run `nix fmt .` to format all modified Nix files
- [x] 5.2 Run `nix flake check --all-systems` to validate the flake structure
