{ config, lib, pkgs, inputs, osConfig, ... }:

let
  inherit (lib) mkIf;
  # Single source of truth for your servers (same as your snippet)
  claudeMcpConfig = {
    mcpServers = {
      journal = {
        type = "stdio";
        command = "${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal";
        args = [ ];
        env = { };
      };

      mcp-nixos = {
        type = "stdio";
        command = "nix";
        args = [ "run" "github:utensils/mcp-nixos" "--" ];
        env = { MCP_NIXOS_CLEANUP_ORPHANS = "true"; };
      };

      sequential-thinking = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
        env = { };
      };

      context7 = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@upstash/context7-mcp" ];
        env = { };
      };

      filesystem = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-filesystem" "/tmp" "${config.home.homeDirectory}/Projects" ];
        env = { };
      };
    };
  };

  # mcpo config JSON (for Open WebUI)
  mcpoJson = lib.generators.toJSON { } claudeMcpConfig;

in
{
  config = mkIf (osConfig.services.ai.enable or false) {

    home.packages = with pkgs; [ nodejs uv ];

    # === Claude CLI artifacts ===
    home.file.".mcp.json.template".text = lib.generators.toJSON { } claudeMcpConfig;

    home.file."scripts/init-claude-mcp" = {
      source = ../../scripts/init-claude-mcp.sh;
      executable = true;
    };

    home.file."scripts/setup-claude-mcp-user" = {
      source = ../../scripts/setup-claude-mcp-user.sh;
      executable = true;
    };

    home.activation.claudeMcpSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! command -v claude &> /dev/null; then
        echo "Claude CLI not found, skipping MCP setup"
        exit 0
      fi

      echo "Setting up user-scoped MCP servers for Claude CLI..."

      add_mcp_server() {
        local name="$1"; shift
        if claude mcp get "$name" -s user &> /dev/null; then
          echo "  ✓ $name already configured"
        else
          echo "  + Adding $name..."
          claude mcp add --transport stdio "$name" --scope user -- "$@" || true
        fi
      }

      add_mcp_server journal \
        "${inputs.mcp-journal.packages.${pkgs.system}.default}/bin/mcp-journal"

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
    '';

    # === mcpo service for Open WebUI ===
    xdg.configFile."mcpo/config.json".text = mcpoJson;

    systemd.user.services.mcpo = {
      Unit = {
        Description = "MCP to OpenAPI proxy (mcpo)";
        After = [ "network-online.target" ];
      };
      Service = {
        ExecStart = ''
          ${pkgs.uv}/bin/uvx mcpo \
            --config ${config.xdg.configHome}/mcpo/config.json \
            --host 127.0.0.1 \
            --port 8000 \
            --hot-reload
        '';
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    # --- Helper: Open WebUI tool registration ---
    # After switching, add these in Open WebUI → ⚙️ Admin Settings → External Tools → + Add:
    #   http://127.0.0.1:8000/journal
    #   http://127.0.0.1:8000/mcp-nixos
    #   http://127.0.0.1:8000/sequential-thinking
    #   http://127.0.0.1:8000/context7
    #   http://127.0.0.1:8000/filesystem
    #
    # Each route provides OpenAPI docs at /<tool>/docs for testing.
  };
}
