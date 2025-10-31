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
    
    # Create claude-code config directory and files
    xdg.configFile."claude-code/config.json" = {
      text = builtins.toJSON {
        version = "1.0";
        mcpServers = claudeConfig.mcpServers;
        aiGuidance = ''
          * After receiving tool results, carefully reflect on their quality and determine optimal next steps
          * For maximum efficiency, invoke multiple independent tools simultaneously rather than sequentially
          * Before finishing, verify your solution addresses all requirements
          * Do what has been asked; nothing more, nothing less
          * NEVER create files unless absolutely necessary
          * ALWAYS prefer editing existing files to creating new ones
          * NEVER proactively create documentation unless explicitly requested
          
          ## Git Commit Rules
          
          * NEVER include Claude's identity or involvement in commit messages
          * Do NOT add "Generated with Claude Code" or "Co-Authored-By: Claude" footers
          * Write commit messages as if authored by the human user
          * Keep commit messages concise and focused on the technical changes
        '';
      };
    };
  };
}
