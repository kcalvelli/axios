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

**Email**: axios-ai-mail - AI-powered email management with local LLM classification.
- Multi-account support (Gmail OAuth, IMAP/SMTP)
- Privacy-first local processing via Ollama
- Modern web UI with PWA support
- Tailscale integration for cross-device access

**Calendar**: vdirsyncer + khal + PWA apps
- Automated CalDAV sync via systemd timers
- khal CLI for DMS calendar widget integration
- PWA apps for graphical interface (user's choice)

**Contacts**: Cloud provider UIs or PWA apps
- Future: axios-ai-mail contacts module (planned)

**Implementation**:
- `modules/pim/default.nix` (system services)
- `home/pim/default.nix` (user configuration)
- See `openspec/specs/pim/spec.md` for full documentation

### Application Management
- **PWA support**: Dedicated builder for Progressive Web Apps with configurable browser backend (Chromium, Brave, Chrome).
- **Add-PWA Script**: Automated tool (`scripts/add-pwa.sh`) that installs icons, registers manifest categories, and inserts configuration into `home/desktop/pwa-apps.nix` with auto-formatting.
- **Implementation**: `modules/desktop/default.nix`, `home/desktop/pwa-apps.nix`, `scripts/add-pwa.sh`

### Requirement: Configurable PWA Backend

The PWA system SHALL allow selecting the underlying browser engine to balance privacy, open-source compliance, and feature support (DRM, Push API). A global default can be set, and individual apps can override it.

#### Scenario: Default Configuration (Chromium)

- **Given**: User does not specify a PWA browser
- **When**: PWA apps are generated
- **Then**: `pkgs.chromium` is used as the backend
- **And**: Push notifications work out-of-the-box (standard Chromium)
- **And**: WMClass is `chrome-{domain}-Default` (Chromium uses `chrome` prefix internally)

#### Scenario: Brave Preference

- **Given**: User sets `axios.pwa.browser = "brave"`
- **When**: PWA apps are generated
- **Then**: `pkgs.brave` is used
- **And**: WMClass is `brave-{domain}-Default`
- **And**: User accepts manual push notification configuration (per profile)

#### Scenario: Chrome Preference

- **Given**: User sets `axios.pwa.browser = "google-chrome"`
- **When**: PWA apps are generated
- **Then**: `pkgs.google-chrome` is used
- **And**: WMClass is `chrome-{domain}-Default`

#### Scenario: Per-App Browser Override

- **Given**: User sets `axios.pwa.apps.youtube-music.browser = "brave"`
- **And**: Global `axios.pwa.browser` is `"chromium"`
- **When**: PWA apps are generated
- **Then**: YouTube Music uses `pkgs.brave` (Widevine DRM support)
- **And**: All other apps use `pkgs.chromium`
- **And**: Both browser packages are installed automatically

### Requirement: PWA Launcher Scripts

Each PWA SHALL have a `pwa-{appId}` launcher script on `$PATH`, decoupling keybinds and desktop entries from browser selection.

#### Scenario: Launching via keybind

- **Given**: `axios.pwa.apps.google-messages` is defined
- **When**: User presses `Mod+G` (bound to `pwa-google-messages`)
- **Then**: Google Messages opens in the configured browser
- **And**: Changing `axios.pwa.browser` automatically updates the launcher

#### Scenario: Desktop entry exec

- **Given**: A PWA desktop entry is generated
- **When**: User launches the app from the application menu
- **Then**: `Exec=pwa-{appId}` is used (not a raw browser command)
- **And**: The launcher respects per-app browser overrides

#### Scenario: PWA inherits browser hardware acceleration flags

- **Given**: `axios.hardware.gpuType` is set to `"amd"` or `"nvidia"`
- **And**: `desktop.browserArgs` exposes computed acceleration flags per browser
- **When**: A PWA launcher script is generated
- **Then**: The launcher exec line includes all flags from `desktop.browserArgs` for the effective browser
- **And**: Flags appear before `--app=` in the command line
- **And**: The PWA has identical GPU acceleration behavior to launching the URL in the browser directly

#### Scenario: PWA launch without GPU configuration

- **Given**: `axios.hardware.gpuType` is not set (null)
- **When**: A PWA launcher script is generated
- **Then**: Only base args (`--password-store=detect`) are included
- **And**: No GPU-specific flags are added

### Requirement: Browser Args Exposure

The desktop module SHALL expose computed browser command-line arguments as a read-only NixOS option (`desktop.browserArgs`) so that downstream modules (including home-manager PWA generation) can consume GPU-aware flags without duplicating detection logic.

#### Scenario: Home-manager module reads browser args

- **Given**: `desktop.enable = true`
- **And**: `axios.hardware.gpuType = "amd"`
- **When**: `pwa-apps.nix` evaluates
- **Then**: `osConfig.desktop.browserArgs.brave` contains AMD acceleration flags
- **And**: `osConfig.desktop.browserArgs.chromium` contains the same flags
- **And**: `osConfig.desktop.browserArgs.google-chrome` contains the same flags

#### Scenario: Chromium receives acceleration flags

- **Given**: `desktop.enable = true` (previously Chromium had no flags)
- **When**: System builds
- **Then**: `programs.chromium.commandLineArgs` includes GPU acceleration flags
- **And**: Chromium (the default PWA browser) has hardware acceleration parity with Brave and Chrome

### Requirement: Centralized PWA Definition

PWA applications (PIM, Immich, generic apps) SHALL be defined via a central `axios.pwa.apps` option to ensure consistency.

#### Scenario: Module Registration

- **Given**: `pim` module is enabled
- **When**: Configuration is evaluated
- **Then**: `pim` module sets `axios.pwa.apps.axios-mail`
- **And**: `desktop` module consumes this definition to generate the desktop entry and launcher
- **And**: `desktop` module applies the global or per-app browser setting

#### Scenario: Unified URL Generation

- **Given**: `immich` module is enabled (server role)
- **When**: PWA definition is created
- **Then**: URL is `https://axios-immich.<tailnet>/` (unified via loopback proxy)
- **And**: Desktop entry uses this URL, ensuring consistent app_id across devices


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

### Requirement: File Manager Integration

Dolphin is configured to use Ghostty as its terminal emulator, and KDE Activities (unused in Niri) are hidden from the UI.

#### Scenario: User opens terminal from Dolphin context menu

- **Given**: User is browsing files in Dolphin
- **When**: User right-clicks and selects "Open Terminal Here" (or presses Shift+F4)
- **Then**: Ghostty opens in the selected directory
- **And**: The Ghostty window uses the singleton daemon (instant launch)

#### Scenario: User views Dolphin context menu

- **Given**: User right-clicks in Dolphin's file view
- **When**: The context menu appears
- **Then**: There is no "Activities" menu item visible
- **And**: All other standard context menu items remain functional

### Requirement: Flatpak Installation Handler

Clicking "Install" on the Flathub website triggers a transparent, terminal-based installation flow.

#### Scenario: User installs app from Flathub

- **Given**: User visits flathub.org in Brave browser
- **And**: Flatpak service is enabled
- **When**: User clicks "Install" on an application page
- **Then**: Browser downloads the `.flatpakref` file
- **And**: A small, floating Ghostty terminal window opens (not full screen) showing the flatpak install command
- **And**: User sees the application name and is prompted to confirm (y/N)
- **And**: Installation progress is visible in the terminal

#### Scenario: Flatpak installation completes

- **Given**: User confirmed the installation
- **When**: `flatpak install` completes successfully
- **Then**: Terminal displays a success message
- **And**: User presses Enter to close the terminal
- **And**: The installed application appears in the application launcher

#### Scenario: Flatpak installation fails

- **Given**: Installation fails (network error, permission issue, etc.)
- **When**: `flatpak install` exits with non-zero status
- **Then**: Terminal displays the error message from flatpak
- **And**: User can read the error and press Enter to close

### Requirement: Drop-down Terminal Identity

The drop-down terminal uses a proper axiOS app-id and does not appear in the DMS dock.

#### Scenario: User toggles drop-down terminal

- **Given**: User presses Mod+` (backtick)
- **When**: The drop-down terminal appears
- **Then**: Its app-id is `com.github.kcalvelli.axios.dropterm`
- **And**: It does not appear as a separate icon in the DMS dock
- **And**: It floats at the top of the screen under the panel (existing behavior)

#### Scenario: User views dock with drop-down terminal open

- **Given**: The drop-down terminal is currently visible
- **When**: User looks at the DMS dock/taskbar
- **Then**: There is no icon or entry for the drop-down terminal

### Requirement: Curated Application Set

The desktop module ships a focused set of applications aligned with the axiOS profile (productivity, development, system administration). Creative and niche tools are available via user configuration.

#### Scenario: Default desktop installation

- **WHEN** user enables `desktop.enable = true`
- **THEN** the following application categories are present:
  - File management (Dolphin, Ark, Filelight)
  - Text editing (Mousepad for simple editing, Ghostwriter for Markdown)
  - Media playback (mpv, FFmpeg, Gwenview)
  - Media creation (Krita for drawing, OBS for recording)
  - Communication (Discord, Gajim, Profanity, Syncterm)
  - Productivity (Okular, Qalculate-qt, Swappy)
  - System utilities (lxqt-openssh-askpass, pavucontrol, ImageMagick, libnotify)
  - Wayland tools (Fuzzel, wtype, playerctl, wf-recorder, slurp, swaybg)
- **AND** Elisa (Qt music player) is NOT included by default
- **AND** Haruna (Qt video player) is NOT included by default
- **AND** GStreamer packages are NOT included by default
- **AND** Database tools (DBeaver) are NOT included by default
- **AND** Heavy photo managers (DigiKam) are NOT included by default
- **AND** Vector editors (Inkscape) are NOT included by default
- **AND** File sharing tools (LocalSend) are NOT included by default
- **AND** Graphics debuggers (RenderDoc) are NOT included by default
- **AND** Tailscale tray apps (Trayscale) are NOT included by default (DMS provides VPN widget)

#### Scenario: User needs a removed application

- **GIVEN** user wants to use Elisa for music library management
- **WHEN** user adds `kdePackages.elisa` and GStreamer packages to their `extraConfig.environment.systemPackages`
- **THEN** Elisa is installed and fully functional
- **AND** user must also set `QT_MEDIA_BACKEND` and `GST_PLUGIN_SYSTEM_PATH_1_0` environment variables
- **AND** no axiOS modules need to be modified

### Requirement: GStreamer is not included by default

**Rationale**: GStreamer causes boot instability due to glib symbol mismatches and race conditions with PipeWire. Media playback uses mpv with FFmpeg decoding instead.

#### Scenario: User needs GStreamer for specific Qt apps

- **GIVEN** user needs GStreamer for a specific Qt application
- **WHEN** user configures it manually in their `extraConfig`
- **THEN** the following packages and environment variables are required:
  ```nix
  environment.systemPackages = with pkgs; [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
  ];
  environment.sessionVariables = {
    QT_MEDIA_BACKEND = "gstreamer";
    GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPath "lib/gstreamer-1.0" [
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
    ];
  };
  ```

### Requirement: SSD-Consistent Application Selection

All primary desktop applications respect the compositor's `prefer-no-csd` setting. Brief utility windows (screenshot annotation, audio control) are exempt. The normie profile uses `prefer-no-csd = false`, so applications draw client-side decorations (titlebars with window controls).

#### Scenario: User opens any default application (standard profile)

- **Given**: Niri is running with `prefer-no-csd = true` (standard profile)
- **WHEN**: User opens any application from the default desktop set
- **THEN**: The application uses server-side decorations (compositor-drawn titlebar)
- **AND**: The application's appearance is visually consistent with other windows

#### Scenario: User opens any default application (normie profile)

- **Given**: Niri is running with `prefer-no-csd = false` (normie profile)
- **WHEN**: User opens any application from the default desktop set
- **THEN**: The application draws its own client-side decorations (titlebar with close/minimize/maximize)
- **AND**: GTK and Qt apps may have slightly different titlebar styles

#### Scenario: Brief utility exceptions

- **Given**: Swappy (screenshot annotation) or Pavucontrol (audio routing) is opened
- **When**: The window appears
- **Then**: CSD may be visible (these are brief utility windows)
- **And**: This is acceptable because these are transient tools, not primary work surfaces

### Requirement: Solaar autostart is hardware-conditional

Solaar autostart SHALL be determined by hardware configuration, not by profile selection. Both standard and normie profiles receive Solaar autostart when Logitech hardware support is enabled.

#### Scenario: System with Logitech support enabled

- **WHEN** `osConfig.hardware.logitech.wireless.enableGraphical` is true
- **THEN** a Solaar autostart desktop entry is created in the user's home
- **AND** Solaar launches with `--window=hide --battery-icons=solaar`
- **AND** this applies to both standard and normie profile users

#### Scenario: System without Logitech support

- **WHEN** `osConfig.hardware.logitech.wireless.enableGraphical` is false or unset
- **THEN** no Solaar autostart entry is created
- **AND** this applies to both standard and normie profile users

### Requirement: AI home modules are profile-conditional

The AI home-manager modules SHALL be imported only for profiles that include developer tooling (currently: standard). They SHALL NOT be applied universally via `sharedModules`.

#### Scenario: Standard user gets AI tools

- **WHEN** a user with `homeProfile = "standard"` is on a host with `modules.ai = true`
- **THEN** `home/ai/` modules are imported for that user
- **AND** AI tool packages, MCP configuration, and system prompts are available

#### Scenario: Normie user does not get AI tools

- **WHEN** a user with `homeProfile = "normie"` is on a host with `modules.ai = true`
- **THEN** `home/ai/` modules are NOT imported for that user
- **AND** no AI packages or configuration files are generated in their home directory
- **AND** the system-level AI NixOS module remains functional for other users

### Requirement: Init script prompts per-user profile

The init script SHALL prompt for each user's profile during user collection instead of deriving the host-level profile from form factor.

#### Scenario: Primary user profile selection

- **WHEN** the init script collects primary user information
- **THEN** it prompts for profile selection: "standard" or "normie"
- **AND** the selection is stored per-user in the generated `users/<name>.nix` file as `homeProfile = "<selection>"`
- **AND** the host-level `homeProfile` defaults to `"standard"`

#### Scenario: Additional user profile selection

- **WHEN** the init script collects an additional user
- **THEN** it prompts for that user's profile: "standard" or "normie"
- **AND** the selection is written to that user's generated config file

#### Scenario: Form factor no longer determines profile

- **WHEN** the init script detects form factor (desktop or laptop)
- **THEN** form factor is used for hardware configuration only
- **AND** form factor does NOT influence the `homeProfile` value
- **AND** the `HOME_PROFILE` derivation from form factor is removed

### Requirement: Default Text Editor

Mousepad serves as the default text editor, providing syntax highlighting and clean editing without IDE-weight features.

#### Scenario: User opens text editor via keybind

- **Given**: User presses Mod+Shift+T
- **When**: Mousepad launches
- **Then**: The window uses server-side decorations (GTK3, traditional menubar)
- **And**: Syntax highlighting works for common languages (Nix, Python, Bash, JSON, YAML, Markdown)
- **And**: The GTK theme (colloid/dank-colors) is applied consistently

#### Scenario: User needs advanced text editing

- **Given**: User needs LSP support, project management, or other advanced features
- **When**: User adds `kdePackages.kate` to their `extraConfig.environment.systemPackages`
- **Then**: Kate is installed with full KTextEditor features
- **And**: Kate inherits DankShell syntax theme if the user also installs the matugen template

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
