## 1. Profile Enum and Resolution

- [x] 1.1 Update `modules/users.nix` homeProfile enum from `"workstation" | "laptop" | "minimal"` to `"standard" | "normie"`
- [x] 1.2 Update `lib/default.nix` default profile from `"workstation"` to `"standard"` (`profile = hostCfg.homeProfile or "standard"`)
- [x] 1.3 Update `lib/default.nix` per-user profile resolution to map `"standard"` → `self.homeModules.standard` and `"normie"` → `self.homeModules.normie`
- [x] 1.4 Register `standard` and `normie` in `home/default.nix` homeModules; remove `workstation` and `laptop`

## 2. Standard Profile (Workstation/Laptop Consolidation)

- [x] 2.1 Create `home/profiles/standard.nix` — imports `base.nix` and `../desktop` (same as current workstation minus Solaar)
- [x] 2.2 Move Solaar autostart from `home/profiles/workstation.nix` into `home/desktop/default.nix` conditional on `osConfig.hardware.logitech.wireless.enableGraphical or false`
- [x] 2.3 Delete `home/profiles/workstation.nix` and `home/profiles/laptop.nix`

## 3. Normie Desktop Module

- [x] 3.1 Create `home/desktop/normie.nix` — imports theming, wallpaper, pwa-apps, mpv, Niri home module, DMS home modules; configures DMS, MIME associations, Flatpak, gnome-keyring, KDE Connect; sets `prefer-no-csd = false`; configures spawn-at-startup WITHOUT cairn-help and WITHOUT drop-down terminal
- [x] 3.2 Create `home/desktop/niri-keybinds-normie.nix` — only `Mod+Q` (close), `Mod+F` (maximize), `Print` (screenshot); no tiling, workspace, dev, or app launcher bindings
- [x] 3.3 Create `home/profiles/normie.nix` — imports `base.nix` and `../desktop/normie.nix`
- [x] 3.4 Add Solaar autostart to normie.nix conditional on `osConfig.hardware.logitech.wireless.enableGraphical or false` (same as standard)

## 4. AI Module Per-Profile Gating

- [x] 4.1 Remove `self.homeModules.ai` from universal `sharedModules` in `lib/default.nix`
- [x] 4.2 Add AI home module import to standard profile only — either in the per-user profile wiring block (conditional on resolved profile being `"standard"`) or as an import in the standard profile module

## 5. Init Script and Templates

- [x] 5.1 Update `scripts/init-config.sh` `compute_derived()` — remove `HOME_PROFILE` derivation from form factor; set host-level `homeProfile` to `"standard"`
- [x] 5.2 Add per-user profile prompt in `collect_primary_user()` — ask "Profile? (standard / normie)" with standard as default; store in user config
- [x] 5.3 Add per-user profile prompt in `collect_additional_users()` — same prompt for each additional user
- [x] 5.4 Update `generate_user_file()` to emit `homeProfile = "<selection>"` in the generated user .nix file
- [x] 5.5 Update `scripts/templates/host.nix.template` — change `homeProfile = "{{HOME_PROFILE}}"` to `homeProfile = "standard"` (static default)
- [x] 5.6 Update `scripts/templates/ai-install-prompt.md.template` — replace workstation/laptop references with standard/normie
- [x] 5.7 Update `scripts/templates/README.md.template` — replace `{{HOME_PROFILE}}` with new profile names

## 6. Formatting and Validation

- [x] 6.1 Run `nix fmt .` on all modified/created Nix files
- [x] 6.2 Verify `nix flake check --all-systems` passes
