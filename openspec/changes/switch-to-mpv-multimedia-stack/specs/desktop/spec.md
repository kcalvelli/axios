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

## REMOVED Requirements

### Requirement: GStreamer environment configuration

**Reason**: GStreamer causes boot instability due to glib symbol mismatches and race conditions with PipeWire. Replaced by mpv/FFmpeg stack.

**Migration**:
- Media playback now uses mpv with FFmpeg decoding
- Users who need GStreamer for specific Qt apps must configure it manually:
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
