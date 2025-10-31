{ config, lib, pkgs, inputs, osConfig ? {}, ... }:

let
  # MCP server configuration helper
  mkMcpServer = command: args: env: {
    inherit command args;
    env = env // { NODE_ENV = "production"; };
  };
  
  # Claude Code configuration
  claudeConfig = {
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
  };
in
{
  # Create claude-code configuration when AI is enabled
  config = lib.mkIf (osConfig.services.ai.enable or false) {
    # Install npx for MCP servers
    home.packages = with pkgs; [
      nodejs
    ];
    
    # Create MCP config file in ~/.claude directory
    home.file.".claude/.claude.json" = {
      text = builtins.toJSON {
        mcpServers = claudeConfig.mcpServers;
      };
    };
  };
}
