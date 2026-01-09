{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? { },
  ...
}:

let
  # MCP server definitions using mcp-servers-nix library
  # Define servers once, generate configs for multiple AI tools
  #
  # MCP (Model Context Protocol) enables AI assistants to access external tools and data.
  # Documentation: https://docs.claude.com/en/docs/claude-code/mcp
  #
  # REQUIREMENTS BY SERVER:
  #
  # ✓ NO SETUP REQUIRED:
  #   - git: Uses system git (always available)
  #   - time: Provides date/time utilities
  #   - journal: Reads systemd journal logs
  #   - nix-devshell-mcp: Nix development environment management
  #   - sequential-thinking: Enhanced reasoning for complex problems
  #   - context7: Up-to-date documentation search
  #   - filesystem: File access (restricted to /tmp and ~/Projects)
  #
  # ⚙️  REQUIRES LOCAL CONFIGURATION:
  #   - github: Requires 'gh auth login' to authenticate GitHub CLI
  #     Run: gh auth login
  #     Verify: gh auth status
  #
  # 🔑 REQUIRES API KEYS (via agenix secrets):
  #   - brave-search: Requires Brave Search API key
  #     1. Get API key: https://brave.com/search/api/
  #     2. Create encrypted secret:
  #        echo "your-api-key" | agenix -e secrets/brave-api-key.age
  #     3. Add to your NixOS config:
  #        age.secrets.brave-api-key.file = ./secrets/brave-api-key.age;
  #     Secret path: /run/user/$UID/agenix/brave-api-key
  #
  # 🎮 COMMODORE 64 INTEGRATION:
  #   - ultimate64: Ultimate64 C64 emulator control
  #     REQUIRES: Ultimate64 hardware on local network
  #     OPTIONAL: Set C64_HOST environment variable (e.g., home.sessionVariables.C64_HOST = "192.168.x.x")
  #     Provides: Remote control, file management, video streaming, .prg execution
  #
  # DISABLING MCP SERVERS:
  #   Set services.ai.mcp.enable = false; in your NixOS configuration

  # Claude Code server configuration
  # Syntax follows: https://docs.claude.com/en/docs/claude-code/mcp
  claude-code-servers = {
    # Use mcp-servers-nix modules for built-in servers
    programs = {
      git.enable = true;
      # NOTE: github-mcp-server removed from mcp-servers-nix (now in nixpkgs 25.11)
      # Configured manually in settings.servers below
      time.enable = true;
    };

    # Custom and third-party servers
    settings.servers = {
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # CORE TOOLS (No setup required)
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      # GitHub integration
      # REQUIRES: gh auth login (GitHub CLI authentication)
      # Provides: Repository management, issues, PRs, code search
      github = {
        command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
        args = [ "stdio" ];
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = ''''${GITHUB_PERSONAL_ACCESS_TOKEN}'';
        };
        passwordCommand = {
          GITHUB_PERSONAL_ACCESS_TOKEN = [
            (lib.getExe config.programs.gh.package)
            "auth"
            "token"
          ];
        };
      };

      # Systemd journal access
      # REQUIRES: No setup (automatic for systemd-journal group members)
      # Provides: System log reading and analysis
      journal = {
        command = "${
          inputs.mcp-journal.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/mcp-journal";
      };

      # Nix development environment management
      # REQUIRES: No setup
      # Provides: devShell inspection and management
      nix-devshell-mcp = {
        command = "${
          inputs.nix-devshell-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/nix-devshell-mcp";
      };

      # Ultimate64 C64 emulator control
      # REQUIRES: Ultimate64 hardware on local network
      # Provides: Remote control, file management, video streaming
      # OPTIONAL: Configure C64_HOST in your downstream config:
      #   home.sessionVariables.C64_HOST = "192.168.x.x";
      #   Or use 'ultimate_set_connection' tool at runtime
      ultimate64 = {
        command = "${
          inputs.ultimate64-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/mcp-ultimate";
        args = [ "--stdio" ];
      };
    }
    // {
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # AI ENHANCEMENT SERVERS (No setup required)
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      # Sequential thinking for complex reasoning
      # REQUIRES: No setup
      # Provides: Step-by-step problem solving, chain-of-thought reasoning
      sequential-thinking = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };

      # Context7 - Up-to-date library documentation
      # REQUIRES: No setup
      # Provides: Current documentation for programming libraries and frameworks
      context7 = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@upstash/context7-mcp"
        ];
      };

      # Filesystem access (restricted paths)
      # REQUIRES: No setup
      # Provides: Read/write access to /tmp and ~/Projects only
      filesystem = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
          "${config.home.homeDirectory}/Projects"
        ];
      };

      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      # SEARCH SERVERS (Require API keys via agenix)
      # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      # Brave Search API integration
      # REQUIRES: Brave Search API key
      # Setup:
      #   1. Get API key: https://brave.com/search/api/
      #   2. Create secret: echo "key" | agenix -e secrets/brave-api-key.age
      #   3. Configure: age.secrets.brave-api-key.file = ./secrets/brave-api-key.age;
      # Provides: Web search, news, image search
      brave-search = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-brave-search"
        ];
        env = {
          BRAVE_API_KEY = ''''${BRAVE_API_KEY}'';
        };
        passwordCommand = {
          BRAVE_API_KEY = [
            "${pkgs.bash}/bin/bash"
            "-c"
            "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/brave-api-key | ${pkgs.coreutils}/bin/tr -d '\\n'"
          ];
        };
      };

    };
  };
in
{
  config = lib.mkIf (osConfig.services.ai.mcp.enable or false) {
    # Shell aliases for AI tools
    programs.bash.shellAliases = {
      cm = "claude-monitor";
      cmonitor = "claude-monitor";
      ccm = "claude-monitor";
    };

    programs.zsh.shellAliases = {
      cm = "claude-monitor";
      cmonitor = "claude-monitor";
      ccm = "claude-monitor";
    };

    # Install MCP server packages
    home.packages = [
      inputs.mcp-journal.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.nix-devshell-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.ultimate64-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # Claude Code MCP configuration (declarative)
    # Generate MCP server configuration file for Claude Code CLI
    # Claude Code reads ~/.mcp.json for global MCP server definitions
    # Note: Do NOT overwrite ~/.claude.json as it contains user state and preferences
    home.file.".mcp.json".text = builtins.toJSON {
      mcpServers =
        (inputs.mcp-servers-nix.lib.evalModule pkgs claude-code-servers).config.settings.servers;
    };
  };
}
