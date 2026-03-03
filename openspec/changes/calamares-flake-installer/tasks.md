## Phase 1: MVP Job Module + ISO Build

### 1. Package Scaffold

- [x] 1.1 Create `pkgs/calamares-axios-extensions/package.nix` derivation with `src = ./src`, install phases for modules/config/branding, `@out@` and `@glibcLocales@` substitution
- [x] 1.2 Create directory structure: `src/modules/axios/`, `src/config/`, `src/config/modules/`, `src/branding/axios/`
- [x] 1.3 Create `src/modules/axios/module.desc` (type: job, interface: python, script: main.py)
- [x] 1.4 Register package in `pkgs/default.nix` (or flake.nix overlay)

### 2. Settings and Module Configs

- [x] 2.1 Create `src/config/settings.conf` with modified sequence (welcome, locale, keyboard, users, unfree, partition, summary → partition, mount, axios, users, umount → finished). Use `@out@` for modules-search path
- [x] 2.2 Copy/adapt module configs from upstream nixpkgs vendored source: `welcome.conf`, `locale.conf` (with `@glibcLocales@`), `keyboard.conf`, `users.conf`, `partition.conf`, `mount.conf`, `finished.conf`
- [x] 2.3 Create `src/config/modules/unfree.conf` pointing to branding QML
- [x] 2.4 Create `src/branding/axios/branding.desc` with axiOS branding metadata

### 3. Unfree QML Page

- [x] 3.1 Create `src/branding/axios/notesqml@unfree.qml` — port from upstream NixOS branding (checkbox writing `nixos_allow_unfree` to globalstorage)

### 4. Config Generation Job (axios/main.py)

- [x] 4.1 Create `src/modules/axios/main.py` with `run()` function reading standard globalstorage keys: `rootMountPoint`, `hostname`, `username`, `fullname`, `locationRegion`, `locationZone`, `localeConf`, `keyboardLayout`, `keyboardVariant`, `firmwareType`, `bootLoader`, `partitions`, `nixos_allow_unfree`, `autoLoginUser`
- [x] 4.2 Implement `flake.nix` template with `@@variable@@` substitution — single input `axios`, `mkHost` helper, `nixosConfigurations.<hostname>`
- [x] 4.3 Implement `hosts/<hostname>.nix` template — `hostConfig` with hostname, hardware (cpu/gpu hardcoded for MVP), formFactor, modules with sensible defaults, timezone, locale, keyboard in extraConfig
- [x] 4.4 Implement `users/<username>.nix` template — `axios.users.users.<name>` with fullName, isAdmin, homeProfile
- [x] 4.5 Run `nixos-generate-config --root <mountpoint>` and move output to `hosts/<hostname>/hardware.nix`
- [x] 4.6 Handle btrfs subvolume fixup in hardware-configuration.nix (port from upstream `nixos/main.py`)
- [x] 4.7 Handle unfree kernel module stripping from hardware-configuration.nix when unfree disabled (port from upstream)
- [x] 4.8 Copy pre-baked `flake.lock` from extensions package to target `/etc/nixos/flake.lock`
- [x] 4.9 Run `nixos-install --no-root-passwd --root <mountpoint> --flake <mountpoint>/etc/nixos#<hostname> --option build-dir /nix/var/nix/builds` with progress streaming
- [x] 4.10 Implement proxy forwarding (HTTP_PROXY, HTTPS_PROXY) matching upstream pattern

### 5. Pre-baked flake.lock

- [x] 5.1 Generate `flake.lock` at package build time using `self.rev` / `self.narHash`, embedding as `src/modules/axios/flake.lock.template` or generating in `postInstall`
- [x] 5.2 Handle `self.rev = null` case (dirty builds) — fail with clear error message requiring clean checkout for ISO builds, or fall back to `self.dirtyRev`

### 6. ISO Module

- [x] 6.1 Create `modules/installer/default.nix` — import `installation-cd-graphical-base.nix`, add calamares-nixos + calamares-axios-extensions + autostart + glibcLocales
- [x] 6.2 Register installer module in `modules/default.nix`
- [x] 6.3 Add ISO nixosConfiguration in flake.nix (or expose via lib helper)
- [ ] 6.4 Verify ISO builds with `nix build` (requires commit + actual build)

### 7. VM Testing

- [ ] 7.1 Boot ISO in QEMU/libvirt VM
- [ ] 7.2 Run Calamares installer end-to-end — verify generated flake structure is correct
- [ ] 7.3 Verify installed system boots and is functional
- [ ] 7.4 Verify `nixos-rebuild switch --flake /etc/nixos#<hostname>` works post-install

---

## Phase 2: axiOS Config QML Page

### 8. Hardware Auto-Detection Job

- [ ] 8.1 Create `src/modules/axiosdetect/module.desc` (type: job, interface: python)
- [ ] 8.2 Create `src/modules/axiosdetect/main.py` — detect CPU vendor from `/proc/cpuinfo`, GPU vendor from `lspci`, form factor from battery presence, SSD from rotational flag
- [ ] 8.3 Write detected values to globalstorage: `axios_cpuVendor`, `axios_gpuVendor`, `axios_formFactor`, `axios_hasSSD`
- [ ] 8.4 Add `axiosdetect` to settings.conf sequence (before show phase)

### 9. axiOS Config QML Page

- [ ] 9.1 Create `src/config/modules/axiosconfig.conf` — notesqml instance config pointing to branding QML
- [ ] 9.2 Register `notesqml@axiosconfig` instance in `settings.conf`
- [ ] 9.3 Create `src/branding/axios/notesqml@axiosconfig.qml` — profile selection (standard/normie) with conditional feature visibility
- [ ] 9.4 Implement hardware confirmation section — display auto-detected values from globalstorage with override controls (radio buttons for CPU/GPU/formFactor)
- [ ] 9.5 Implement feature toggles section (visible only when standard selected) — checkboxes for gaming, PIM, Immich, Local LLM, Secure Boot, Secrets, Libvirt, Containers
- [ ] 9.6 Implement conditional sub-options — server/client role selectors for PIM, Immich, Local LLM (visible when parent enabled)
- [ ] 9.7 Implement tailnet domain text input (visible when any client role selected)
- [ ] 9.8 Write all values to globalstorage via `Global.insert()`

### 10. Wire QML Values into Config Generation

- [ ] 10.1 Update `axios/main.py` to read `axios_*` globalstorage keys
- [ ] 10.2 Map `axios_homeProfile` to user template `homeProfile` field
- [ ] 10.3 Map `axios_cpuVendor`, `axios_gpuVendor`, `axios_formFactor`, `axios_hasSSD` to `hostConfig.hardware.*` fields
- [ ] 10.4 Map feature toggles to `hostConfig.modules.*` flags
- [ ] 10.5 Map server/client roles and tailnet domain to `hostConfig.extraConfig`
- [ ] 10.6 Handle normie defaults — when profile is normie, set all optional modules to false regardless of globalstorage

---

## Phase 3: Polish

### 11. Branding

- [ ] 11.1 Create axiOS branding assets (logo, sidebar image, slideshow images)
- [ ] 11.2 Create `src/branding/axios/show.qml` — install slideshow with axiOS feature highlights
- [ ] 11.3 Update `branding.desc` with axiOS name, description, URLs, image paths

### 12. Validation

- [ ] 12.1 Run `nix fmt .` on all modified Nix files
- [ ] 12.2 Run `nix flake check` to validate flake structure
- [ ] 12.3 Full end-to-end VM test: ISO boot → Calamares → install → reboot → working system → nixos-rebuild
