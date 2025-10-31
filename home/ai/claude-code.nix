{ config, lib, pkgs, inputs, osConfig ? {}, ... }:

let
  # MCPHost configuration file
  mcpHostConfig = {
    mcpServers = {
      # Journal log access via custom mcp-journal server
      journal = {
        type = "local";
        command = [ "${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal" ];
      };
      
      # NixOS package and option search
      mcp-nixos = {
        type = "local";
        command = [ "nix" "run" "github:utensils/mcp-nixos" "--" ];
        environment = {
          MCP_NIXOS_CLEANUP_ORPHANS = "true";
        };
      };
      
      # Sequential thinking for enhanced reasoning
      sequential-thinking = {
        type = "local";
        command = [ "npx" "-y" "@modelcontextprotocol/server-sequential-thinking" ];
      };
      
      # Context7 for context management
      context7 = {
        type = "local";
        command = [ "npx" "-y" "@upstash/context7-mcp" ];
      };
      
      # Filesystem access (restricted to /tmp and ~/Projects)
      filesystem = {
        type = "local";
        command = [ "npx" "-y" "@modelcontextprotocol/server-filesystem" "/tmp" "${config.home.homeDirectory}/Projects" ];
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
      mcphost # Universal MCP client
    ];
    
    # MCPHost configuration file
    home.file.".mcphost.yml".text = lib.generators.toYAML {} mcpHostConfig;
    
    # Export Material Code theme updater script
    home.file."scripts/update-material-code-theme" = {
      source = ../../scripts/update-material-code-theme.sh;
      executable = true;
    };
  };
}
