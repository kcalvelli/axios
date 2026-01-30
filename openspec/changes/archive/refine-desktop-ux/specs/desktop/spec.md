# Desktop Environment (Delta: refine-desktop-ux)

## MODIFIED Requirements

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

- **Given**: User enables `desktop.enable = true`
- **When**: System builds
- **Then**: The following application categories are present:
  - File management (Dolphin, Ark, Filelight)
  - Text editing (Mousepad for simple editing, Ghostwriter for Markdown)
  - Media playback (Haruna, MPV, FFmpeg, Gwenview, Elisa)
  - Media creation (Krita for drawing, OBS for recording)
  - Communication (Discord, Gajim, Profanity, Syncterm)
  - Productivity (Okular, Qalculate-qt, Swappy)
  - System utilities (ksshaskpass, pavucontrol, ImageMagick, libnotify)
  - Wayland tools (Fuzzel, wtype, playerctl, wf-recorder, slurp, swaybg)
- **And**: Database tools (DBeaver) are NOT included by default
- **And**: Heavy photo managers (DigiKam) are NOT included by default
- **And**: Vector editors (Inkscape) are NOT included by default
- **And**: File sharing tools (LocalSend) are NOT included by default
- **And**: Graphics debuggers (RenderDoc) are NOT included by default
- **And**: Tailscale tray apps (Trayscale) are NOT included by default (DMS provides VPN widget)

#### Scenario: User needs a removed application

- **Given**: User wants to use Inkscape for vector graphics
- **When**: User adds `inkscape` to their `extraConfig.environment.systemPackages`
- **Then**: Inkscape is installed and fully functional
- **And**: No axiOS modules need to be modified

### Requirement: SSD-Consistent Application Selection

All primary desktop applications respect the compositor's `prefer-no-csd` setting. Brief utility windows (screenshot annotation, audio control) are exempt.

#### Scenario: User opens any default application

- **Given**: Niri is running with `prefer-no-csd = true`
- **When**: User opens any application from the default desktop set
- **Then**: The application uses server-side decorations (compositor-drawn titlebar)
- **And**: The application's appearance is visually consistent with other windows

#### Scenario: Brief utility exceptions

- **Given**: Swappy (screenshot annotation) or Pavucontrol (audio routing) is opened
- **When**: The window appears
- **Then**: CSD may be visible (these are brief utility windows)
- **And**: This is acceptable because these are transient tools, not primary work surfaces

## ADDED Requirements

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

## REMOVED Requirements

_None. Existing requirements in the desktop spec are retained or modified above._
