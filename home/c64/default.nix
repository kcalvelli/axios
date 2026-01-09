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

    # Create desktop launcher
    xdg.desktopEntries.c64-shell = {
      name = "C64 Shell";
      genericName = "Commodore 64 Terminal";
      comment = "Authentic Commodore 64 terminal experience with development tools";
      exec = "${pkgs.c64-shell}/bin/c64-shell";
      icon = "c64term";
      terminal = false;
      categories = [
        "System"
        "TerminalEmulator"
        "Development"
      ];
    };

    # Ensure required programs are available
    programs.fish.enable = lib.mkDefault true;
    programs.starship.enable = lib.mkDefault true;
    programs.ghostty.enable = lib.mkDefault true;
  };
}
