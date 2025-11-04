{ ... }:

{
  # AI home-manager configuration
  # Always import but claude-code.nix will check osConfig.services.ai.enable internally
  imports = [
    #./claude-code.nix
    ./mcp.nix
  ];
}
