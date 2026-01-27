{ ... }:

{
  # AI home-manager configuration
  # This module is conditionally imported when services.ai.enable = true
  imports = [
    ./mcp.nix
    ./mcp-gateway.nix
  ];

  # Additional AI configuration can go here
  # Note: axios-ai-chat replaces Open WebUI for AI chat interface
  # Users connect via XMPP clients (Conversations, Gajim, Dino)
}
