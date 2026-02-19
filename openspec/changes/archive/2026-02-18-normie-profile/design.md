## Context

axiOS home profiles control per-user desktop experience via home-manager. The current profile system has three issues:

1. **No simplified mode** — all desktop users get the full power-user surface (100+ keybinds, dev launchers, AI tools)
2. **Workstation/laptop split is vestigial** — the only difference is Solaar autostart, which is a hardware concern not a profile concern
3. **`"minimal"` is a dead enum value** — defined in the type but never implemented (no `home/profiles/minimal.nix` exists)

The desktop module (`home/desktop/`) is currently monolithic — `default.nix` imports niri config, keybinds, theming, wallpaper, PWAs, mpv, DMS, axios-monitor, and dsearch as a single unit. Profiles (`workstation.nix`, `laptop.nix`) import `../desktop` wholesale. There is no way for a profile to select a subset.

AI home modules (`home/ai/`) are applied to ALL users via `sharedModules` in `lib/default.nix`, with no per-profile opt-out.

## Goals / Non-Goals

**Goals:**
- Two clear profiles: `"standard"` (current power-user experience) and `"normie"` (ChromeOS-like, mouse-driven)
- Normie users get window titlebars, DMS shelf, PWAs, and minimal keybindings — no tiling, no terminals, no AI
- Solaar autostart becomes hardware-conditional, not profile-gated
- Init script prompts per-user profile selection
- Clean elimination of workstation/laptop/minimal dead weight

**Non-Goals:**
- Alternative desktop environments (GNOME, KDE Plasma) — both profiles use Niri + DMS
- Per-app opt-in/opt-out granularity within a profile — profiles are opinionated bundles
- Runtime profile switching — profile is set at config time, requires rebuild to change

## Decisions

### 1. Profile-specific desktop modules instead of conditional options

**Decision**: Create separate `home/desktop/normie.nix` and `home/desktop/niri-keybinds-normie.nix` files rather than adding `lib.mkIf` conditionals throughout the existing desktop module.

**Rationale**: The existing `home/desktop/default.nix` imports 10 modules and configures DMS, services, MIME types, Flatpak, etc. Threading a profile option through all of these would add complexity throughout. Instead, the normie profile imports a new `home/desktop/normie.nix` that cherry-picks the subset it needs (theming, wallpaper, PWAs, MIME, DMS, mpv, Flatpak, gnome-keyring, KDE Connect) while providing its own simplified niri config.

**Alternative considered**: A single desktop module with `axios.desktop.profile = "standard" | "normie"` option. Rejected because it would require pervasive `mkIf` branching in keybinds, spawn-at-startup, DMS config, and package lists — harder to read and maintain than two clean compositions.

### 2. CSD via `prefer-no-csd = false` for normie profile

**Decision**: The normie profile sets `programs.niri.settings.prefer-no-csd = false` (opposite of current `true`). This tells GTK/Qt apps to draw their own client-side decorations (titlebars with close/minimize/maximize buttons).

**Rationale**: This is per-user (home-manager niri config), so standard users keep borderless windows while normie users get titlebars. No system-level change needed. CSD is well-supported by GTK4 and Qt6 apps. Niri does not currently provide server-side decorations, so CSD is the only path to window controls.

**Trade-off**: CSD appearance varies between GTK and Qt apps (different titlebar styles). This is acceptable — ChromeOS itself has inconsistent window chrome across web apps and Android apps.

### 3. Move AI from sharedModules to profile-conditional imports

**Decision**: Remove `self.homeModules.ai` from the universal `sharedModules` list in `lib/default.nix`. Instead, import it only for `"standard"` profile users in the per-user profile wiring block.

**Rationale**: AI tools (claude-code, gemini, MCP servers, system prompts) are developer-oriented. Normie users don't need them, and they add unnecessary packages and config files to their home. The AI NixOS module (system-level) remains unchanged — only the home-manager AI module is profile-gated.

**Alternative considered**: Adding `services.ai.perUser = true/false` option. Rejected as over-engineered — the profile already captures this intent. If a normie user somehow needs AI tools, they can override with `homeProfile = "standard"`.

### 4. Solaar autostart via hardware detection, not profile

**Decision**: Move the Solaar autostart `.desktop` file from `home/profiles/workstation.nix` into the standard profile's desktop config, conditional on `osConfig.hardware.logitech.wireless.enableGraphical or false`. Normie profile gets Solaar too if the hardware flag is set.

**Rationale**: Solaar is a hardware concern (Logitech Unifying receiver management), not a user-experience concern. Both standard and normie users with Logitech hardware should get it. The existing system-level `hardware.desktop.enableLogitechSupport` option already controls whether Solaar is installed — the autostart should follow the same signal.

### 5. Normie keybindings: minimal set that doesn't conflict with DMS

**Decision**: `home/desktop/niri-keybinds-normie.nix` provides only:
- `Mod+Q` — close window (familiar from macOS Cmd+Q)
- `Mod+F` — maximize/restore (toggle)
- `Print` — screenshot
- DMS-injected bindings (media keys, Mod+Space launcher, Mod+N notifications, Mod+X power menu, Mod+V clipboard, Super+Alt+L lock) come automatically via `enableKeybinds = true`

No tiling binds, no workspace navigation, no dev launchers, no drop-down terminal, no axios-help. The user interacts entirely via DMS panel clicks and Alt+Tab.

### 6. Standard profile is a rename of workstation, not a rewrite

**Decision**: `home/profiles/standard.nix` is functionally identical to the current `workstation.nix` — imports `base.nix` and `../desktop`. The Solaar autostart moves to `home/desktop/default.nix` with hardware detection.

**Rationale**: Minimizes risk. The standard experience doesn't change at all — it's purely a rename. Existing users who switch from `"workstation"` to `"standard"` see zero behavioral difference.

### 7. Init script prompts profile per-user instead of deriving from form factor

**Decision**: Remove the `HOME_PROFILE` derivation from form factor (`desktop → workstation`, `laptop → laptop`). Instead, the host-level `homeProfile` defaults to `"standard"`. During user collection, the init script asks per-user: "Profile? (standard / normie)" with standard as default.

**Rationale**: Form factor is orthogonal to user experience preference. A laptop user might want normie mode; a desktop user might want normie mode. The distinction is about the person, not the hardware.

### 8. Default homeProfile changes from "workstation" to "standard"

**Decision**: In `lib/default.nix`, change `profile = hostCfg.homeProfile or "workstation"` to `profile = hostCfg.homeProfile or "standard"`.

**Rationale**: Direct rename. The host-level default should match the new enum. Downstream configs that don't set `homeProfile` at all get `"standard"` (same behavior as before, since standard = workstation).

## Risks / Trade-offs

- **CSD inconsistency** — GTK and Qt apps render different titlebar styles. Normie users may notice visual inconsistency between Brave (GTK) and Dolphin (Qt). → Acceptable; mirrors ChromeOS behavior with mixed web/Android apps.

- **DMS keybinds still present** — DMS injects its own bindings (Mod+Space, Mod+N, Mod+V, Mod+X, etc.) via `enableKeybinds = true`. These are ~8 bindings that normie users don't need to learn but won't hurt. → Acceptable; they're all accessible via mouse through the DMS panel too.

- **No workspace management for normie** — Normie users can't organize windows into workspaces. They rely on Alt+Tab only. → Acceptable for the target audience. Workspaces are a power-user concept.

- **Code duplication between desktop modules** — `home/desktop/normie.nix` will duplicate some config from `home/desktop/default.nix` (MIME associations, Flatpak, gnome-keyring, KDE Connect). → Acceptable; extracting shared config into a `home/desktop/common.nix` is a future refactor if duplication becomes painful. Keeping them separate now means each profile is self-contained and easy to reason about.
