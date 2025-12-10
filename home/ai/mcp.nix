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
      github = {
        enable = true;
        passwordCommand = {
          GITHUB_PERSONAL_ACCESS_TOKEN = [
            (lib.getExe config.programs.gh.package)
            "auth"
            "token"
          ];
        };
        type = "stdio";
      };
      time.enable = true;
    };

    # Custom and third-party servers
    settings.servers = {
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
  ];

  # Claude Code MCP configuration (declarative)
  # This replaces the imperative activation script approach
  programs.claude-code = {
    enable = true;
    mcpServers =
      (inputs.mcp-servers-nix.lib.evalModule pkgs claude-code-servers).config.settings.servers;
  };

  # Note: Future AI tools can be added here by defining additional server configs
  # Example for Neovim with mcphub:
  #   home.file."${config.xdg.configHome}/mcphub/servers.json".source =
  #     inputs.mcp-servers-nix.lib.mkConfig pkgs mcphub-servers;
}
