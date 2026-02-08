## 1. Remove GStreamer from desktop module

- [x] 1.1 Remove GStreamer packages from `modules/desktop/default.nix` (gstreamer, gst-plugins-base, gst-plugins-good, gst-plugins-bad, gst-plugins-ugly, gst-libav)
- [x] 1.2 Remove `QT_MEDIA_BACKEND` environment variable from `modules/desktop/default.nix`
- [x] 1.3 Remove `GST_PLUGIN_SYSTEM_PATH_1_0` environment variable from `modules/desktop/default.nix`
- [x] 1.4 Remove Elisa (`kdePackages.elisa`) from package list
- [x] 1.5 Remove Haruna (`kdePackages.haruna`) from package list (note: keep mpv which is already present)

## 2. Configure mpv in home-manager

- [x] 2.1 Create `home/desktop/mpv.nix` with `programs.mpv` configuration
- [x] 2.2 Configure mpv with `hwdec=auto` for hardware acceleration
- [x] 2.3 Configure mpv with `ao=pipewire` for PipeWire audio output
- [x] 2.4 Add sensible default keybindings and OSD settings
- [x] 2.5 Import `mpv.nix` in `home/desktop/default.nix`

## 3. Update MIME type associations

- [x] 3.1 Update video MIME types in `home/desktop/default.nix` to use `mpv.desktop` (replace Haruna associations)
- [x] 3.2 Update audio MIME types in `home/desktop/default.nix` to use `mpv.desktop` (replace Elisa associations)

## 4. Update documentation

- [x] 4.1 Update `docs/APPLICATIONS.md` "Media Viewing & Playback" section: replace Haruna and Elisa entries with mpv
- [x] 4.2 Update `docs/APPLICATIONS.md` to explain mpv is unified audio/video player with FFmpeg backend
- [x] 4.3 Add note in `docs/APPLICATIONS.md` about installing Elisa/Haruna manually if users need them
- [x] 4.4 Update `docs/TROUBLESHOOTING.md` with note about GStreamer removal and manual installation if needed

## 5. Verify and format

- [x] 5.1 Run `nix fmt .` to format all modified Nix files
- [x] 5.2 Run `nix flake check` to verify configuration validity
- [ ] 5.3 Test that mpv opens video files correctly
- [ ] 5.4 Test that mpv opens audio files correctly
- [ ] 5.5 Verify DMS/Quickshell starts without Qt6Multimedia crashes
