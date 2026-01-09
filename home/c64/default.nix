{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.c64;
in
{
  options.programs.c64 = {
    enable = lib.mkEnableOption "Commodore 64 shell experience with authentic colors and C64 development tools";
  };

  config = lib.mkIf cfg.enable {
    # Install C64 shell package and related tools
    home.packages = [
      pkgs.c64-shell
      # C64/Ultimate64 video/audio stream viewer
      inputs.c64-stream-viewer.packages.${pkgs.stdenv.hostPlatform.system}.av
      # Ultimate64 MCP server
      inputs.ultimate64-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # Install C64 icon from package to user directory for theme system
    # Icon name matches app-id for proper association
    home.file.".local/share/icons/hicolor/512x512/apps/com.kc.c64shell.png".source =
      "${pkgs.c64-shell}/share/icons/hicolor/512x512/apps/c64term.png";

    # Create desktop launcher
    xdg.desktopEntries.c64-shell = {
      name = "C64 Shell";
      genericName = "Commodore 64 Terminal";
      comment = "Authentic Commodore 64 terminal experience with development tools";
      exec = "${pkgs.c64-shell}/bin/c64-shell";
      icon = "com.kc.c64shell";
      terminal = false;
      categories = [
        "System"
        "TerminalEmulator"
        "Development"
      ];
      # Match custom C64 shell app-id
      settings = {
        StartupWMClass = "com.kc.c64shell";
      };
    };

    # Ensure required programs are available
    programs.fish.enable = lib.mkDefault true;
    programs.starship.enable = lib.mkDefault true;
    programs.ghostty.enable = lib.mkDefault true;
  };
}
