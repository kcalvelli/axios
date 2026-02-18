{
  ...
}:
{
  # Minimal keybindings for normie profile
  # DMS injects its own bindings (media keys, Mod+Space launcher, Mod+N notifications,
  # Mod+X power menu, Mod+V clipboard, Super+Alt+L lock) via enableKeybinds = true.
  # All other interaction is via mouse through the DMS panel and Alt+Tab.
  programs.niri.settings.binds = {
    # Close focused window
    "Mod+Q".action."close-window" = [ ];

    # Toggle maximize column
    "Mod+F".action.maximize-column = [ ];

    # Screenshot (interactive area selection)
    "Print".action.screenshot = { };
  };
}
