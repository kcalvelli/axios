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

    # Export Claude MCP initialization script (project-scoped)
    home.file."scripts/init-claude-mcp" = {
      source = ../../scripts/init-claude-mcp.sh;
      executable = true;
    };

    # Export user-scoped MCP setup script
    # Note: Run this manually after nixos-rebuild if activation doesn't trigger
    home.file."scripts/setup-claude-mcp-user" = {
      source = ../../scripts/setup-claude-mcp-user.sh;
      executable = true;
    };

    # Automatically configure user-scoped MCP servers for Claude CLI
    # This makes MCP servers available in all Claude CLI sessions, not just projects
    home.activation.claudeMcpSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.writeShellScript "setup-claude-mcp" ''
        # Only run if claude CLI is available
        if ! command -v claude &> /dev/null; then
          echo "Claude CLI not found, skipping MCP setup"
          exit 0
        fi

        echo "Setting up user-scoped MCP servers for Claude CLI..."

        # Function to add MCP server if it doesn't exist
        add_mcp_server() {
          local name="$1"
          shift

          # Check if server already exists at user scope
          if claude mcp get "$name" -s user &> /dev/null; then
            echo "  ✓ $name already configured"
          else
            echo "  + Adding $name..."
            claude mcp add --transport stdio "$name" --scope user -- "$@" || true
          fi
        }

        # Add all MCP servers at user scope
        add_mcp_server journal \
          "${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal"

        # Note: mcp-nixos environment variable needs to be set differently
        # We'll add it without the env var and document it for now
        add_mcp_server mcp-nixos \
          nix run github:utensils/mcp-nixos --

        add_mcp_server sequential-thinking \
          npx -y @modelcontextprotocol/server-sequential-thinking

        add_mcp_server context7 \
          npx -y @upstash/context7-mcp

        add_mcp_server filesystem \
          npx -y @modelcontextprotocol/server-filesystem /tmp ${config.home.homeDirectory}/Projects

        echo "✓ Claude CLI MCP setup complete!"
        echo "  Run 'claude mcp list' to verify (check 'claude mcp get <name>' for scope)"
      ''}
    '';
  };
}
