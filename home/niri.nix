{ inputs, pkgs, lib, config, ... }:
{
  imports = [
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  programs = {
    dankMaterialShell = {
      niri = {
        enableKeybinds = true;
        enableSpawn = true;
      };
    };
    niri.settings = {
      prefer-no-csd = true;
      xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite}";
      screenshot-path = "~/Pictures/Screenshots/Screenshot-from-%Y-%m-%d-%H-%M-%S.png";
      hotkey-overlay.skip-at-startup = true;

      spawn-at-startup = [
        { command = [ "wl-paste" "--watch" "cliphist" "store" ]; }
        { command = [ "wl-paste" "--type text" "--watch" "cliphist" "store" ]; }
        { command = [ "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1" ]; }
        # User-specific background is set in modules/users/[username].nix
        #{command = ["qs" "-c" "DankMaterialShell"];}
        {
          command = [
            "$ghostty"
            "--gtk-single-instance=true" # reuse one resident process
            "--initial-window=false" # start with no window
            "--quit-after-last-window-closed=false" # keep the process alive
          ];
        }
      ];

      layout = {
        # Kill borders around all windows
        border = {
          enable = false;
        };
        focus-ring = {
          enable = true;
        };
        background-color = "transparent";
        preset-column-widths = [
          # proportions are fractions of the output width (gaps considered)
          { proportion = 1.0; }
          { proportion = 0.75; }
          { proportion = 0.5; }
          { proportion = 0.25; }
        ];
        tab-indicator = {
          hide-when-single-tab = true;
          place-within-column = true;
          position = "left";
          corner-radius = 20.0;
          gap = -12.0;
          gaps-between-tabs = 10.0;
          width = 4.0;
          length.total-proportion = 0.1;
        };
      };

      overview = {
        #zoom = 0.25;
      };

      input = {

        touchpad = {
          natural-scroll = false;
          tap = true;
          tap-button-map = "left-right-middle";
          middle-emulation = true;
          accel-profile = "adaptive";
        };

        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "90%";
        };
        warp-mouse-to-focus.enable = true;
        workspace-auto-back-and-forth = true;
      };

      switch-events.lid-close.action.spawn = [
        "systemctl"
        "suspend"
      ];

      layer-rules = [
        {
          matches = [{ namespace = "^wallpaper$"; }];
          place-within-backdrop = true;
        }
      ];

      window-rules = [
        {
          geometry-corner-radius =
            let
              radius = 12.0;
            in
            {
              bottom-left = radius;
              bottom-right = radius;
              top-left = radius;
              top-right = radius;
            };
          clip-to-geometry = true;
          draw-border-with-background = false;
        }
        {
          matches = [
            { is-floating = true; }
          ];
          shadow.enable = true;
        }
        {
          matches = [
            { app-id = ".*"; } # regex: all apps
          ];
          open-maximized = true;
        }

        # 2) Specific: Google Messages PWA — float, centered, iMessage-ish size
        {
          matches = [
            { app-id = "^google-messages$"; }
          ];

          # Explicitly override the global rule:
          open-maximized = false;
          open-floating = true;

          # Size on open (pixels)
          default-column-width = { fixed = 500; };
          default-window-height = { fixed = 700; };

          # Optional: pin position instead of center (comment out if not needed)
          default-floating-position = { x = 5; y = 5; relative-to = "top-left"; };
        }
        {
          matches = [
            { app-id = "^org\\.gnome\\.Nautilus$"; }
          ];

          # Override the global maximized rule
          open-maximized = false;
          open-floating = true; # centers by default

          # A comfortable size for quick file tasks
          default-column-width = { fixed = 1200; };
          default-window-height = { fixed = 900; };

          # Optional: pin a corner instead of center
          # default-floating-position = { x = 0; y = 0; relative-to = "top-right"; };
        }
        # Drop-down Ghostty: float, matches panel width, short height, stick to the top center
        {
          matches = [{ app-id = "^com\\.kc\\.dropterm$"; }];

          open-floating = true;

          # Size/position: panel width (full width minus side margins), 420px tall, tucked under bar
          default-column-width = { proportion = 0.97; };
          default-window-height = { fixed = 420; };
          default-floating-position = { x = 0; y = 4; relative-to = "top"; };

          # --- Remove border/outline/shadow (per-window) ---
          border = { enable = false; };
          focus-ring = { enable = false; };
          shadow = { enable = false; };
        }

        # Normal Ghostty windows: leave as you like (example: keep maximized-by-default off)
        {
          matches = [{ app-id = "^com\\.mitchellh\\.ghostty$"; }];
          # no open-floating here, so they tile/maximize per your global rules
        }
      ];


      # Keybindings      
      binds = {
        # --- App launches ---
        "Mod+B".action.spawn = [ "brave" ];
        "Mod+E".action.spawn = [ "nautilus" ];
        "Mod+Return".action.spawn = "ghostty";
        "Mod+G".action.spawn = [ "gtk-launch" "google-messages" ];        

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
        "Mod+WheelScrollRight".action.focus-column-or-monitor-right = { };
        "Mod+WheelScrollLeft".action.focus-column-or-monitor-left = { };
        "Mod+Ctrl+WheelScrollRight".action.move-column-right-or-to-monitor-right = { };
        "Mod+Ctrl+WheelScrollLeft".action.move-column-left-or-to-monitor-left = { };

        # --- Tabbed display ---
        "Mod+T".action.toggle-column-tabbed-display = [ ];

        # --- Floating ---
        "Mod+Shift+Z".action."toggle-window-floating" = [ ];
        "Mod+Z".action."switch-focus-between-floating-and-tiling" = [ ];

        # Wheel scroll:
        "Mod+WheelScrollDown" = {
          cooldown-ms = 150;
          action.focus-workspace-down = { };
        };
        "Mod+WheelScrollUp" = {
          cooldown-ms = 150;
          action.focus-workspace-up = { };
        };
        "Mod+Ctrl+WheelScrollDown" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-down = { };
        };
        "Mod+Ctrl+WheelScrollUp" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-up = { };
        };



        # --- Volume control with thumb wheel ---
        "Mod+Shift+WheelScrollLeft".action.spawn = [
          "dms"
          "ipc"
          "audio"
          "increment"
          "3"
        ];
        "Mod+Shift+WheelScrollRight".action.spawn = [
          "dms"
          "ipc"
          "audio"
          "decrement"
          "3"
        ];
        "Mod+Shift+M".action.spawn = [
          "dms"
          "ipc"
          "audio"
          "mute"
        ];

        # --- Keyboard backlight control (System76) ---
        "XF86KbdBrightnessUp".action.spawn = [
          "brightnessctl"
          "--device=system76_acpi::kbd_backlight"
          "set"
          "5%+"
        ];
        "XF86KbdBrightnessDown".action.spawn = [
          "brightnessctl"
          "--device=system76_acpi::kbd_backlight"
          "set"
          "5%-"
        ];

        # --- Quit compositor (clean exit) ---
        "Mod+Shift+E".action."quit" = [ ];

        # Screenshot
        "Mod+Ctrl+S".action.screenshot-screen = { write-to-disk = true; };
        "Mod+Alt+S".action.screenshot-screen = { };
        "Mod+Shift+S".action.screenshot = { };

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
    };
  };
}
