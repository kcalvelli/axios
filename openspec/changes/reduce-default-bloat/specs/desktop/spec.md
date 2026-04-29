## ADDED Requirements

### Requirement: Individual browser enable flags

The desktop module SHALL expose individual enable options for each supported browser channel under `desktop.browsers`. Only Brave stable SHALL default to enabled. All other browsers SHALL default to disabled.

#### Scenario: Default desktop has only Brave stable

- **WHEN** user enables `desktop.enable = true`
- **AND** no `desktop.browsers.*` options are set
- **THEN** Brave stable is installed with extensions and GPU-aware command-line flags
- **AND** Brave Nightly, Brave Beta, Brave Origin, and Google Chrome are NOT installed
- **AND** Brave is set as the default browser for http/https MIME types

#### Scenario: User enables additional browser channels

- **WHEN** user sets `desktop.browsers.braveNightly.enable = true`
- **AND** user sets `desktop.browsers.chrome.enable = true`
- **THEN** Brave Nightly, Google Chrome, AND Brave stable are all installed
- **AND** each browser receives GPU-aware command-line flags from `desktop.browserArgs`

#### Scenario: User disables Brave stable

- **WHEN** user sets `desktop.browsers.brave.enable = false`
- **AND** no other browser is enabled
- **THEN** no standalone browser is installed by the desktop module
- **AND** the PWA module's browser backend (if enabled) is unaffected

#### Scenario: User enables Brave Beta

- **WHEN** user sets `desktop.browsers.braveBeta.enable = true`
- **THEN** `programs.brave-beta.enable` is set to `true` on the `brave-browser-previews` NixOS module
- **AND** the browser receives GPU-aware command-line flags via `programs.brave-beta.commandLineArgs`
- **AND** Brave stable remains enabled (independent flag)

#### Scenario: User enables Brave Origin

- **WHEN** user sets `desktop.browsers.braveOrigin.enable = true`
- **THEN** `programs.brave-origin-nightly.enable` is set to `true` on the `brave-browser-previews` NixOS module
- **AND** the browser receives GPU-aware command-line flags via `programs.brave-origin-nightly.commandLineArgs`

## MODIFIED Requirements

### Requirement: Curated Application Set

The desktop module SHALL organize applications into toggleable sub-groups, each with an independent enable option defaulting to `true`. Core desktop packages (file management, theming, launchers, system utilities, Wayland tools) SHALL always be installed when `desktop.enable = true`. Optional groups (media, office, streaming, social) SHALL be independently disableable. Browser installation SHALL be controlled by individual `desktop.browsers.*` flags rather than being unconditional.

#### Scenario: Default desktop installation (all sub-options true)

- **WHEN** user enables `desktop.enable = true`
- **AND** all sub-options are at their defaults (`true`)
- **THEN** the following application categories are present:
  - Core: File management (Dolphin, Ark), launchers (Fuzzel), theming, system utilities (Mousepad, lxqt-openssh-askpass, pavucontrol, ImageMagick, libnotify), Wayland tools (wtype, playerctl, slurp, swaybg)
  - Browsers (`desktop.browsers.*`): Brave stable (default enabled), others opt-in
  - Media (`desktop.media.enable`): Gwenview, Tauon, FFmpeg, wf-recorder, Swappy, Krita
  - Office (`desktop.office.enable`): LibreOffice-qt, Ghostwriter, Okular, Qalculate-qt, Filelight
  - Streaming (`desktop.streaming.enable`): OBS Studio (gamemode-wrapped), Discord
  - Social (`desktop.social.enable`): Materialgram, Spotify, Zenity
- **AND** DMS community plugins are available via `programs.dank-material-shell.plugins`
- **AND** core Niri plugins (displayManager, niriWindows, niriScreenshot, dankKDEConnect) are auto-enabled
- **AND** conditional plugins are enabled based on system module flags
- **AND** nixMonitor plugin is explicitly disabled (cairn-monitor provides this)

#### Scenario: User disables a sub-group

- **WHEN** user sets any sub-option to `false` (e.g., `desktop.streaming.enable = false`)
- **THEN** packages in that group MUST NOT be in `environment.systemPackages`
- **AND** all other desktop groups remain functional
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
- **AND** no Cairn modules need to be modified
