# Desktop Environment

## Purpose
Provides a modern, polished Wayland-based desktop experience using the Niri compositor and DankMaterialShell.

## Components

### Niri Wayland Compositor
- **Features**: Scrollable tiling, overview mode.
- **Implementation**: `home/desktop/niri.nix`

### DankMaterialShell (DMS)
- **Features**: Material Design shell, system monitoring, clipboard, VPN status, dynamic theming via matugen.
- **Integration**: Runs via systemd service (`dms.service`).
- **Implementation**: `home/desktop/default.nix`

### Personal Information Management (PIM)
- **Apps**: Geary/Evolution, GNOME Calendar, GNOME Contacts.
- **Backend**: Evolution Data Server (EDS), GNOME Online Accounts (GOA).
- **Implementation**: `modules/pim/default.nix`

### Application Management
- **Primary Method**: Flatpak (Flathub) via GNOME Software.
- **Secondary**: NixOS packages for system tools.
- **PWA support**: Builder for Progressive Web Apps.
- **Implementation**: `modules/desktop/default.nix`, `home/desktop/pwa-apps.nix`

### Wallpaper & Theming
- **Features**: Dynamic blur, matugen color extraction, curated collection at `~/Pictures/Wallpapers`.
- **Implementation**: `home/desktop/wallpaper.nix`, `home/desktop/theming.nix`
