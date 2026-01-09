{ config, lib, pkgs, inputs, ... }:

{
  # C64 module is active when imported via modules.c64 = true
  # No separate enable flag needed - follows axios module pattern

  # Install C64-related packages
  environment.systemPackages = [
    # C64/Ultimate64 video/audio stream viewer
    inputs.c64-stream-viewer.packages.${pkgs.stdenv.hostPlatform.system}.av
    # C64 terminal with authentic PETSCII colors and boot screen
    inputs.c64term.packages.${pkgs.stdenv.hostPlatform.system}.c64term
  ];

  # Note: ultimate64-mcp MCP server is installed via services.ai module
  # and is always available when AI tools are enabled. It provides:
  # - Remote control of Ultimate64 hardware
  # - File management (.prg, .d64, etc.)
  # - Video/audio streaming
  # - Execute programs on real C64 hardware
}
