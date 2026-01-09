{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.c64;
in
{
  options.c64 = {
    enable = lib.mkEnableOption "Commodore 64 integration with Ultimate64 hardware";
  };

  config = lib.mkIf cfg.enable {
    # Install C64-related packages
    environment.systemPackages = with pkgs; [
      # C64/Ultimate64 video/audio stream viewer
      inputs.c64-stream-viewer.packages.${pkgs.stdenv.hostPlatform.system}.av
    ];

    # Note: ultimate64-mcp MCP server is installed via services.ai module
    # and is always available when AI tools are enabled. It provides:
    # - Remote control of Ultimate64 hardware
    # - File management (.prg, .d64, etc.)
    # - Video/audio streaming
    # - Execute programs on real C64 hardware
  };
}
