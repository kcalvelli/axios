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

## Session Lifecycle Management

### Ghostty Singleton Mode
Ghostty is managed via **systemd user service** (`app-com.mitchellh.ghostty.service`) for proper lifecycle management:
- **Startup**: Automatically starts on `graphical-session.target`
- **Singleton mode**: `--gtk-single-instance=true` for instant window creation
- **Resident process**: `--quit-after-last-window-closed=false` keeps process alive for drop-down terminal
- **Zombie prevention**: Systemd handles cleanup on logout/crash (no manual pkill needed)

Performance benefits:
- **First launch**: Slow (~300ms-1s) due to GTK initialization overhead
- **Subsequent windows**: Near-instant (~10-50ms) as they reuse the existing process
- **Memory**: Shared process reduces memory usage with multiple terminals

**Implementation**: `home/terminal/ghostty.nix` (service override), NOT spawn-at-startup

### Known Upstream Stability Issues

#### DMS/Quickshell SIGSEGV at Greeter
- **Status**: Known issue, upstream dependency (quickshell)
- **Impact**: Occasional greeter session crash before login
- **Workaround**: Re-attempt login; usually succeeds on second try
- **Contributing factors**: May be exacerbated by GPU memory pressure from previous ollama sessions (see GPU Correlation below)

#### kded6 SIGABRT at Session Startup
- **Status**: Known issue, upstream (KDE)
- **Impact**: KDE services may not start properly on first login
- **Workaround**: Services usually recover; manual restart via `kded6` if needed

## Requirements

### Requirement: GPU Resource Correlation Awareness

Desktop session stability correlates with GPU memory state; axiOS documents this relationship to aid troubleshooting.

#### Scenario: Login after heavy ollama usage

- **Given**: User ran large model inference before logout
- **And**: ROCm had queue evictions during the session
- **When**: User logs back in and greeter starts quickshell
- **Then**: quickshell MAY have increased crash probability
- **And**: User SHOULD know to check AI spec's GPU troubleshooting section

#### Scenario: Stable session startup

- **Given**: Ollama models were unloaded before logout (via keepAlive timeout or manual unload)
- **And**: No queue evictions occurred in previous session
- **When**: User logs in
- **Then**: Greeter SHOULD start normally with low crash probability

## Constraints
- **Wayland Compatibility**: All desktop components must be Wayland-native.
- **Spawn Order**: DMS must spawn after `dbus-update-activation-environment` to ensure session variables are available.
- **Singleton Cleanup**: Singleton applications in `spawn-at-startup` must have pre-startup cleanup commands.
- **GPU Resource Sharing**: Desktop GPU usage must coexist with AI inference; see AI spec for memory reservation guidance.

## Troubleshooting

### Frequent Quickshell Crashes at Login

If DMS/Quickshell crashes frequently at greeter startup:

1. **Check if ollama was running heavy workloads**: `journalctl -u ollama --since "1 hour ago" | grep -E "evict|timeout|discovery"`
2. **Unload ollama models before logout**: `curl -X DELETE http://localhost:11434/api/generate` or wait for keepAlive timeout
3. **Reduce ollama context window**: Lower `OLLAMA_NUM_CTX` reduces VRAM footprint
4. **Use smaller models**: See AI spec model size guidance

If crashes persist without ollama correlation, this is the known upstream quickshell issue.
