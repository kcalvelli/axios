{ config, lib, pkgs, inputs, osConfig ? {}, ... }:

let
  # Script to set up Claude MCP servers
  setupClaudeMcpScript = pkgs.writeShellScript "setup-claude-mcp" ''
    #!/usr/bin/env bash
    set -e
    
    echo "Setting up Claude Code MCP servers..."
    echo ""
    
    # Add MCP servers to Claude Code
    echo "Adding journal MCP server..."
    claude mcp add --transport stdio journal -- ${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal
    
    echo "Adding mcp-nixos..."
    claude mcp add --transport stdio mcp-nixos -- nix run github:utensils/mcp-nixos --
    
    echo "Adding sequential-thinking..."
    claude mcp add --transport stdio sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
    
    echo "Adding context7..."
    claude mcp add --transport stdio context7 -- npx -y @upstash/context7-mcp
    
    echo "Adding filesystem..."
    claude mcp add --transport stdio filesystem -- npx -y @modelcontextprotocol/server-filesystem /tmp ${config.home.homeDirectory}/Projects
    
    echo ""
    echo "✓ MCP servers configured!"
    echo ""
    echo "Verifying connection..."
    claude mcp list
  '';
in
{
  # Create AI tool configurations when AI is enabled
  config = lib.mkIf (osConfig.services.ai.enable or false) {
    # Install npx for MCP servers
    home.packages = with pkgs; [
      nodejs
    ];
    
    # Export setup script to ~/scripts/
    home.file."scripts/setup-claude-mcp" = {
      source = setupClaudeMcpScript;
      executable = true;
    };
  };
}
