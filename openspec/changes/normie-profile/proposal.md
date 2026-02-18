## Why

Non-technical household members sharing an axiOS machine face an intimidating power-user desktop: 100+ keyboard shortcuts, tiling concepts (columns, consume/expel, workspaces), developer launchers, and AI tooling. They want what ChromeOS provides — a browser, apps, and familiar window controls. axiOS already has the building blocks (DMS shelf, 30+ PWAs, maximized-by-default windows) but no way to present a simplified surface per-user.

Separately, the laptop and workstation profiles are nearly identical — the only difference is Solaar autostart for Logitech devices, which should be hardware-conditional, not profile-conditional. Consolidating them simplifies the profile model and makes the normie/standard distinction the only meaningful axis.

## What Changes

- **Add `"normie"` home profile**: ChromeOS-like, mouse-driven desktop with window titlebars (CSD), DMS shelf, PWAs, and ~5 keybindings
- **Consolidate workstation + laptop into `"standard"`**: **BREAKING** — replace `"workstation"` and `"laptop"` profiles with a single `"standard"` profile. Move Solaar autostart to be hardware-conditional (when `hardware.desktop.enableLogitechSupport` is true) instead of profile-gated
- Remove the `"minimal"` enum value (was defined but never implemented)
- **New profile enum**: `"standard"` | `"normie"` (replaces `"workstation"` | `"laptop"` | `"minimal"`)
- Enable client-side decorations (`prefer-no-csd = false`) for normie profile so windows have close/minimize/maximize buttons
- Simplified keybinding set for normie: close window, app launcher, screenshots only — no tiling, workspace, or dev-tool bindings
- Exclude AI home modules from normie users by making AI imports profile-conditional instead of universal via `sharedModules`
- Suppress keybinding help overlay at startup for normie profile
- Retain for normie: DMS shell, theming, wallpaper, MIME associations, PWAs, Flatpak, mpv, KDE Connect, gnome-keyring
- **Update init script**: Replace form-factor-derived profile logic with per-user profile selection (standard vs normie); remove dead workstation/laptop derivation
- **Update templates**: Reflect new profile names in host.nix.template, ai-install-prompt.md.template, README.md.template

## Capabilities

### New Capabilities
- `normie-profile`: Defines the "normie" home profile — a simplified, mouse-driven desktop experience with window controls, DMS shelf, PWAs, and minimal keybindings. Covers profile composition, niri configuration overrides (CSD, simplified keybinds, no dev launchers), and inclusion/exclusion relative to the standard profile.

### Modified Capabilities
- `multi-user`: Replace homeProfile enum (`"workstation"` | `"laptop"` | `"minimal"`) with `"standard"` | `"normie"`. Update profile resolution, default value, and documentation.
- `desktop`: Document that normie profile uses a desktop subset (CSD enabled, simplified keybinds, no dev launchers, no drop-down terminal, no axios-help). Move Solaar autostart from workstation profile to hardware-conditional config.

## Impact

- **New files**: `home/profiles/normie.nix`, `home/profiles/standard.nix`, `home/desktop/niri-keybinds-normie.nix`, `home/desktop/normie.nix`
- **Removed files**: `home/profiles/workstation.nix`, `home/profiles/laptop.nix`
- **Modified files**:
  - `modules/users.nix` — new homeProfile enum
  - `home/default.nix` — register standard/normie, remove workstation/laptop
  - `lib/default.nix` — wire new profiles; move AI from `sharedModules` to profile-conditional; update default from `"workstation"` to `"standard"`
  - `home/desktop/default.nix` or new `home/desktop/standard.nix` — absorb Solaar autostart conditionally
  - `scripts/init-config.sh` — per-user profile prompt (standard/normie), remove form-factor derivation
  - `scripts/templates/host.nix.template` — update homeProfile references
  - `scripts/templates/ai-install-prompt.md.template` — update profile documentation
  - `scripts/templates/README.md.template` — update profile references
- **BREAKING**: Downstream configs using `homeProfile = "workstation"` or `"laptop"` must change to `"standard"`. Downstream clients will be updated directly as part of this change.
- **No new dependencies** — uses existing Niri, DMS, PWA, and theming infrastructure
