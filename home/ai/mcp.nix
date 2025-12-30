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

  # Note: Server paths are resolved by mcp-servers-nix.lib.evalModule
  # No need to pre-resolve paths here

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
      # GitHub MCP server (from nixpkgs 25.11+)
      # Previously provided by mcp-servers-nix, now in nixpkgs
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

      # axios custom MCP servers
      journal = {
        command = "${
          inputs.mcp-journal.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/mcp-journal";
      };

      nix-devshell-mcp = {
        command = "${
          inputs.nix-devshell-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/nix-devshell-mcp";
      };

      ultimate64 = {
        command = "${
          inputs.ultimate64-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/mcp-ultimate";
        args = [ "--stdio" ];
        # Note: Users can optionally set C64_HOST in their local config:
        #   programs.claude-code.mcpServers.ultimate64.env.C64_HOST = "your-c64-ip";
        # If not set, use the 'ultimate_set_connection' tool to configure at runtime
      };

      mcp-nixos = {
        command = "${pkgs.nix}/bin/nix";
        args = [
          "run"
          "github:utensils/mcp-nixos"
          "--"
        ];
        env = {
          MCP_NIXOS_CLEANUP_ORPHANS = "true";
        };
      };

      # AI enhancement servers
      sequential-thinking = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };

      context7 = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@upstash/context7-mcp"
        ];
      };

      # Filesystem access (restricted to /tmp and ~/Projects)
      filesystem = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
          "${config.home.homeDirectory}/Projects"
        ];
      };

      # Search tools (require API keys)
      # Users should configure secrets in their downstream config:
      #   age.secrets.brave-api-key.file = ./secrets/brave-api-key.age;
      #   age.secrets.tavily-api-key.file = ./secrets/tavily-api-key.age;
      brave-search = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-brave-search"
        ];
        passwordCommand = lib.mkIf ((config.age or null) != null && (config.age.secrets ? brave-api-key)) {
          BRAVE_API_KEY = [
            "${pkgs.coreutils}/bin/cat"
            config.age.secrets.brave-api-key.path
          ];
        };
        # Fallback to environment variable if secret not configured
        env = lib.mkIf ((config.age or null) == null || !(config.age.secrets ? brave-api-key)) {
          BRAVE_API_KEY = ''''${BRAVE_API_KEY}'';
        };
      };

      tavily = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "tavily-mcp"
        ];
        passwordCommand = lib.mkIf ((config.age or null) != null && (config.age.secrets ? tavily-api-key)) {
          TAVILY_API_KEY = [
            "${pkgs.coreutils}/bin/cat"
            config.age.secrets.tavily-api-key.path
          ];
        };
        # Fallback to environment variable if secret not configured
        env = lib.mkIf ((config.age or null) == null || !(config.age.secrets ? tavily-api-key)) {
          TAVILY_API_KEY = ''''${TAVILY_API_KEY}'';
        };
      };
    };
  };
in
{
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
    mcpServers = (inputs.mcp-servers-nix.lib.evalModule pkgs claude-code-servers).config.settings.servers;
  };

  # Note: Future AI tools can be added here by defining additional server configs
  # Example for Neovim with mcphub:
  #   home.file."${config.xdg.configHome}/mcphub/servers.json".source =
  #     inputs.mcp-servers-nix.lib.mkConfig pkgs mcphub-servers;
}
