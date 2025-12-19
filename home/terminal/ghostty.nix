{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty;
    enableFishIntegration = true;
    installVimSyntax = true;
  };

  # Generate ghostty config directly via xdg.configFile
  # Note: dankcolors are loaded separately via config-file directive
  # Note: Drop-down terminal is handled by Niri keybind (Mod+grave) in niri.nix,
  #       not by Ghostty's global keybind (Wayland doesn't support app-level global keybinds)
  xdg.configFile."ghostty/config".text = ''
    # Ghostty Configuration

    # Import dankcolors theme (if it exists)
    config-file = ~/.config/ghostty/config-dankcolors
  '';
  # Create desktop entry for drop-down terminal to use Ghostty's icon
  xdg.dataFile."applications/com.kc.dropterm.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Ghostty Drop-down Terminal
    Comment=Drop-down terminal using Ghostty
    Icon=com.mitchellh.ghostty
    Exec=${pkgs.ghostty}/bin/ghostty --class=com.kc.dropterm
    Terminal=false
    Categories=System;TerminalEmulator;
    StartupWMClass=com.kc.dropterm
    NoDisplay=true
  '';
}
