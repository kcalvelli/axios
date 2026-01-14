# Desktop Environment

## Purpose
Provides a modern, polished Wayland-based desktop experience using the Niri compositor and DankMaterialShell (DMS).

## Components

### Niri Wayland Compositor
- **Features**: Scrollable tiling, overview mode, sophisticated window rules, and custom keybindings guide.
- **Rules**: Deep integration with DMS for theming and session management.
- **Implementation**: `home/desktop/niri.nix`, `home/desktop/niri-keybinds.nix`

### DankMaterialShell (DMS)
- **Architecture**: Runs as a `systemd` user service (`dms.service`) ensuring reliable lifecycle management.
- **Features**: Material Design shell, system monitoring, clipboard, VPN status, and dynamic theming via `matugen`.
- **Theming**: Automatic color extraction from wallpaper.
- **Implementation**: `home/desktop/default.nix`, `home/desktop/theming.nix`

### Personal Information Management (PIM)
- **Clients**: Geary (Email), GNOME Calendar, GNOME Contacts, Evolution (Backend).
- **Backend**: Evolution Data Server (EDS) services for lightweight PIM without full GNOME.
- **Sync**: `vdirsyncer` support for CalDAV/CardDAV.
- **Limitation**: Office365/Outlook integration is currently non-functional.
- **Implementation**: `modules/pim/default.nix`

### Application Management
- **PWA support**: Dedicated builder for Progressive Web Apps.
- **Add-PWA Script**: Automated tool (`scripts/add-pwa.sh`) that installs icons, registers manifest categories, and inserts configuration into `home/desktop/pwa-apps.nix` with auto-formatting.
- **Implementation**: `modules/desktop/default.nix`, `home/desktop/pwa-apps.nix`, `scripts/add-pwa.sh`

### Wallpaper & Theming
- **Features**: Curated collection at `~/Pictures/Wallpapers`, blurred background effects, and Base16/Dank16 support for VSCode.
- **Implementation**: `home/desktop/wallpaper.nix`, `home/desktop/theming.nix`
