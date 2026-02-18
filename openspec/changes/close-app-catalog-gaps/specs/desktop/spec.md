## ADDED Requirements

### Requirement: Office Suite

The desktop module SHALL include LibreOffice with Qt integration for document productivity.

#### Scenario: Default desktop includes LibreOffice

- **WHEN** user enables `desktop.enable = true`
- **THEN** `libreoffice-qt` SHALL be installed
- **AND** the application SHALL inherit Qt theming from the DMS Material You theme engine
- **AND** LibreOffice Writer, Calc, Impress, and Draw SHALL be launchable from Fuzzel

#### Scenario: User opts out of LibreOffice

- **WHEN** user does not want LibreOffice installed
- **THEN** user MAY override `environment.systemPackages` in their `extraConfig` to exclude it
- **AND** no axiOS module changes are required

### Requirement: Hoppscotch Default PWA

Hoppscotch SHALL be included as a default PWA in `pkgs/pwa-apps/pwa-defs.nix`, with its icon in `home/resources/pwa-icons/`, following the same pattern as all other axios-shipped PWAs. Downstream user configs that previously defined Hoppscotch manually can remove their duplicate entries since axios defaults use `mkDefault`.

#### Scenario: Hoppscotch appears in launcher

- **WHEN** user enables `axios.pwa.enable = true` with `includeDefaults = true` (the default)
- **THEN** a `pwa-hoppscotch` launcher script SHALL exist on `$PATH`
- **AND** a Hoppscotch desktop entry SHALL appear in Fuzzel
- **AND** the PWA SHALL use `https://hoppscotch.io/` as its URL
- **AND** the icon SHALL be sourced from `home/resources/pwa-icons/hoppscotch.png`

#### Scenario: Hoppscotch respects PWA browser configuration

- **WHEN** user sets `axios.pwa.browser = "brave"`
- **THEN** Hoppscotch SHALL open in Brave
- **AND** the PWA SHALL inherit GPU acceleration flags from `desktop.browserArgs`

#### Scenario: Downstream override still works

- **WHEN** a user defines `axios.pwa.apps.hoppscotch` in their user config
- **THEN** the user's definition SHALL override the axios default (since defaults use `mkDefault`)
- **AND** no conflict or duplicate entry SHALL occur

## MODIFIED Requirements

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
  - Productivity (Okular, Qalculate-qt, Swappy, LibreOffice-Qt)
  - System utilities (lxqt-openssh-askpass, pavucontrol, ImageMagick, libnotify)
  - Wayland tools (Fuzzel, wtype, playerctl, wf-recorder, slurp, swaybg)
  - PWAs (Hoppscotch)
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
