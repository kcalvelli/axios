# MCP Configuration for axios
# This module imports mcp-gateway's home-manager module and configures
# the MCP servers using axios's flake inputs.
#
# mcp-gateway owns the declarative config module and generates all config files.
# axios provides server definitions, prompts, commands, and aliases.
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

  # System prompt configuration from NixOS
  systemPromptEnabled = osConfig.services.ai.systemPrompt.enable or true;
  extraInstructions = osConfig.services.ai.systemPrompt.extraInstructions or "";

  # PIM configuration for calendar paths
  pimCfg = osConfig.services.pim or { };
  calendarAccounts = pimCfg.calendar.accounts or { };

  # Extract unique parent directories from calendar account localPaths
  # Default to ~/.calendars, plus any custom paths like ~/.calendars-external/...
  calendarPaths =
    let
      defaultPath = "~/.calendars";
      # Collect non-null external paths
      externalPaths = lib.unique (lib.filter (p: p != null) (
        lib.mapAttrsToList (name: account:
          let
            path = account.localPath or null;
            cleanPath = if path != null then lib.removeSuffix "/" path else null;
          in
          # Check for external calendar directories
          if cleanPath != null && lib.hasPrefix "~/.calendars-external" cleanPath
          then "~/.calendars-external"
          else null
        ) calendarAccounts
      ));
    in
    lib.concatStringsSep ":" ([ defaultPath ] ++ externalPaths);

  # Generate unified prompt
  unifiedPrompt =
    let
      defaultPrompt = builtins.readFile ./prompts/axios-system-prompt.md;
      hasExtra = extraInstructions != "";
    in
    defaultPrompt + (if hasExtra then "\n\n${extraInstructions}\n" else "");
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

      # Let NixOS manage the systemd service when mcp-gateway NixOS module is enabled
      # (NixOS module handles OAuth secrets via agenix)
      manageService = !(osConfig.services.mcp-gateway.enable or false);

      # Pass through gateway settings from NixOS config (if using NixOS module)
      # Otherwise use defaults
      port = osConfig.services.mcp-gateway.port or 8085;
      autoEnable =
        osConfig.services.mcp-gateway.autoEnable or [
          "git"
          "github"
          "filesystem"
          "context7"
          "mcp-dav"
          "axios-ai-mail"
        ];

      # Gemini configuration
      gemini = {
        model = "gemini-2.0-flash-thinking-exp-01-21";
        contextSize = 32768;
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
            # Dynamic calendar paths from services.pim.calendar.accounts
            # Supports multiple paths separated by colons (e.g., ~/.calendars:~/.calendars-external)
            MCP_DAV_CALENDARS = calendarPaths;
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
              # Check NixOS agenix path first, then home-manager agenix, then env var
              "${pkgs.coreutils}/bin/cat /run/agenix/brave-api-key 2>/dev/null || ${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/brave-api-key 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\\n' || echo \${BRAVE_API_KEY}"
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

    # System prompts and OpenSpec commands (axios-specific content)
    home.file = {
      # System prompts
      ".config/ai/prompts/axios.md" = lib.mkIf systemPromptEnabled {
        text = unifiedPrompt;
      };

      ".config/ai/prompts/mcp-cli.md" = lib.mkIf systemPromptEnabled {
        source = ./prompts/mcp-cli-system-prompt.md;
      };

      # OpenSpec commands for Claude Code
      ".claude/commands/openspec/proposal.md".source = ./commands/openspec/proposal.md;
      ".claude/commands/openspec/apply.md".source = ./commands/openspec/apply.md;
      ".claude/commands/openspec/archive.md".source = ./commands/openspec/archive.md;
    };

    # Note: Shell aliases (axc, axios-claude, axg, axios-gemini) are defined
    # in home/terminal/fish.nix as fish abbreviations (abbr)

    # Environment variable for Gemini CLI system prompt
    home.sessionVariables = lib.mkIf systemPromptEnabled {
      GEMINI_SYSTEM_MD = "${config.home.homeDirectory}/.config/ai/prompts/axios.md";
    };
  };
}
