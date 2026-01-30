# Design: Refine Desktop UX

## Architecture Overview

This change touches multiple subsystems across the desktop stack. The design is intentionally conservative - each item is a surgical change rather than a refactor.

```
┌──────────────────────────────────────────────────────────┐
│                    NixOS System Layer                     │
│  modules/desktop/default.nix  - App list (removals/swaps)│
│  modules/desktop/flatpak.nix  - Flatpak handler          │
│  modules/development/default.nix - Remove code-nautilus  │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────┴───────────────────────────────────┐
│                  Home-Manager Layer                       │
│  home/terminal/ghostty.nix    - Dropterm class rename    │
│  home/desktop/default.nix     - Dolphin config (dolphinrc)│
│  home/desktop/niri.nix        - Window rules update      │
│  home/desktop/niri-keybinds.nix - Keybind updates        │
│  home/desktop/theming.nix     - Theme verification       │
└──────────────────────────────────────────────────────────┘
```

## Design Decisions

### DD-1: Dolphin Terminal Configuration Method

**Options considered:**
1. `dolphinrc` via `xdg.configFile` in home-manager
2. Environment variable `TERMINAL=ghostty`
3. KDE Global Settings (`kdeglobals`)

**Chosen: Option 1** (`dolphinrc`)

Rationale:
- `dolphinrc` is the canonical way Dolphin stores its terminal preference
- Setting `TERMINAL` env var is a blunt instrument that affects other tools
- `kdeglobals` would work but is broader than needed
- Home-manager's `xdg.configFile` is idempotent and declarative

Configuration:
```ini
[General]
TerminalApplication=ghostty
```

### DD-2: Activities Hiding Method

**Options considered:**
1. Disable `kactivitymanagerd` via systemd mask
2. Set `ActivitiesVisible=false` in dolphinrc
3. Remove the Activities KDE plugin

**Chosen: Option 1** (systemd mask)

Rationale:
- Masking `kactivitymanagerd` prevents the Activities service from starting entirely
- This removes Activities from all KDE apps, not just Dolphin
- More thorough than per-app configuration
- No user-visible side effects since axiOS uses Niri workspaces, not KDE Activities

Implementation:
```nix
systemd.user.services.plasma-kactivitymanagerd = {
  Unit.Description = "KDE Activity Manager (masked by axiOS)";
  Install = {};
  Service.ExecStart = "${pkgs.coreutils}/bin/true";
};
```

Alternative if masking causes issues: use dolphinrc `[ContextMenu]` settings.

### DD-3: Flatpak Handler Approach

**Options considered:**
1. Terminal-based handler (spawn ghostty with flatpak install)
2. Notification + background install
3. Minimal GUI dialog (zenity/kdialog)
4. GNOME Software / KDE Discover

**Chosen: Option 1** (terminal-based)

Rationale:
- Transparent: user sees exactly what's being installed
- Interactive: Flatpak's built-in confirmation prompt provides security
- Minimal: no GUI dependency beyond the existing terminal
- Consistent: uses Ghostty (already running as singleton)

Implementation:
```bash
#!/usr/bin/env bash
# axios-flatpak-install: Handle .flatpakref file installation
set -euo pipefail

REF_FILE="$1"
APP_NAME=$(grep -oP '^Name=\K.*' "$REF_FILE" 2>/dev/null || basename "$REF_FILE" .flatpakref)

echo "═══════════════════════════════════════"
echo "  axiOS Flatpak Installer"
echo "═══════════════════════════════════════"
echo ""
echo "  Installing: $APP_NAME"
echo ""

flatpak install --user "$REF_FILE"
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "  ✓ Installation complete!"
else
  echo "  ✗ Installation failed (exit code: $EXIT_CODE)"
fi
echo ""
echo "  Press Enter to close..."
read -r
```

The handler is registered as a desktop entry:
```ini
[Desktop Entry]
Type=Application
Name=axiOS Flatpak Installer
Exec=ghostty --class=com.github.kcalvelli.axios.flatpak-install -e axios-flatpak-install %f
MimeType=application/vnd.flatpak.ref;application/vnd.flatpak.repo;
NoDisplay=true
Terminal=false
```

Plus MIME association in `xdg.mimeApps.defaultApplications`.

**Niri window rule** for the installer (small floating window, not full screen):
```nix
{
  matches = [ { app-id = "^com\\.github\\.kcalvelli\\.axios\\.flatpak-install$"; } ];
  open-maximized = false;
  open-floating = true;
  default-column-width = { fixed = 800; };
  default-window-height = { fixed = 400; };
}
```

### DD-4: Drop-down Terminal Naming Convention

**Current:** `com.kc.dropterm`
**Proposed:** `com.github.kcalvelli.axios.dropterm`

This follows the reverse-DNS convention tied to the project's GitHub identity (`github.com/kcalvelli/axios`). The pattern `com.github.kcalvelli.axios.<component>` is used for all axiOS-owned window classes.

**Existing axiOS app-ids for reference:**
- `io.github.kcalvelli.c64term` (C64 Terminal - uses io.github convention)

**Decision:** Use `com.github.kcalvelli.axios.dropterm` for consistency with the broader ecosystem. The `com.github` prefix is more standard for desktop entries than `io.github`.

### DD-5: Kate → Mousepad

**Options considered:**
1. `kdePackages.kwrite` (KDE's simpler editor, same package as Kate)
2. `mousepad` (Xfce's text editor)
3. `leafpad` (minimal GTK2 editor)

**Chosen: Option 2** (Mousepad)

Rationale:
- Mousepad is GTK3 with a traditional menubar - no CSD/headerbar, respects Niri's `prefer-no-csd`
- Simpler than Kate/KWrite: no LSP, no minimap, no project management
- Supports syntax highlighting, line numbers, search/replace, tabs
- Themed via the existing GTK3 pipeline (colloid-gtk-theme, dank-colors.css from matugen) - no additional theme template needed
- Well-maintained as part of the Xfce ecosystem

**Impact on theming:**
- The `kate-dankshell.mustache` matugen template generates KTextEditor themes used only by Kate/KWrite
- With Kate removed from the desktop module, this template becomes orphaned and should be removed
- Mousepad uses GtkSourceView for syntax highlighting, which is themed via the GTK color scheme

**Package change:**
- Remove `kdePackages.kate` from `modules/desktop/default.nix`
- Add `mousepad` to `modules/desktop/default.nix`
- Keybind `Mod+Shift+T` changes spawn from `kate` to `mousepad`

### DD-6: Image Viewer Replacement (Loupe → Gwenview)

**Gwenview** (`kdePackages.gwenview`) is the natural replacement:
- Qt6/KDE, respects SSD
- Full-featured: thumbnails, slideshow, basic editing, EXIF display
- Part of KDE Gear, well-maintained
- Already compatible with KDE theming pipeline

### DD-7: Music Player Replacement (Amberol → Elisa)

**Elisa** (`kdePackages.elisa`) is the natural replacement:
- Qt6/KDE, respects SSD
- Clean, focused music player (not a full media manager)
- Integrates with KDE theming
- Baloo integration for music library indexing

## Dependency Graph

```
[1] Dolphin Terminal Config ──── (independent)
[2] Dolphin Activities Hide ──── (independent)
[3] Flatpak Handler ──────────── (independent)
[4] Dropterm Rename ───────────── depends on nothing, but touches same files as [5,6,7]
[5] App Bloat Removal ─────────── (independent)
[6] Kate → Mousepad ────────────── (independent)
[7] CSD Replacements ──────────── (independent, but [5] may remove some CSD apps)
```

Items 1-3 and 5-7 are fully parallelizable. Item 4 touches `niri.nix` and `niri-keybinds.nix` which are also touched by items 6-7, so those should be sequenced together to avoid merge conflicts.

**Recommended execution order:**
1. Items 5 + 6 + 7 together (app list changes in `default.nix` + keybind)
2. Item 4 (dropterm rename across files)
3. Items 1 + 2 (Dolphin config)
4. Item 3 (Flatpak handler - most complex, benefits from a clean base)
