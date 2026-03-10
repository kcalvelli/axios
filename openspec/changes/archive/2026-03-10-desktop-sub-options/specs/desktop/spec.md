## MODIFIED Requirements

### Requirement: Curated Application Set

The desktop module SHALL organize applications into toggleable sub-groups, each with an independent enable option defaulting to `true`. Core desktop packages (file management, theming, launchers, system utilities, Wayland tools) SHALL always be installed when `desktop.enable = true`. Optional groups (media, office, streaming, social) SHALL be independently disableable.

#### Scenario: Default desktop installation (all sub-options true)

- **WHEN** user enables `desktop.enable = true`
- **AND** all sub-options are at their defaults (`true`)
- **THEN** the following application categories are present:
  - Core: File management (Dolphin, Ark, Filelight), launchers (Fuzzel), theming, system utilities, Wayland tools
  - Media: Gwenview, Tauon, FFmpeg, wf-recorder, Swappy, Krita
  - Office: LibreOffice-qt, Ghostwriter, Okular, Qalculate-qt, Filelight
  - Streaming: OBS Studio (gamemode-wrapped), Discord
  - Social: Materialgram, Spotify, Zenity

#### Scenario: User disables streaming apps

- **WHEN** user sets `desktop.streaming.enable = false`
- **THEN** OBS Studio and Discord MUST NOT be in `environment.systemPackages`
- **AND** all other desktop groups (core, media, office, social) remain functional

#### Scenario: User disables office apps

- **WHEN** user sets `desktop.office.enable = false`
- **THEN** LibreOffice-qt, Ghostwriter, Okular, Qalculate-qt, and Filelight MUST NOT be in `environment.systemPackages`
- **AND** all other desktop groups remain functional

#### Scenario: User disables media apps

- **WHEN** user sets `desktop.media.enable = false`
- **THEN** Gwenview, Tauon, FFmpeg, wf-recorder, Swappy, and Krita MUST NOT be in `environment.systemPackages`
- **AND** all other desktop groups remain functional

#### Scenario: User disables social apps

- **WHEN** user sets `desktop.social.enable = false`
- **THEN** Materialgram, Spotify, and Zenity MUST NOT be in `environment.systemPackages`
- **AND** all other desktop groups remain functional

## REMOVED Requirements

### Requirement: Profanity XMPP client
**Reason**: Redundant with Gajim. One XMPP client is sufficient.
**Migration**: Users who need profanity can add it via `extraConfig.environment.systemPackages`.

### Requirement: C64term retro terminal
**Reason**: Novelty package not appropriate for a library/framework default.
**Migration**: Users who want c64term can add it via `extraConfig.environment.systemPackages`.

### Requirement: Gajim in desktop module
**Reason**: XMPP client belongs with chat/PIM configuration, not the desktop module.
**Migration**: Users who need gajim can add it via `extraConfig.environment.systemPackages` or a future chat module.
