{ config, lib, pkgs, inputs, osConfig ? {}, ... }:

let
  # MCP server configuration helper
  mkMcpServer = command: args: env: {
    inherit command args;
    env = env // { NODE_ENV = "production"; };
  };
  
  # Shared MCP servers configuration (used by both Claude and Copilot)
  mcpServers = {
    # Journal log access
    journal = mkMcpServer 
      "${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal"
      []
      {};
    
    # NixOS package search
    "mcp-nixos" = mkMcpServer
      "nix"
      ["run" "github:utensils/mcp-nixos" "--"]
      { MCP_NIXOS_CLEANUP_ORPHANS = "true"; };
    
    # Sequential thinking for reasoning
    "sequential-thinking" = mkMcpServer
      "npx"
      ["-y" "@modelcontextprotocol/server-sequential-thinking"]
      {};
    
    # Context7 for context management  
    context7 = mkMcpServer
      "npx"
      ["-y" "@upstash/context7-mcp"]
      {};
    
    # Filesystem access
    filesystem = mkMcpServer
      "npx"
      ["-y" "@modelcontextprotocol/server-filesystem" "/tmp" "${config.home.homeDirectory}/Projects"]
      {};
  };
in
{
  # Create AI tool configurations when AI is enabled
  config = lib.mkIf (osConfig.services.ai.enable or false) {
    # Install npx for MCP servers
    home.packages = with pkgs; [
      nodejs
    ];
    
    # Claude Code MCP config in ~/.claude directory
    home.file.".claude/.claude.json" = {
      text = builtins.toJSON {
        mcpServers = mcpServers;
      };
    };
    
    # GitHub Copilot CLI MCP config
    home.file.".copilot/mcp-config.json" = {
      text = builtins.toJSON {
        mcpServers = mcpServers;
      };
    };
  };
}
