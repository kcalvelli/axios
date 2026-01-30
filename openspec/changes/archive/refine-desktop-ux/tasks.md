# Tasks: Refine Desktop UX

## Status: Complete

## Overview

Improve desktop UX consistency by configuring Dolphin, adding a Flatpak installer, renaming the drop-down terminal, reducing application bloat, replacing Kate with Mousepad, swapping CSD applications for SSD alternatives, and removing legacy theming code.

---

## Phase 1: Application List Changes (bloat + CSD + editor)

### Task 1.1: Remove bloat applications across modules
- [x] Edit `modules/desktop/default.nix`:
  - Remove `dbeaver-bin`
  - Remove `kdePackages.digikam`
  - Remove `inkscape`
  - Remove `v4l-utils`
  - Remove `wayvnc`
  - Remove `localsend` (the entire `programs.localsend` block with `enable` and `openFirewall`)
- [x] Edit `modules/development/default.nix`:
  - Remove `code-nautilus`
- [x] Edit `modules/graphics/default.nix`:
  - Remove `renderdoc` from graphics utilities package list
- [x] Edit `modules/networking/tailscale.nix`:
  - Remove `trayscale` from `environment.systemPackages`
- [x] Edit `home/desktop/default.nix`:
  - Remove the entire `systemd.user.services.trayscale` block

### Task 1.2: Replace Kate with Mousepad
- [x] Edit `modules/desktop/default.nix`:
  - Replace `kdePackages.kate` with `mousepad`
  - Update comment from "Text editor (LSP, minimap, plugins, dev-tier features)" to "Text editor (simple, syntax highlighting, no CSD)"
- [x] Edit `home/desktop/niri-keybinds.nix`:
  - Change `Mod+Shift+T` spawn command from `kate` to `mousepad`
  - Update keybinding help text from "Kate" to "Mousepad"
- [x] Edit `home/desktop/theming.nix`:
  - Remove the kate-dankshell.mustache template reference (KTextEditor theme no longer needed)
  - Remove legacy theming mode entirely (DMS handles all theming now)
  - Remove unused `useAxiosTemplates` option and `cfg` variable
  - Clean up unused `inputs` and `themeProjectDir` variables
- [x] Remove `home/terminal/resources/kate-dankshell.mustache` template file

### Task 1.3: Replace CSD applications with SSD alternatives
- [x] Edit `modules/desktop/default.nix`:
  - Replace `loupe` with `kdePackages.gwenview`
  - Replace `amberol` with `kdePackages.elisa`
  - Update comments for new apps

---

## Phase 2: Drop-down Terminal Rename

### Task 2.1: Rename drop-down terminal app-id
- [x] Edit `home/terminal/ghostty.nix`:
  - Change `com.kc.dropterm` to `com.github.kcalvelli.axios.dropterm` in desktop entry
  - Update `--class=com.kc.dropterm` to `--class=com.github.kcalvelli.axios.dropterm` in Exec line
  - Update `StartupWMClass` to match
- [x] Edit `home/desktop/niri.nix`:
  - Update window rule `app-id` match from `com\\.kc\\.dropterm` to `com\\.github\\.kcalvelli\\.axios\\.dropterm`
- [x] Edit `home/desktop/niri-keybinds.nix`:
  - Update grep pattern for `com.kc.dropterm` to `com.github.kcalvelli.axios.dropterm`
  - Update `--class=com.kc.dropterm` to `--class=com.github.kcalvelli.axios.dropterm`

### Task 2.2: Ensure drop-down terminal is hidden from dock
- [x] Desktop entry has `NoDisplay=true` (existing behavior preserved)
- [x] Niri window rule keeps dropterm floating (not in tiling layout)

---

## Phase 3: Dolphin Configuration

### Task 3.1: Configure Ghostty as Dolphin's terminal
- [x] Edit `home/desktop/default.nix`:
  - Add `xdg.configFile."dolphinrc"` with `[General]` section setting `TerminalApplication=ghostty`
  - Use `force = true` to ensure config is applied

### Task 3.2: Hide Activities from Dolphin/KDE
- [x] Mask `plasma-kactivitymanagerd` systemd user service in `home/desktop/default.nix`:
  - ExecStart replaced with `${pkgs.coreutils}/bin/true`
  - Empty Install block prevents auto-start

---

## Phase 4: Flatpak Install Handler

### Task 4.1: Create flatpak install handler script
- [x] Create `axios-flatpak-install` shell script in `modules/desktop/flatpak.nix`:
  - Script accepts `.flatpakref` file path as argument
  - Displays app name, runs `flatpak install --user`, shows result
  - Pauses for user to read before closing
- [x] Add script to `modules/desktop/flatpak.nix` as `writeShellScriptBin`

### Task 4.2: Create desktop entry and MIME registration
- [x] Create desktop entry in `home/desktop/default.nix`:
  - `MimeType=application/vnd.flatpak.ref;application/vnd.flatpak.repo;`
  - `Exec=ghostty --class=com.github.kcalvelli.axios.flatpak-install -e axios-flatpak-install %f`
  - `NoDisplay=true`
- [x] Register MIME association in `xdg.mimeApps.defaultApplications`:
  - `application/vnd.flatpak.ref` → handler desktop entry
  - `application/vnd.flatpak.repo` → handler desktop entry
- [x] Add Niri window rule for `com.github.kcalvelli.axios.flatpak-install`:
  - Small floating window (NOT full screen): 800x400px, centered
  - `open-maximized = false; open-floating = true;`

### Task 4.3: Archive superseded change
- [x] Move `openspec/changes/flatpak-streamlined-install/` to `openspec/changes/archive/`

---

## Phase 5: Documentation & Finalization

### Task 5.1: Update documentation
- [x] Update `docs/APPLICATIONS.md`:
  - Remove entries for removed applications (DigiKam, Inkscape, LocalSend, GNOME Software, wayvnc)
  - Update Kate → Mousepad
  - Update Loupe → Gwenview, Amberol → Elisa
  - Add note about Flatpak handler in System Utilities section
- [x] Update `home/desktop/niri-keybinds.nix` help text (Kate → Mousepad)

### Task 5.2: Update specs
- [x] Merge spec delta: Copy `openspec/changes/refine-desktop-ux/specs/desktop/spec.md` changes into `openspec/specs/desktop/spec.md`

### Task 5.3: Final validation
- [x] Run `nix fmt .`
- [ ] Run `nix flake check --all-systems` (or dry-run build) - deferred to user testing
- [ ] Archive change: Move `openspec/changes/refine-desktop-ux/` to `openspec/changes/archive/` - after user validation

---

## Additional Changes (User-Requested)

### Remove legacy theming mode
- [x] Remove `useAxiosTemplates` option from `home/desktop/theming.nix`
- [x] Remove legacy matugen template registration code (DMS manages all templates)
- [x] Remove Kate themes directory activation script
- [x] Clean up unused variables (`inputs`, `themeProjectDir`, `cfg`)
- [x] Simplify `registerMatugenTemplates` to just ensure directories exist

---

## Blocked By

- None - implementation complete.

## Priority

**Medium-High** - Visible UX improvements and consistency gains.
