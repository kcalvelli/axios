## Context

The desktop module (`modules/desktop/default.nix`) installs ~50 packages in a single `environment.systemPackages` block guarded only by `desktop.enable`. Users cannot selectively disable heavyweight apps without losing the entire desktop. The module already has precedent for aspect files (`flatpak.nix`, `browsers.nix`).

## Goals / Non-Goals

**Goals:**
- Add sub-option flags (`desktop.media.enable`, `desktop.office.enable`, `desktop.streaming.enable`, `desktop.social.enable`) each defaulting to `true`
- Move packages into conditional blocks within the existing `modules/desktop/default.nix`
- Remove profanity (redundant XMPP client) and c64term (novelty)
- Remove gajim from desktop (belongs with chat/PIM, not desktop)

**Non-Goals:**
- Creating separate aspect files for each sub-option (keep in default.nix with mkIf blocks — the groups are small)
- Changing the installer/Calamares (all defaults are true)
- Creating a desktop.chat or axios-chat module (future work)
- Changing any programs.* or services.* declarations (those stay in core desktop)

## Decisions

### 1. Inline mkIf blocks, not separate files

**Decision**: Add sub-option mkIf blocks within `modules/desktop/default.nix` rather than creating `media.nix`, `office.nix`, etc.

**Rationale**: Each group is 3-8 packages. Separate files for 3-line package lists creates unnecessary file proliferation. The mkIf pattern is already well-established in the codebase. If a group grows complex (gains services, config, etc.), it can be extracted to an aspect file later.

### 2. Package groupings

**Core desktop** (always with `desktop.enable`):
- xwayland-satellite, dolphin+ark+kio+kdegraphics-thumbnailers
- fuzzel, wtype, playerctl, pavucontrol, slurp, swaybg
- theming (colloid-gtk-theme, colloid-icon-theme, adwaita-icon-theme, papirus-icon-theme, hicolor-icon-theme, adw-gtk3, qt5ct, qt6ct)
- libnotify, imagemagick, mousepad
- lxqt-openssh-askpass
- plasma-workspace, kservice

**desktop.media.enable** (default true):
- gwenview, tauon, ffmpeg, wf-recorder, swappy, krita

**desktop.office.enable** (default true):
- libreoffice-qt, ghostwriter, okular, qalculate-qt, filelight

**desktop.streaming.enable** (default true):
- obs-studio-gamemode (wrapped), discord

**desktop.social.enable** (default true):
- materialgram, spotify, zenity (Spotify dependency)

### 3. Removals

- **profanity**: Remove entirely. Gajim is the XMPP client.
- **c64term**: Remove entirely. Novelty item.
- **gajim**: Remove from desktop. XMPP belongs with a chat/PIM module, not the desktop.

## Risks / Trade-offs

- **[Risk] Users who explicitly installed profanity/c64term/gajim via desktop** → Mitigation: These can be added back via `extraConfig.environment.systemPackages`. Minor inconvenience.
- **[Risk] Option proliferation** → Mitigation: Only 4 sub-options, all defaulting to true. Clean and predictable.
