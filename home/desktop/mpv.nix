# mpv configuration - unified audio/video player with FFmpeg backend
#
# Uses FFmpeg for decoding (no GStreamer) and PipeWire for audio output.
# Hardware acceleration via hwdec=auto (VA-API, NVDEC, etc.)
# Frontend: uosc (modern on-screen controller with thumbnails)
{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  programs.mpv = {
    enable = true;

    # === Scripts ===
    # uosc: Modern, feature-rich on-screen controller
    # thumbfast: Thumbnails on the seek bar
    # mpris: D-Bus integration for media keys and playerctl
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
      mpris
    ];

    config = {
      # === Audio Output ===
      # Use PipeWire directly (bypasses PulseAudio compatibility layer)
      ao = "pipewire";

      # === Hardware Acceleration ===
      # Auto-detect best available method (VA-API, NVDEC, VDPAU, etc.)
      hwdec = "auto";

      # === Video Output ===
      # GPU-accelerated video output
      vo = "gpu";
      gpu-api = "vulkan";
      gpu-context = "waylandvk";

      # === uosc Configuration ===
      # Disable default OSD (uosc provides its own)
      osd-bar = "no";
      osc = "no";
      # Border for uosc's streaming title display
      border = "no";

      # === Window Behavior ===
      # Keep window open after playback (useful for playlists)
      keep-open = "yes";
      # Start with reasonable window size
      autofit = "80%";

      # === Audio Normalization ===
      # Normalize audio levels across different media
      af = "lavfi=[loudnorm]";

      # === Subtitles ===
      # Auto-load subtitles with matching filename
      sub-auto = "fuzzy";
      sub-font-size = 40;

      # === Cache Settings ===
      # Reasonable cache for network streams
      cache = "yes";
      demuxer-max-bytes = "512MiB";
      demuxer-max-back-bytes = "128MiB";
    };

    # === Script Options ===
    scriptOpts = {
      # uosc configuration
      uosc = {
        # Progress bar always visible at bottom
        progress = "windowed";
        # Timeline style with chapters
        timeline_style = "bar";
        # Volume control style
        volume = "right";
        # Speed display
        speed = true;
        # Proximity controls (show UI on mouse movement)
        proximity_in = 40;
        proximity_out = 80;
      };

      # thumbfast configuration
      thumbfast = {
        # Thumbnail dimensions
        max_height = 200;
        max_width = 200;
        # Use hardware decoding for thumbnails if available
        hwdec = true;
      };
    };

    # === Keybindings ===
    # Most UI interactions handled by uosc, these are keyboard shortcuts
    bindings = {
      # Playback
      "SPACE" = "cycle pause";
      "p" = "cycle pause";

      # Seeking (uosc provides visual feedback)
      "LEFT" = "seek -5";
      "RIGHT" = "seek 5";
      "Shift+LEFT" = "seek -30";
      "Shift+RIGHT" = "seek 30";
      "Ctrl+LEFT" = "seek -60";
      "Ctrl+RIGHT" = "seek 60";

      # Volume
      "UP" = "add volume 5";
      "DOWN" = "add volume -5";
      "m" = "cycle mute";

      # Playlist
      ">" = "playlist-next";
      "<" = "playlist-prev";
      "ENTER" = "playlist-next";

      # Speed
      "[" = "multiply speed 0.9";
      "]" = "multiply speed 1.1";
      "BS" = "set speed 1.0";

      # Fullscreen
      "f" = "cycle fullscreen";
      "ESC" = "set fullscreen no";

      # Subtitles
      "v" = "cycle sub-visibility";
      "j" = "cycle sub";
      "J" = "cycle sub down";

      # Audio tracks
      "a" = "cycle audio";

      # Screenshot
      "s" = "screenshot";
      "S" = "screenshot video";

      # uosc menus (right-click also works)
      "tab" = "script-binding uosc/flash-ui";
      "menu" = "script-binding uosc/menu";

      # Quit
      "q" = "quit";
      "Q" = "quit-watch-later";
    };
  };
}
