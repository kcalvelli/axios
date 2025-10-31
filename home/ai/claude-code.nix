{ config, lib, pkgs, inputs, osConfig ? {}, ... }:

let
  # Claude CLI MCP configuration
  # Format: { "mcpServers": { "name": { "type": "stdio", "command": "cmd", "args": [], "env": {} } } }
  claudeMcpConfig = {
    mcpServers = {
      # Journal log access via custom mcp-journal server
      journal = {
        type = "stdio";
        command = "${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal";
        args = [];
        env = {};
      };

      # NixOS package and option search
      mcp-nixos = {
        type = "stdio";
        command = "nix";
        args = [ "run" "github:utensils/mcp-nixos" "--" ];
        env = {
          MCP_NIXOS_CLEANUP_ORPHANS = "true";
        };
      };

      # Sequential thinking for enhanced reasoning
      sequential-thinking = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
        env = {};
      };

      # Context7 for context management
      context7 = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@upstash/context7-mcp" ];
        env = {};
      };

      # Filesystem access (restricted to /tmp and ~/Projects)
      filesystem = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-filesystem" "/tmp" "${config.home.homeDirectory}/Projects" ];
        env = {};
      };
    };
  };
in
{
  # Create AI tool configurations when AI is enabled
  config = lib.mkIf (osConfig.services.ai.enable or false) {
    # Install required packages
    home.packages = with pkgs; [
      nodejs  # For npx MCP servers
    ];

    # Claude CLI .mcp.json template (for copying to new projects)
    home.file.".mcp.json.template".text = lib.generators.toJSON {} claudeMcpConfig;

    # Export Material Code theme updater script
    home.file."scripts/update-material-code-theme" = {
      source = ../../scripts/update-material-code-theme.sh;
      executable = true;
    };

    # Export Claude MCP initialization script
    home.file."scripts/init-claude-mcp" = {
      source = ../../scripts/init-claude-mcp.sh;
      executable = true;
    };
  };
}
