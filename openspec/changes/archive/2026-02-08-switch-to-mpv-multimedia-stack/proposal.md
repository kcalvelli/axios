## Why

The current multimedia stack uses GStreamer as the Qt6 multimedia backend, which has caused boot failures due to glib symbol mismatches and race conditions with PipeWire initialization. The GStreamer plugin architecture is fragile on NixOS due to dynamic module loading that doesn't work reliably with the Nix store's immutable paths. Switching to mpv with FFmpeg/libavcodec and native PipeWire audio eliminates this entire class of problems.

## What Changes

- **BREAKING**: Remove `kdePackages.elisa` (Qt/GStreamer music player) → replaced by mpv-based solution
- **BREAKING**: Remove `kdePackages.haruna` (Qt/GStreamer video player) → replaced by mpv
- Remove GStreamer packages (`gstreamer`, `gst-plugins-base`, `gst-plugins-good`, `gst-plugins-bad`, `gst-plugins-ugly`, `gst-libav`)
- Remove `QT_MEDIA_BACKEND` and `GST_PLUGIN_SYSTEM_PATH_1_0` environment variables
- Add mpv as the unified media player with FFmpeg backend and PipeWire audio output
- Update MIME type associations to use mpv for audio and video
- Simplify multimedia dependencies: only mpv + ffmpeg needed

## Capabilities

### New Capabilities

- `mpv-multimedia`: mpv-based unified audio/video playback configuration with FFmpeg decoding and PipeWire audio, replacing GStreamer-dependent Qt applications

### Modified Capabilities

- `desktop`: Removal of GStreamer packages, Qt multimedia environment variables, and Qt-based media players; updated application set and MIME associations

## Impact

- **Files**: `modules/desktop/default.nix`, `home/desktop/default.nix`
- **Dependencies**: Removes ~6 GStreamer packages, removes Elisa and Haruna; adds mpv configuration
- **User Impact**: Users who prefer Elisa's library management or Haruna's UI will need to install them manually via `extraConfig`
- **DMS**: Quickshell's Qt6Multimedia dependency may still exist but won't be triggered for audio/video playback since no GStreamer backend is configured
- **Boot Stability**: Eliminates GStreamer-related race conditions and symbol mismatch crashes
