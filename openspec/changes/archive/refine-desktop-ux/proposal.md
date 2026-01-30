# Proposal: Refine Desktop UX

## Status: Complete

## Summary

A targeted sweep of the axiOS desktop module to improve UX consistency, reduce bloat, and enforce the project's SSD (Server-Side Decorations) visual identity. This change covers seven areas:

1. **Dolphin: Open Terminal Here → Ghostty** - Dolphin's "Open Terminal Here" context menu should launch Ghostty instead of Konsole.
2. **Dolphin: Hide Activities** - The KDE "Activities" context menu item should be hidden since axiOS doesn't use KDE Activities.
3. **Flatpak: One-click install from Flathub** - Clicking "Install" on the Flathub website/PWA should launch a flatpak installer (supersedes existing `flatpak-streamlined-install` backlog item).
4. **Drop-down terminal: Dock & naming** - The drop-down terminal should not show an icon in the DMS dock, and its startup class should follow axiOS conventions (`com.github.kcalvelli.axios.dropterm`).
5. **Application bloat reduction** - Remove applications that don't fit the axiOS profile, giving users the ability to install them separately.
6. **Replace Kate with Mousepad** - Kate is too heavy for a default text editor; replace with Mousepad (Xfce's simple text editor, GTK3, no CSD).
7. **CSD audit & remediation** - Replace CSD-forced applications with SSD-compatible alternatives where quality alternatives exist.

## Motivation

axiOS uses the Niri compositor with `prefer-no-csd = true`, establishing a clean, consistent visual language where the compositor controls window decorations. Several currently-installed applications break this by forcing CSD (Client-Side Decorations), creating a visually inconsistent experience. Additionally, the application list has grown beyond what a focused system framework should ship by default.

The axiOS philosophy is "Library First" - users should be empowered to install additional applications via `extraConfig`, nixpkgs, or Flatpak. The default set should be the curated essentials, not a complete app store.

## Scope

**In scope:** Desktop module (`modules/desktop/`), home terminal config (`home/terminal/`), home desktop config (`home/desktop/`), flatpak module, Niri window rules, desktop entries, and the desktop spec.

**Out of scope:** Gaming module, AI module, development module (except removing `code-nautilus` since we don't ship Nautilus), networking, virtualisation.

---

## 1. Dolphin: Open Terminal Here → Ghostty

### Current State
Dolphin uses KDE's default terminal emulator setting. Without explicit configuration, it defaults to Konsole (which isn't installed) or falls back to xterm. Dolphin's built-in F4 terminal panel also uses the default.

### Proposed Change
Configure `dolphinrc` via home-manager to set Ghostty as Dolphin's terminal:
- Set `TerminalApplication=ghostty` in `[General]` section of `dolphinrc`.
- This affects both the "Open Terminal Here" (Shift+F4) context menu and the F4 embedded terminal panel.

### Rationale
Ghostty is axiOS's primary terminal emulator, already running as a singleton daemon. Using it for Dolphin terminal integration provides consistency and leverages the existing resident process for instant window creation.

---

## 2. Dolphin: Hide Activities

### Current State
KDE Activities are a feature of KDE Plasma that provides virtual workspace grouping. axiOS uses Niri workspaces, not KDE Activities. However, since `kdePackages.plasma-workspace` is installed (for menu spec compliance), the Activities context menu item appears in Dolphin.

### Proposed Change
Disable the Activities plugin in Dolphin via `dolphinrc`:
- Set `ActivitiesVisible=false` or disable the relevant KDE Activity Manager plugin.
- Alternatively, configure `kactivitymanagerd` to not start, or mask it via systemd.

### Rationale
The Activities menu item is confusing in a Niri environment and provides no value. Hiding it reduces visual clutter and prevents user confusion.

---

## 3. Flatpak: One-click Install from Flathub

### Current State
An existing backlog item (`openspec/changes/flatpak-streamlined-install/`) documents this need. Flatpak is enabled, Flathub remote is configured, but there's no handler for `.flatpakref` files or `x-scheme-handler/application/vnd.flatpak.ref` MIME types. Clicking "Install" on Flathub downloads a `.flatpakref` file that nothing handles.

### Proposed Change
Create a minimal `.flatpakref` MIME handler:
- Register a handler for `application/vnd.flatpak.ref` and `application/vnd.flatpak.repo` MIME types.
- The handler spawns a Ghostty terminal window running `flatpak install <ref-file>`, giving the user clear progress and a confirmation prompt (Flatpak's default `y/N` prompt).
- Window class set to a recognizable axiOS class for Niri window rules.
- Niri window rule: **small floating window** (not full screen), centered, ~800x400px.
- On completion, display success/failure and close after keypress.

### Rationale
A terminal-based approach is minimal, transparent, and consistent with the axiOS desktop. It avoids adding a GUI dependency (GNOME Software, Discover) while giving users full visibility into what's being installed. This supersedes and replaces the existing `flatpak-streamlined-install` backlog change.

---

## 4. Drop-down Terminal: Dock & Naming

### Current State
- **App ID**: `com.kc.dropterm` - doesn't follow reverse-DNS conventions matching the axiOS project.
- **Dock icon**: `NoDisplay=true` is set in the desktop entry, but DMS dock behavior depends on the running window's app-id, not the desktop entry. The dropdown may still appear in the dock when spawned.

### Proposed Change
- **Rename app class** from `com.kc.dropterm` to `com.github.kcalvelli.axios.dropterm`.
- **Ensure no dock icon**: Add a Niri window rule `exclude-from-focus-chain = true` (if supported) or configure DMS to exclude this app-id from the dock. The desktop entry already has `NoDisplay=true`.
- Update all references: `ghostty.nix`, `niri.nix`, `niri-keybinds.nix`.

### Rationale
The naming convention `com.github.kcalvelli.axios.*` is consistent with the project's GitHub identity. Hiding the dock icon prevents the dropdown from cluttering the taskbar since it's a transient, keyboard-driven utility.

---

## 5. Application Bloat Reduction

### Current State
The desktop module ships 30+ GUI applications. Several are niche, overlapping, or better suited as user-installed additions:

### Applications to Remove

| Application | Reason for Removal | User Can Install Via |
|-------------|-------------------|---------------------|
| **DBeaver** | Niche database tool; not a general desktop essential | `extraConfig` / nixpkgs |
| **DigiKam** | Heavy photo manager; overlaps with Immich PWA for photo management | `extraConfig` / nixpkgs |
| **Inkscape** | Professional vector editor; niche creative use case, also CSD | `extraConfig` / nixpkgs / Flatpak |
| **v4l-utils** | Camera debugging; developer/power-user tool | `extraConfig` / nixpkgs |
| **wayvnc** | VNC server; not needed on most desktops | `extraConfig` / nixpkgs |
| **LocalSend** | File sharing tool; not used | `extraConfig` / nixpkgs |
| **Trayscale** | Tailscale system tray; not used (DMS provides VPN widget) | `extraConfig` / nixpkgs |
| **RenderDoc** | Graphics debugger; developer/niche tool, installed by graphics module | `extraConfig` / nixpkgs |
| **code-nautilus** | Nautilus integration for VS Code; axiOS uses Dolphin, not Nautilus | Remove entirely |
| **Kate** | Replaced by Mousepad as default editor; users who need Kate/KWrite can install via `extraConfig` | `extraConfig` / nixpkgs |

### Applications to Keep

| Application | Justification |
|-------------|---------------|
| **Dolphin + Ark + KIO extras + thumbnailers** | Core file management |
| **Mousepad** | Simple text editor (GTK3, SSD, lightweight) |
| **Ghostwriter** | Markdown editing (Qt, SSD, lightweight) |
| **Haruna** | Video playback (Qt, SSD, MPV frontend) |
| **MPV + FFmpeg** | Core media playback/processing |
| **Okular** | PDF viewing (Qt, SSD, essential) |
| **Filelight** | Disk usage (Qt, SSD, useful utility) |
| **Qalculate-qt** | Calculator (Qt, SSD) |
| **Swappy** | Screenshot workflow |
| **Gajim** | XMPP client (needed for axios-ai-chat integration) |
| **Discord** | Communication (kept - industry standard) |
| **Profanity** | XMPP client (terminal, no CSD concern) |
| **Krita** | Drawing/art (Qt, SSD - need one drawing program) |
| **OBS Studio** | Video recording (Qt, SSD) |
| **Syncterm** | BBS access (retro terminal, part of axiOS identity) |
| **All Wayland tools** | Core compositor support |
| **All theming packages** | Visual consistency |
| **Brave browser** | Primary browser |
| **Swaybg, ImageMagick, libnotify** | Core utilities |

### Rationale
axiOS is a framework, not a distribution. A leaner default set:
- Reduces system closure size and rebuild time
- Communicates a clear identity (productivity/development, not creative suite)
- Empowers users to curate their own application stack
- Follows the "Library First" constitutional principle

---

## 6. Replace Kate with Mousepad

### Current State
Kate is a full IDE-weight editor with LSP, minimap, plugins, split views, and project management. While powerful, it's overkill for the "default text editor" role. Users needing Kate-level features likely already use VS Code (in the development module).

### Proposed Change
Replace `kdePackages.kate` with `mousepad`:
- **Mousepad** is the Xfce text editor - simple, fast, and lightweight.
- GTK3-based with traditional menubar (no headerbar/CSD), so it uses SSD with Niri's `prefer-no-csd`.
- Supports syntax highlighting, line numbers, search/replace, word wrap, and multiple tabs.
- Themed via the existing GTK3 theme pipeline (colloid-gtk-theme, dank-colors.css from matugen).
- Keybind `Mod+Shift+T` updated to launch `mousepad`.
- The `kate-dankshell.mustache` matugen template can be removed (it generates KTextEditor themes which Mousepad doesn't use).

### Rationale
Mousepad provides exactly the right level of functionality for a default text editor: syntax highlighting, search/replace, and tab support without IDE complexity. It's lightweight, doesn't use CSD, and integrates with the existing GTK theme system. Users who need Kate or VS Code can install them via `extraConfig` or the development module.

---

## 7. CSD Audit & Remediation

### Methodology
With `prefer-no-csd = true` in Niri, Qt/KDE apps use SSD (compositor decorations) while GTK4/libadwaita and some GTK3 apps force CSD (drawing their own titlebar). This creates a visual inconsistency.

### CSD Audit Results

| Application | Toolkit | CSD/SSD | Status |
|-------------|---------|---------|--------|
| **All KDE packages** | Qt6 | SSD | Keep |
| **Ghostwriter** | Qt6 (KDE) | SSD | Keep |
| **Qalculate-qt** | Qt6 | SSD | Keep |
| **Haruna** | Qt6 (KDE) | SSD | Keep |
| **Loupe** | GTK4/libadwaita | CSD | **Replace** |
| **Amberol** | GTK4/libadwaita | CSD | **Replace** |
| **Inkscape** | GTK3/4 | CSD | Remove (bloat, item 5) |
| **Gajim** | GTK4 | CSD | Keep (needed for axios-ai-chat) |
| **Pavucontrol** | GTK3 | CSD | **Replace** |
| **Discord** | Electron | Mixed | Keep (standard, CSD less visible) |
| **DBeaver** | Java/SWT | Native | Remove (bloat, item 5) |
| **Swappy** | GTK3 | CSD | Keep (brief annotation tool, CSD acceptable) |
| **OBS Studio** | Qt6 | SSD | Remove (bloat, item 5) |

### Proposed Replacements

| CSD App | Replacement | Toolkit | Notes |
|---------|-------------|---------|-------|
| **Loupe** (image viewer) | **gwenview** (`kdePackages.gwenview`) | Qt6/KDE | Full-featured image viewer, SSD, KDE integration, thumbnail browsing |
| **Amberol** (music player) | **Elisa** (`kdePackages.elisa`) | Qt6/KDE | KDE's music player, SSD, clean Material-compatible UI, library management |
| **Pavucontrol** (audio control) | **pwvucontrol** | GTK4/libadwaita | PipeWire-native volume control. NOTE: This is also CSD/libadwaita, but no Qt alternative exists. Keep pavucontrol as-is since it's a brief utility, OR accept pwvucontrol's CSD. **Decision needed.** |

### Pavucontrol Decision

There is no good Qt/SSD alternative to pavucontrol for PipeWire audio control:
- `pavucontrol` - GTK3, CSD, but stable and well-known
- `pwvucontrol` - GTK4/libadwaita, CSD, PipeWire-native (newer)
- DMS provides basic volume controls in the panel already

**Recommendation**: Keep `pavucontrol` as-is. It's a brief utility window (not something users stare at) and there's no SSD alternative. DMS handles daily volume needs; pavucontrol is the escape hatch for advanced audio routing.

### Rationale
Gwenview and Elisa are mature KDE applications that provide equivalent or superior functionality to their GNOME counterparts while respecting SSD. This creates a visually consistent desktop where all primary applications use compositor-controlled decorations.

---

## Impact on Existing Changes

- **Supersedes**: `openspec/changes/flatpak-streamlined-install/` - This proposal includes a concrete implementation plan for item 3 (Flatpak install handler). The existing backlog change should be archived when this is implemented.

## Files Affected

| File | Changes |
|------|---------|
| `modules/desktop/default.nix` | Remove bloat apps, remove LocalSend, replace Kate→Mousepad, replace Loupe→Gwenview, replace Amberol→Elisa |
| `modules/development/default.nix` | Remove `code-nautilus` |
| `modules/graphics/default.nix` | Remove `renderdoc` |
| `modules/networking/tailscale.nix` | Remove `trayscale` package |
| `modules/desktop/flatpak.nix` | Add `.flatpakref` MIME handler |
| `home/terminal/ghostty.nix` | Update dropterm class, add dolphinrc config |
| `home/desktop/niri.nix` | Update dropterm window rule app-id |
| `home/desktop/niri-keybinds.nix` | Update dropterm app-id, update Kate→Mousepad keybind |
| `home/desktop/default.nix` | Add dolphinrc configuration for terminal and Activities, remove trayscale systemd service |
| `home/desktop/theming.nix` | Remove kate-dankshell.mustache template (no longer needed with Mousepad) |
| `openspec/specs/desktop/spec.md` | Update desktop spec with new requirements |
| `docs/APPLICATIONS.md` | Update application catalog |

## Estimated Effort

| Area | Effort |
|------|--------|
| Dolphin terminal + Activities | 1 hour |
| Flatpak handler | 2-3 hours |
| Drop-down terminal rename | 1 hour |
| App bloat removal | 1 hour |
| Kate → Mousepad | 30 min |
| CSD replacements | 1 hour |
| Spec updates & docs | 1 hour |
| Testing & validation | 1-2 hours |
| **Total** | **8-10 hours** |
