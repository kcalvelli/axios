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
    │ Mod + E           Launch File Manager (Nautilus)                 │
    │ Mod + C           Launch VS Code                                 │
    │ Mod + D           Launch Discord                                 │
    │ Mod + G           Launch Google Messages (PWA)                   │
    │ Mod + `           Toggle Drop-down Terminal (Quake-style)        │
    │ Mod + Shift + T   Launch Text Editor                             │
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
  programs.niri.settings.binds."Mod+Shift+Slash" = {
    action.spawn = [ "axios-help" ];
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
