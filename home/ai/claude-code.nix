{ config, lib, pkgs, inputs, ... }:

let
  mkMcpServer = {
    command,
    args ? [],
    env ? {},
    timeout ? 300
  }: {
    inherit command args timeout;
    env = env // {
      NODE_ENV = "production";
    };
  };
in
{
  # Claude Code configuration with MCP servers
  programs.claude-code = {
    enable = true;
    debug = false;
    
    defaultModel = "sonnet";
    
    # Default account (pro tier)
    defaultAccount = "pro";
    
    # Account profiles
    accounts = {
      pro = {
        enable = true;
        displayName = "Claude Pro";
        model = "sonnet";
      };
    };
    
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
    
    permissions = {
      allow = [
        "Bash"
        "mcp__journal"
        "mcp__nixos"
        "mcp__sequential-thinking"
        "mcp__filesystem"
        "mcp__context7"
        "Read"
        "Write"
        "Edit"
        "WebFetch"
      ];
      deny = [
        "Search"
        "Find"
        "Bash(rm -rf /*)"
      ];
    };
    
    # MCP Server configurations
    mcpServers = {
      # NixOS package/option search
      nixos.enable = true;
      
      # Sequential thinking for complex reasoning
      sequentialThinking.enable = true;
      
      # Context7 for advanced context management
      context7.enable = true;
      
      # Filesystem access (restrict to safe paths)
      mcpFilesystem = {
        enable = true;
        allowedPaths = [
          "/tmp"
          "${config.home.homeDirectory}/Projects"
        ];
      };
      
      # Custom MCP servers
      custom = {
        # Journal log access via mcp-journal
        journal = mkMcpServer {
          command = "${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal";
          args = [];
        };
      };
    };
  };
}
