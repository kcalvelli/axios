{ config, lib, pkgs, inputs, osConfig ? {}, ... }:

let
  # MCP server configurations for manual addition
  # Use: claude mcp add <name> <command> [args...]
  # Use: copilot --additional-mcp-config <config>
  
  # Script to configure Claude MCP servers
  setupClaudeMcp = pkgs.writeShellScript "setup-claude-mcp" ''
    # Add MCP servers to Claude Code
    claude mcp add --transport stdio journal -- ${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal || true
    claude mcp add --transport stdio mcp-nixos -- ${pkgs.nix}/bin/nix run github:utensils/mcp-nixos -- || true
    claude mcp add --transport stdio sequential-thinking -- ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-sequential-thinking || true
    claude mcp add --transport stdio context7 -- ${pkgs.nodejs}/bin/npx -y @upstash/context7-mcp || true
    claude mcp add --transport stdio filesystem -- ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-filesystem /tmp ${config.home.homeDirectory}/Projects || true
  '';
in
{
  # Create AI tool configurations when AI is enabled
  config = lib.mkIf (osConfig.services.ai.enable or false) {
    # Install npx for MCP servers
    home.packages = with pkgs; [
      nodejs
    ];
    
    # Run MCP setup on activation
    home.activation.setupClaudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${setupClaudeMcp}
    '';
  };
}
