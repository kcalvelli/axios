# Proposal: Streamlined Flatpak Installation

## Status: Backlog

## Problem Statement

Currently, installing Flatpak applications from the Flathub website requires a full app store application (like KDE Discover or GNOME Software). These stores:
- Show unrelated apps and recommendations
- Add bloat and complexity
- Are overkill for users who just want to click "Install" on Flathub

The user has removed `kdePackages.discover` and wants a minimal, streamlined experience.

## Desired User Flow

1. User visits https://flathub.org in browser
2. User finds desired app and clicks "Install"
3. Flathub triggers installation (via `.flatpakref` file or `flatpak://` URL)
4. A minimal handler processes the request
5. App installs in background (or with simple progress indicator)
6. No app store UI, no browsing other apps, no distractions

## Research Questions

### 1. How does Flathub trigger installs?
- Does it use `.flatpakref` file downloads?
- Does it use `flatpak://` URI scheme?
- Does it use XDG portal / D-Bus?
- What MIME types are involved?

### 2. What handlers exist?
- `flatpak-xdg-utils` - provides xdg-open integration
- `xdg-desktop-portal-*` - portal implementations
- Custom handler script wrapping `flatpak install`
- Minimal GTK/Qt dialog for confirmation

### 3. What's the minimal solution?
Options to explore:
- **Script handler**: Shell script that calls `flatpak install --assumeyes`
- **Terminal popup**: Open terminal, run flatpak install, close on success
- **Notify + background**: Send notification, install in background
- **Minimal GUI**: Simple confirmation dialog with progress

### 4. Security considerations
- Should there be a confirmation prompt?
- How to prevent malicious installs?
- User consent model

## Potential Implementation Approaches

### Approach A: Terminal-based handler
```bash
#!/usr/bin/env bash
# Handler for .flatpakref files
foot --hold flatpak install "$1"
```
- Pros: Simple, transparent, shows progress
- Cons: Requires terminal, less polished

### Approach B: Notification-based background install
```bash
#!/usr/bin/env bash
notify-send "Installing Flatpak" "Installing $(basename $1)..."
flatpak install --assumeyes "$1" && \
  notify-send "Install Complete" "$(basename $1) is ready"
```
- Pros: Non-intrusive
- Cons: No progress visibility, silent failures

### Approach C: Minimal GUI dialog
- Use `zenity`, `kdialog`, or custom tool
- Show: App name, description, "Install" / "Cancel"
- Show progress bar during install
- Pros: Polished UX
- Cons: Additional dependency

### Approach D: Existing minimal tool
- Research if a minimal flatpak installer GUI already exists
- Check: `gnome-software-plugin-flatpak` without full GNOME Software?
- Check: Standalone flatpak GUI tools

## Implementation Outline

1. **Research phase**: Determine how Flathub triggers installs
2. **Handler creation**: Create minimal handler script/tool
3. **MIME registration**: Register handler for `.flatpakref` and `flatpak://`
4. **NixOS module**: Add option to enable streamlined flatpak
5. **Testing**: Verify flow works end-to-end

## Files to Create/Modify

| File | Purpose |
|------|---------|
| `modules/desktop/flatpak.nix` | Flatpak handler configuration |
| `pkgs/flatpak-installer/` | Minimal installer tool (if needed) |

## Dependencies

- Flatpak must be enabled (`services.flatpak.enable`)
- XDG portal integration
- Browser must handle file downloads / URI schemes

## Open Questions

1. Does Niri/Wayland affect how URI handlers work?
2. What's the best UX for showing install progress?
3. Should axiOS provide a "Flathub" PWA desktop entry for quick access?
4. How do other minimal distros (like Fedora Silverblue) handle this?

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Research | 2-3 hours |
| Implementation | 2-4 hours |
| Testing | 1 hour |
| **Total** | **5-8 hours** |

## References

- https://docs.flatpak.org/en/latest/flatpak-command-reference.html
- https://flathub.org (test install flow)
- XDG MIME handlers: https://wiki.archlinux.org/title/XDG_MIME_Applications
