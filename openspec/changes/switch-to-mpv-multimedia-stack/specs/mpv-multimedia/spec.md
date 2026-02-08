## ADDED Requirements

### Requirement: Unified media playback via mpv

mpv SHALL serve as the primary audio and video player, using FFmpeg for decoding and PipeWire for audio output, with no GStreamer dependencies. The uosc script provides a modern on-screen controller UI.

#### Scenario: User plays a video file

- **WHEN** user opens a video file (mp4, mkv, webm, etc.) from Dolphin or command line
- **THEN** mpv launches and plays the video with hardware-accelerated decoding if available
- **AND** audio outputs through PipeWire
- **AND** no GStreamer plugins are loaded

#### Scenario: User plays an audio file

- **WHEN** user opens an audio file (mp3, flac, ogg, etc.) from Dolphin or command line
- **THEN** mpv launches and plays the audio through PipeWire
- **AND** a minimal OSD shows playback information

#### Scenario: Hardware acceleration detection

- **WHEN** mpv starts playback on a system with AMD, NVIDIA, or Intel GPU
- **THEN** mpv uses `hwdec=auto` to detect and enable VA-API, NVDEC, or equivalent
- **AND** decoding happens on GPU when the codec supports it

### Requirement: PipeWire audio configuration

mpv SHALL be configured to use PipeWire directly for audio output, bypassing PulseAudio compatibility layer where possible.

#### Scenario: mpv audio output configuration

- **WHEN** mpv is installed via home-manager
- **THEN** `audio-output=pipewire` is set in mpv configuration
- **AND** audio latency is minimized compared to pulse backend

#### Scenario: Audio device selection

- **WHEN** user has multiple audio outputs (speakers, headphones, HDMI)
- **THEN** mpv respects PipeWire's default device selection
- **AND** user can override via `--audio-device` flag or config

### Requirement: MIME type associations

mpv SHALL be the default handler for common audio and video MIME types.

#### Scenario: Video MIME types

- **WHEN** xdg-mime queries the default handler for `video/mp4`, `video/x-matroska`, `video/webm`, or other video types
- **THEN** `mpv.desktop` is returned as the default application

#### Scenario: Audio MIME types

- **WHEN** xdg-mime queries the default handler for `audio/mpeg`, `audio/flac`, `audio/ogg`, or other audio types
- **THEN** `mpv.desktop` is returned as the default application

#### Scenario: Opening from file manager

- **WHEN** user double-clicks a media file in Dolphin
- **THEN** mpv opens and plays the file
- **AND** the file manager does not prompt for application selection

### Requirement: Keyboard-driven interface

mpv SHALL provide efficient keyboard controls aligned with the tiling window manager workflow.

#### Scenario: Basic playback controls

- **WHEN** mpv is playing media
- **THEN** Space toggles play/pause
- **AND** Left/Right arrows seek backward/forward
- **AND** Up/Down arrows adjust volume
- **AND** q quits the player

#### Scenario: Playlist navigation

- **WHEN** mpv is playing a directory or playlist
- **THEN** `>` and `<` navigate to next/previous item
- **AND** Enter on a file in playlist selects it

### Requirement: Minimal visual footprint

mpv SHALL display minimal UI chrome to integrate with the tiling desktop aesthetic.

#### Scenario: Default window appearance

- **WHEN** mpv opens a video file
- **THEN** the window shows only the video content (no menubar, toolbar)
- **AND** OSD appears only on user interaction or state changes
- **AND** the window respects Niri's window rules (rounded corners, no CSD)

#### Scenario: Audio-only playback

- **WHEN** mpv plays an audio file
- **THEN** a minimal window appears with album art if available
- **OR** a small placeholder window if no art exists
- **AND** the window can be minimized while playback continues
