{ config, lib, pkgs, osConfig ? {}, ... }:

{
  # AI home-manager configuration
  # Always import but modules will check osConfig.services.ai.enable internally
  imports = [
    #./claude-code.nix
    ./mcp.nix
  ];

  config = lib.mkIf (osConfig.services.ai.enable or false) {
    # Install LM Studio (desktop app with native MCP support)
    home.packages = with pkgs; [
      lmstudio
    ];
  };
}
