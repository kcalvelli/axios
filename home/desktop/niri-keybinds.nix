{ pkgs, ... }:
let
  # Keybinding reference for axios niri configuration
  keybindingGuide = pkgs.writeText "niri-keybindings.txt" ''
    ╔══════════════════════════════════════════════════════════════════╗
    ║              axiOS Niri Keybinding Reference                     ║
    ╚══════════════════════════════════════════════════════════════════╝

    ┌─ APPLICATION LAUNCHERS ──────────────────────────────────────────┐
    │ Mod + Return      Launch Terminal (Ghostty)                      │
    │ Mod + B           Launch Brave Browser                           │
    │ Mod + E           Launch File Manager (Dolphin)                  │
    │ Mod + C           Launch VS Code                                 │
    │ Mod + D           Launch Discord                                 │
    │ Mod + G           Launch Google Messages (PWA)                   │
    │ Mod + `           Toggle Drop-down Terminal (Quake-style)        │
    │ Mod + Shift + T   Launch Text Editor (Kate)                      │
    │ Mod + Shift + C   Launch Calculator (Qalculate)                  │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ WORKSPACE NAVIGATION ───────────────────────────────────────────┐
    │ Mod + 1-8         Switch to workspace 1-8                        │
    │ Mod + Tab         Toggle workspace overview                      │
    │ Mod + Wheel ↑/↓   Focus workspace up/down                        │
    │ Mod + Page Up/Dn  Focus workspace up/down (keyboard)             │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ WINDOW NAVIGATION ──────────────────────────────────────────────┐
    │ Mod + H/←         Focus column left                              │
    │ Mod + J/↓         Focus window down                              │
    │ Mod + K/↑         Focus window up                                │
    │ Mod + L/→         Focus column right                             │
    │ Mod + Z           Switch between floating/tiling                 │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ WINDOW MANAGEMENT ──────────────────────────────────────────────┐
    │ Mod + Q           Close window                                   │
    │ Mod + Shift + F   Toggle fullscreen                              │
    │ Mod + Shift + Z   Toggle window floating                         │
    │ Mod + Shift + H   Move column left                               │
    │ Mod + Shift + J   Move window down                               │
    │ Mod + Shift + K   Move window up                                 │
    │ Mod + Shift + L   Move column right                              │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ MOVE TO WORKSPACE ──────────────────────────────────────────────┐
    │ Mod + Shift + 1-9         Move window to workspace 1-9           │
    │ Mod + Ctrl + Shift + 1-9  Move column to workspace 1-9           │
    │ Mod + Ctrl + Wheel ↑/↓    Move column to workspace up/down       │
    │ Mod + Ctrl + Page Up/Dn   Move column to workspace up/down       │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ COLUMN/LAYOUT MANAGEMENT ───────────────────────────────────────┐
    │ Mod + W           Cycle preset column widths                     │
    │ Mod + -           Decrease column width (-10%)                   │
    │ Mod + =           Increase column width (+10%)                   │
    │ Mod + \           Maximize column                                │
    │ Mod + T           Toggle column tabbed display                   │
    │ Mod + '           Focus column/monitor left                      │
    │ Mod + ;           Focus column/monitor right                     │
    │ Mod + Ctrl + '    Move column to monitor left                    │
    │ Mod + Ctrl + ;    Move column to monitor right                   │
    │ Mod + [           Consume/expel window left                      │
    │ Mod + ]           Consume/expel window right                     │
    │ Mod + Shift + ,   Consume window into column                     │
    │ Mod + Shift + .   Expel window from column                       │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ SCREENSHOTS & RECORDING ────────────────────────────────────────┐
    │ Mod + Shift + S   Screenshot with area selection                 │
    │ Mod + Ctrl + S    Screenshot screen (save to disk)               │
    │ Mod + Alt + S     Screenshot screen (copy to clipboard)          │
    │ Mod + Shift + R   Toggle screen recording (start/stop)           │
    │ Mod + Ctrl + R    Record screen area (with selection)            │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ AUDIO CONTROL (DMS) ────────────────────────────────────────────┐
    │ Mod + Shift + Wheel ← Volume up (+3%) (mouse)                    │
    │ Mod + Shift + Wheel → Volume down (-3%) (mouse)                  │
    │ Mod + Shift + =       Volume up (+3%) (keyboard)                 │
    │ Mod + Shift + -       Volume down (-3%) (keyboard)               │
    │ Mod + Shift + M       Toggle mute                                │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ SYSTEM ─────────────────────────────────────────────────────────┐
    │ Mod + Shift + E   Exit Niri (clean exit)                         │
    │ Mod + Shift + /   Show this keybinding guide                     │
    └──────────────────────────────────────────────────────────────────┘

    ┌─ NOTES ──────────────────────────────────────────────────────────┐
    │ • Mod = Super (Windows key) when running on TTY                  │
    │ • Screenshots saved to: ~/Pictures/Screenshots/                  │
    │ • Screen recordings saved to: ~/Videos/                          │
    │ • Brightness controls provided by DankMaterialShell               │
    └──────────────────────────────────────────────────────────────────┘
  '';

  # Script to display keybindings in a terminal with proper scrolling
  showKeybindings = pkgs.writeShellScript "show-niri-keybindings" ''
    # Use less for scrolling support on all screen sizes
    # -R: handle ANSI colors (from bat)
    # -F: quit if content fits on one screen
    # -X: don't clear screen on exit
    # -S: chop long lines (no wrap, use arrow keys to scroll horizontally)
    ${pkgs.bat}/bin/bat --plain --language txt ${keybindingGuide} 2>/dev/null | ${pkgs.less}/bin/less -RFX || \
    ${pkgs.less}/bin/less -RFX ${keybindingGuide}
  '';

in
{
  # Make the keybinding guide available as a command
  home.packages = [
    (pkgs.writeShellScriptBin "axios-help" ''
      # Display in a floating terminal window sized for readability on all screens
      # Note: Window rule matches by title since Ghostty doesn't allow custom app-id
      ${pkgs.ghostty}/bin/ghostty \
        --title="Niri Keybindings - axiOS" \
        --window-width=80 \
        --window-height=40 \
        -e ${showKeybindings}
    '')
  ];

  # Add keybinding to show the guide
  programs.niri.settings.binds = {
    "Mod+Shift+Slash".action.spawn = [ "axios-help" ];

    # --- App launches ---
    "Mod+B".action.spawn = [
      "brave"
      "--class=brave-browser"
    ];
    "Mod+E".action.spawn = [ "dolphin" ];
    "Mod+Return".action.spawn = "ghostty";
    "Mod+G".action.spawn = [
      "brave"
      "--app=https://messages.google.com/web"
    ];
    "Mod+C".action.spawn = [ "code" ];
    "Mod+D".action.spawn = [ "discord" ];
    "Mod+Shift+T".action.spawn = [ "kate" ];
    "Mod+Shift+C".action.spawn = [ "focus-or-spawn-qalculate" ];

    # --- Workspace: jump directly (1..8) ---
    "Mod+1".action."focus-workspace" = [ 1 ];
    "Mod+2".action."focus-workspace" = [ 2 ];
    "Mod+3".action."focus-workspace" = [ 3 ];
    "Mod+4".action."focus-workspace" = [ 4 ];
    "Mod+5".action."focus-workspace" = [ 5 ];
    "Mod+6".action."focus-workspace" = [ 6 ];
    "Mod+7".action."focus-workspace" = [ 7 ];
    "Mod+8".action."focus-workspace" = [ 8 ];

    # --- Navigation ---
    "Mod+H".action.focus-column-left = [ ];
    "Mod+J".action.focus-window-down = [ ];
    "Mod+K".action.focus-window-up = [ ];
    "Mod+L".action.focus-column-right = [ ];

    "Mod+Left".action.focus-column-left = [ ];
    "Mod+Down".action.focus-window-down = [ ];
    "Mod+Up".action.focus-window-up = [ ];
    "Mod+Right".action.focus-column-right = [ ];

    "Mod+Ctrl+Left".action.move-column-left = [ ];
    "Mod+Ctrl+Down".action.move-window-down = [ ];
    "Mod+Ctrl+Up".action.move-window-up = [ ];
    "Mod+Ctrl+Right".action.move-column-right = [ ];
    "Mod+Shift+H".action.move-column-left = [ ];
    "Mod+Shift+J".action.move-window-down = [ ];
    "Mod+Shift+K".action.move-window-up = [ ];
    "Mod+Shift+L".action.move-column-right = [ ];

    # --- Move focused window to workspace N ---
    "Mod+Shift+0".action."move-window-to-workspace" = [ 0 ];
    "Mod+Shift+1".action."move-window-to-workspace" = [ 1 ];
    "Mod+Shift+2".action."move-window-to-workspace" = [ 2 ];
    "Mod+Shift+3".action."move-window-to-workspace" = [ 3 ];
    "Mod+Shift+4".action."move-window-to-workspace" = [ 4 ];
    "Mod+Shift+5".action."move-window-to-workspace" = [ 5 ];
    "Mod+Shift+6".action."move-window-to-workspace" = [ 6 ];
    "Mod+Shift+7".action."move-window-to-workspace" = [ 7 ];
    "Mod+Shift+8".action."move-window-to-workspace" = [ 8 ];
    "Mod+Shift+9".action."move-window-to-workspace" = [ 9 ];

    # --- Move focused column to workspace N ---
    "Mod+Ctrl+Shift+0".action.move-column-to-workspace = "0";
    "Mod+Ctrl+Shift+1".action.move-column-to-workspace = "1";
    "Mod+Ctrl+Shift+2".action.move-column-to-workspace = "2";
    "Mod+Ctrl+Shift+3".action.move-column-to-workspace = "3";
    "Mod+Ctrl+Shift+4".action.move-column-to-workspace = "4";
    "Mod+Ctrl+Shift+5".action.move-column-to-workspace = "5";
    "Mod+Ctrl+Shift+6".action.move-column-to-workspace = "6";
    "Mod+Ctrl+Shift+7".action.move-column-to-workspace = "7";
    "Mod+Ctrl+Shift+8".action.move-column-to-workspace = "8";
    "Mod+Ctrl+Shift+9".action.move-column-to-workspace = "9";

    # --- Column width adjustment ---
    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Equal".action.set-column-width = "+10%";
    "Mod+W".action.switch-preset-column-width = [ ];

    # --- Window consume/expel within columns ---
    "Mod+Shift+Comma".action.consume-window-into-column = { };
    "Mod+Shift+Period".action.expel-window-from-column = { };

    # --- Consume/expel window left/right ---
    "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
    "Mod+BracketRight".action.consume-or-expel-window-right = [ ];

    # --- Overview ---
    "Mod+Tab".action."toggle-overview" = [ ];

    # --- Window management ---
    "Mod+Q".action."close-window" = [ ];
    "Mod+Shift+F".action."fullscreen-window" = [ ];

    # --- Column management ---
    "Mod+backslash".action.maximize-column = [ ];

    # Column/monitor focus (wheel + keyboard alternatives)
    "Mod+WheelScrollRight".action.focus-column-or-monitor-right = { };
    "Mod+WheelScrollLeft".action.focus-column-or-monitor-left = { };
    "Mod+Semicolon".action.focus-column-or-monitor-right = { };
    "Mod+Apostrophe".action.focus-column-or-monitor-left = { };

    # Move column to monitor (wheel + keyboard alternatives)
    "Mod+Ctrl+WheelScrollRight".action.move-column-right-or-to-monitor-right = { };
    "Mod+Ctrl+WheelScrollLeft".action.move-column-left-or-to-monitor-left = { };
    "Mod+Ctrl+Semicolon".action.move-column-right-or-to-monitor-right = { };
    "Mod+Ctrl+Apostrophe".action.move-column-left-or-to-monitor-left = { };

    # --- Tabbed display ---
    "Mod+T".action.toggle-column-tabbed-display = [ ];

    # --- Floating ---
    "Mod+Shift+Z".action."toggle-window-floating" = [ ];
    "Mod+Z".action."switch-focus-between-floating-and-tiling" = [ ];

    # Workspace navigation (wheel + keyboard alternatives)
    "Mod+WheelScrollDown" = {
      cooldown-ms = 150;
      action.focus-workspace-down = { };
    };
    "Mod+WheelScrollUp" = {
      cooldown-ms = 150;
      action.focus-workspace-up = { };
    };
    "Mod+Page_Down".action.focus-workspace-down = { };
    "Mod+Page_Up".action.focus-workspace-up = { };

    # Move column to workspace (wheel + keyboard alternatives)
    "Mod+Ctrl+WheelScrollDown" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-down = { };
    };
    "Mod+Ctrl+WheelScrollUp" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-up = { };
    };
    "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
    "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };

    # --- Volume control (DMS IPC) ---
    # Wheel bindings
    "Mod+Shift+WheelScrollLeft".action.spawn = [
      "dms"
      "ipc"
      "call"
      "audio"
      "increment"
      "3"
    ];
    "Mod+Shift+WheelScrollRight".action.spawn = [
      "dms"
      "ipc"
      "call"
      "audio"
      "decrement"
      "3"
    ];

    # Keyboard alternatives for volume
    "Mod+Shift+Equal".action.spawn = [
      "dms"
      "ipc"
      "call"
      "audio"
      "increment"
      "3"
    ];
    "Mod+Shift+Minus".action.spawn = [
      "dms"
      "ipc"
      "call"
      "audio"
      "decrement"
      "3"
    ];
    "Mod+Shift+M".action.spawn = [
      "dms"
      "ipc"
      "call"
      "audio"
      "mute"
    ];

    # --- Brightness control (DMS IPC) ---
    # Note: Brightness keybinds are provided by DankMaterialShell
    # via enableKeybinds = true (handles both screen and keyboard backlight)

    # --- Quit compositor (clean exit) ---
    "Mod+Shift+E".action."quit" = [ ];

    # --- Screenshots (Niri native) ---
    "Mod+Ctrl+S".action.screenshot-screen = {
      write-to-disk = true;
    };
    "Mod+Alt+S".action.screenshot-screen = { };
    "Mod+Shift+S".action.screenshot = { };

    # --- Screen Recording (wf-recorder) ---
    # Toggle recording (start/stop)
    "Mod+Shift+R".action.spawn = [
      "${pkgs.bash}/bin/bash"
      "-c"
      ''
        if pgrep -x wf-recorder > /dev/null; then
          pkill -INT wf-recorder
          notify-send "Screen Recording" "Recording stopped" -i video-x-generic
        else
          mkdir -p ~/Videos
          wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4 &
          notify-send "Screen Recording" "Recording started" -i media-record
        fi
      ''
    ];

    # Record with area selection
    "Mod+Ctrl+R".action.spawn = [
      "${pkgs.bash}/bin/bash"
      "-c"
      ''
        mkdir -p ~/Videos
        wf-recorder -g "$(slurp)" -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4 &
        notify-send "Screen Recording" "Area recording started" -i media-record
      ''
    ];

    # Quake style drop down terminal using ghostty
    # Toggle by closing window if focused, or spawning/focusing if not
    "Mod+grave".action.spawn = [
      "${pkgs.bash}/bin/bash"
      "-c"
      ''
        # Get dropterm window ID if it exists
        dropterm_id=$(niri msg windows | ${pkgs.gnugrep}/bin/grep -B2 'App ID: "com.kc.dropterm"' | ${pkgs.gnugrep}/bin/grep 'Window ID' | ${pkgs.gawk}/bin/awk '{print $3}' | ${pkgs.gnused}/bin/sed 's/://')

        if [ -n "$dropterm_id" ]; then
          # Check if it's focused
          if niri msg windows | ${pkgs.gnugrep}/bin/grep -A1 "Window ID $dropterm_id:" | ${pkgs.gnugrep}/bin/grep -q "(focused)"; then
            # Close if focused
            niri msg action close-window
          else
            # Focus if not focused
            niri msg action focus-window --id "$dropterm_id"
          fi
        else
          # Spawn new window using resident daemon (instant)
          ${pkgs.ghostty}/bin/ghostty \
            --gtk-single-instance=true \
            --class=com.kc.dropterm \
            --window-decoration=none &
        fi
      ''
    ];
  };

  # Window rule for the keybinding reference window
  # Make it float and center on screen, sized appropriately for small displays
  programs.niri.settings.window-rules = [
    {
      matches = [
        { title = "Niri Keybindings - axiOS"; }
      ];
      default-column-width = { };
      open-floating = true;
    }
  ];

  # Also make the raw text file available
  xdg.configFile."niri/keybindings.txt".source = keybindingGuide;
}
