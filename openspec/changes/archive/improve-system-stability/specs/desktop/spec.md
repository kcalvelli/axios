# Desktop Environment

## Purpose
Provides a modern, polished Wayland-based desktop experience using the Niri compositor and DankMaterialShell (DMS).

## Components

### Niri Wayland Compositor
- **Features**: Scrollable tiling, overview mode, sophisticated window rules, and custom keybindings guide.
- **Rules**: Deep integration with DMS for theming and session management.
- **Implementation**: `home/desktop/niri.nix`, `home/desktop/niri-keybinds.nix`

### DankMaterialShell (DMS)
- **Architecture**: Launched via Niri's `spawn-at-startup` mechanism (managed by the `dank-material-shell` niri module).
- **Lifecycle**: Systemd integration is explicitly disabled in `axios` to eliminate race conditions with PipeWire/Wayland during boot.
- **Features**: Material Design shell, system monitoring, clipboard, VPN status, and dynamic theming via `matugen`.
- **Theming**: Automatic color extraction from wallpaper.
- **Implementation**: `home/desktop/default.nix`, `home/desktop/theming.nix`, `home/desktop/niri.nix`

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

## ADDED Requirements

### Requirement: Ghostty Singleton Cleanup

Applications spawned at Niri startup with singleton/resident mode MUST have pre-startup cleanup to prevent zombie processes from blocking new sessions.

#### Scenario: Ghostty starts after unclean logout

- **Given**: A previous Niri session crashed or the system froze before logout
- **And**: A Ghostty process from the old session is still running (zombie state)
- **When**: User logs in and Niri starts a new session
- **Then**: The pre-startup cleanup command kills the stale Ghostty process
- **And**: A new Ghostty instance starts successfully with `--gtk-single-instance=true`

#### Scenario: Clean logout and re-login

- **Given**: User logged out cleanly (Niri exited normally)
- **And**: No stale Ghostty processes exist
- **When**: User logs in again
- **Then**: The pre-startup cleanup command completes (no-op if nothing to kill)
- **And**: Ghostty starts normally

### Requirement: Document Known Upstream Stability Issues

Known stability issues caused by upstream dependencies MUST be documented in the spec to help users understand expected behavior.

#### Scenario: User investigates DMS crash at login

- **Given**: User experiences occasional DMS/Quickshell SIGSEGV at greeter startup
- **When**: User consults the desktop spec documentation
- **Then**: User finds the issue documented as a known upstream limitation
- **And**: User finds the workaround (re-attempt login)

## Constraints
- **Wayland Compatibility**: All desktop components must be Wayland-native.
- **Spawn Order**: DMS must spawn after `dbus-update-activation-environment` to ensure session variables are available.
- **Singleton Cleanup**: Singleton applications in `spawn-at-startup` must have pre-startup cleanup commands.
