{ ... }:

{
  # AI home-manager configuration
  # This module is conditionally imported when services.ai.enable = true
  imports = [
    ./mcp.nix
    ./gemini.nix
  ];

  # Additional AI configuration can go here

}
