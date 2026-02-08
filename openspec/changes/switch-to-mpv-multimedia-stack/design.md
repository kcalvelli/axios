## Context

The current axiOS desktop module uses GStreamer as the Qt6 multimedia backend. This architecture has proven unreliable on NixOS:

1. **Symbol mismatch crashes**: GStreamer plugins are loaded via `g_io_module_load`, but NixOS's isolated store paths can cause glib version mismatches, leading to `undefined symbol` errors
2. **Race conditions**: Qt6Multimedia/GStreamer initialization races with PipeWire, causing DMS/Quickshell SIGSEGV at boot
3. **Complexity**: 6+ GStreamer packages, environment variables (`QT_MEDIA_BACKEND`, `GST_PLUGIN_SYSTEM_PATH_1_0`), and fragile plugin discovery

mpv with FFmpeg offers a simpler, more reliable alternative:
- Direct libavcodec decoding (no plugin system)
- Native PipeWire audio output (`--ao=pipewire`)
- Single package with comprehensive format support
- Lua scripting for UI customization

## Goals / Non-Goals

**Goals:**
- Eliminate GStreamer from the multimedia stack
- Provide reliable audio/video playback via mpv
- Reduce boot-time failures related to multimedia initialization
- Maintain full codec coverage (including hardware acceleration)

**Non-Goals:**
- Music library management (users who need this can install Elisa manually)
- GUI-first video player experience (mpv's keyboard-driven UI is the default)
- Eliminating Qt6Multimedia from Quickshell (DMS may still link it, but won't use it for playback)

## Decisions

### Decision 1: mpv as unified player

**Choice**: Use mpv for both audio and video playback

**Alternatives considered**:
- **VLC**: Heavy, GTK/Qt hybrid, still uses GStreamer for some codecs on Linux
- **Celluloid**: GTK mpv frontend, adds CSD complexity and GTK dependencies
- **Audacious**: Audio-only, would need separate video player

**Rationale**: mpv is lightweight, keyboard-driven (fits tiling WM workflow), has native PipeWire support, and uses FFmpeg directly without GStreamer intermediary.

### Decision 2: Remove Qt-based media players

**Choice**: Remove Elisa and Haruna from default installation

**Alternatives considered**:
- **Keep Elisa, remove GStreamer**: Not possible - Elisa requires Qt6Multimedia which requires a backend
- **Provide migration script**: Unnecessary complexity for a niche use case

**Rationale**: Users who need library management can install Elisa manually. The goal is a working default, not covering every use case.

### Decision 3: Configure mpv via home-manager

**Choice**: Use `programs.mpv` in home-manager, not system-level

**Alternatives considered**:
- **System-wide mpv.conf**: Less flexible, harder for users to override
- **No configuration**: Would miss PipeWire audio configuration

**Rationale**: home-manager's `programs.mpv` module provides proper option handling, script management, and user-level customization.

### Decision 4: Hardware acceleration via FFmpeg

**Choice**: Use FFmpeg's VA-API/NVDEC support (`hwdec=auto`)

**Alternatives considered**:
- **Force specific hwdec**: Less portable across AMD/NVIDIA/Intel
- **Disable hwdec**: Would lose performance benefits

**Rationale**: `hwdec=auto` lets mpv detect the best available method, maintaining compatibility across GPU vendors without conditional configuration.

## Risks / Trade-offs

**[Risk: Users accustomed to Elisa/Haruna UI]** → Mitigation: Document how to install them manually; they'll still work with GStreamer if users add it themselves

**[Risk: Dolphin media previews break]** → Mitigation: Test KIO thumbnail generation; may need `ffmpegthumbs` package

**[Risk: Other Qt apps need Qt6Multimedia]** → Mitigation: Qt6Multimedia remains available, just without GStreamer backend configured; apps that don't need audio/video will be unaffected

**[Trade-off: No music library]** → mpv can play directories/playlists but lacks Elisa's metadata browsing; acceptable for the "file manager + player" workflow
