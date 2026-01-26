# MCP Configuration for axios
# This module imports mcp-gateway's home-manager module and configures
# the MCP servers using axios's flake inputs.
#
# mcp-gateway owns the declarative config module and generates all config files.
# axios just provides the server definitions with resolved paths from inputs.
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? { },
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Import mcp-gateway's home-manager module
  imports = [
    inputs.mcp-gateway.homeManagerModules.default
  ];

  config = lib.mkIf (osConfig.services.ai.mcp.enable or false) {
    # Configure mcp-gateway with axios's server definitions
    services.mcp-gateway = {
      enable = true;

      # Let NixOS manage the systemd service when mcpGateway is enabled
      # (NixOS module handles OAuth secrets via agenix)
      manageService = !(osConfig.services.ai.mcpGateway.enable or false);

      # Pass through gateway settings from NixOS config
      port = osConfig.services.ai.mcpGateway.port or 8085;
      autoEnable =
        osConfig.services.ai.mcpGateway.autoEnable or [
          "git"
          "github"
          "filesystem"
          "context7"
          "mcp-dav"
          "axios-ai-mail"
        ];

      # System prompt configuration
      systemPrompt = {
        enable = osConfig.services.ai.systemPrompt.enable or true;
        extraInstructions = osConfig.services.ai.systemPrompt.extraInstructions or "";
      };

      # MCP Server Definitions
      # All servers with fully resolved paths from axios inputs
      servers = {
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # CORE TOOLS (No setup required)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        git = {
          enable = true;
          command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        };

        time = {
          enable = true;
          command = "${pkgs.mcp-server-time}/bin/mcp-server-time";
        };

        github = {
          enable = true;
          command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
          args = [ "stdio" ];
          passwordCommand = {
            GITHUB_PERSONAL_ACCESS_TOKEN = [
              (lib.getExe config.programs.gh.package)
              "auth"
              "token"
            ];
          };
        };

        journal = {
          enable = true;
          command = "${inputs.mcp-journal.packages.${system}.default}/bin/mcp-journal";
        };

        nix-devshell-mcp = {
          enable = true;
          command = "${inputs.nix-devshell-mcp.packages.${system}.default}/bin/nix-devshell-mcp";
        };

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # PIM TOOLS (Require services.pim.enable)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        axios-ai-mail = {
          enable = true;
          command = "${inputs.axios-ai-mail.packages.${system}.default}/bin/axios-ai-mail";
          args = [ "mcp" ];
        };

        mcp-dav = {
          enable = true;
          command = "${inputs.axios-dav.packages.${system}.mcp-dav}/bin/mcp-dav";
          env = {
            MCP_DAV_CALENDARS = "~/.calendars";
            MCP_DAV_CONTACTS = "~/.contacts";
          };
        };

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # AI ENHANCEMENT SERVERS (No setup required)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        sequential-thinking = {
          enable = true;
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking"
          ];
        };

        context7 = {
          enable = true;
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@upstash/context7-mcp"
          ];
        };

        filesystem = {
          enable = true;
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/tmp"
            "${config.home.homeDirectory}/Projects"
          ];
        };

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # SEARCH SERVERS (Require API keys)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        brave-search = {
          enable = true;
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-brave-search"
          ];
          env = {
            BRAVE_API_KEY = "\${BRAVE_API_KEY}";
          };
          passwordCommand = {
            BRAVE_API_KEY = [
              "${pkgs.bash}/bin/bash"
              "-c"
              "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/brave-api-key 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\\n' || echo \${BRAVE_API_KEY}"
            ];
          };
        };
      };
    };

    # Install MCP server packages
    home.packages = [
      inputs.axios-ai-mail.packages.${system}.default
      inputs.axios-dav.packages.${system}.mcp-dav
      inputs.mcp-journal.packages.${system}.default
      inputs.nix-devshell-mcp.packages.${system}.default
    ];
  };
}
