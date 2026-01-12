{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.ai;

in
{
  options = {
    services.ai = {
      enable = lib.mkEnableOption "AI tools and services (claude-code, gemini-cli)";

      mcp = {
        enable = lib.mkEnableOption "Model Context Protocol (MCP) server integration" // {
          default = true;
        };
      };

      # Per-tool enablement (all default to true for backward compatibility)
      claude = {
        enable = lib.mkEnableOption "Claude Code" // {
          default = true;
        };
      };

      gemini = {
        enable = lib.mkEnableOption "Gemini CLI" // {
          default = true;
        };
      };

      # Unified system prompt
      systemPrompt = {
        enable = lib.mkEnableOption "unified system prompt for AI agents" // {
          default = true;
        };

        extraInstructions = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            Additional custom instructions appended to the axiOS system prompt.
            These are added under the "Custom User Instructions" section.

            Example:
              services.ai.systemPrompt.extraInstructions = '''
                ## Project Standards
                - Use Rust for performance-critical code
                - Include integration tests
                - Follow conventional commits
              ''';
          '';
          example = ''
            ## My Coding Rules
            - Prefer functional patterns
            - Always add comprehensive error handling
          '';
        };
      };

      # MCP server secrets configuration
      secrets = {
        braveApiKeyPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "config.age.secrets.brave-api-key.path";
          description = ''
            Path to Brave API key secret file for MCP brave-search server.
            Used by Gemini CLI and Copilot CLI (Claude Code uses passwordCommand).

            Example with agenix:
              age.secrets.brave-api-key.file = ./secrets/brave-api-key.age;
              services.ai.secrets.braveApiKeyPath = config.age.secrets.brave-api-key.path;
          '';
        };

        githubTokenPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "config.age.secrets.github-token.path";
          description = ''
            Path to GitHub personal access token secret file for MCP github server.
            Used by Gemini CLI and Copilot CLI (Claude Code uses gh auth token).

            Example with agenix:
              age.secrets.github-token.file = ./secrets/github-token.age;
              services.ai.secrets.githubTokenPath = config.age.secrets.github-token.path;

            Alternative: Use gh CLI authentication (recommended for Claude Code)
              Run: gh auth login
          '';
        };
      };

      local = {
        enable = lib.mkEnableOption "local LLM inference stack (Ollama, OpenCode)";

        models = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "qwen3-coder:30b"
            "qwen3:14b"
            "deepseek-coder-v2:16b"
            "qwen3:4b"
          ];
          description = ''
            List of Ollama models to preload on first run.
            Models are pulled automatically when the service starts.
          '';
        };

        rocmOverrideGfx = lib.mkOption {
          type = lib.types.str;
          default = "10.3.0";
          description = ''
            ROCm GPU architecture override for older AMD GPUs.
            Required for gfx1031 (RX 5500/5600/5700 series).
          '';
        };

        ollamaReverseProxy = {
          enable = lib.mkEnableOption "Caddy reverse proxy for Ollama with Tailscale HTTPS" // {
            default = false;
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "/ollama";
            example = "/ai/ollama";
            description = ''
              Path prefix for Ollama reverse proxy.
              Server will be accessible at: {domain}{path}/*
              Example: hostname.tail1234ab.ts.net/ollama
            '';
          };

          domain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "hostname.tail1234ab.ts.net";
            description = ''
              Domain for reverse proxy. If null, uses {hostname}.{tailscale.domain}.
              Must match the domain used by other services for path-based routing.
            '';
          };
        };

        cli = lib.mkEnableOption "OpenCode agentic CLI" // {
          default = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    # Assertions for reverse proxy configuration
    {
      assertions = [
        {
          assertion =
            cfg.enable -> (cfg.local.ollamaReverseProxy.enable -> config.selfHosted.enable or false);
          message = ''
            services.ai.local.ollamaReverseProxy requires selfHosted.enable = true.

            Add to your configuration:
              selfHosted.enable = true;
          '';
        }
      ];
    }

    # Base AI configuration (always enabled when services.ai.enable = true)
    (lib.mkIf cfg.enable {
      # Add users to systemd-journal group using userGroups
      # This avoids infinite recursion by not modifying users.users directly
      users.groups.systemd-journal = {
        members = lib.attrNames (
          lib.filterAttrs (_name: user: user.isNormalUser or false) config.users.users
        );
      };

      # AI tools and packages
      environment.systemPackages =
        with pkgs;
        [
          # Core AI tools (always installed when services.ai.enable = true)
          whisper-cpp # Speech-to-text
          nodejs # For npx MCP servers
          claude-monitor # Real-time Claude Code usage monitoring
          mcp-cli # Dynamic MCP tool discovery for reduced context usage
          spec-kit # Spec-driven development framework
        ]
        # Claude Code (conditional on services.ai.claude.enable)
        ++ lib.optionals cfg.claude.enable [
          claude-code # Anthropic - MCP support, deep integration
          claude-desktop # Nix packaging of claude desktop for debian
          claude-code-acp # Claude Code Agent Communication Protocol
          claude-code-router # Claude Code request router
          # VSCode extension compatibility: claude-code symlink
          (writeShellScriptBin "claude-code" ''
            exec ${claude-code}/bin/claude "$@"
          '')
        ]
        # Gemini CLI (conditional on services.ai.gemini.enable)
        ++ lib.optional cfg.gemini.enable gemini-cli-bin;

      # Load MCP secrets into environment (all shells)
      environment.sessionVariables =
        lib.optionalAttrs (cfg.secrets.githubTokenPath != null) {
          GITHUB_PERSONAL_ACCESS_TOKEN = "$(cat ${cfg.secrets.githubTokenPath} 2>/dev/null | tr -d '\\n')";
        }
        // lib.optionalAttrs (cfg.secrets.braveApiKeyPath != null) {
          BRAVE_API_KEY = "$(cat ${cfg.secrets.braveApiKeyPath} 2>/dev/null | tr -d '\\n')";
        };
    })

    # Local LLM configuration (conditional on services.ai.local.enable)
    (lib.mkIf (cfg.enable && cfg.local.enable) {
      # Ollama service with ROCm acceleration
      services.ollama = {
        enable = true;
        package = pkgs.ollama-rocm;
        rocmOverrideGfx = cfg.local.rocmOverrideGfx;
        environmentVariables = {
          # 32K context window for agentic tool use
          OLLAMA_NUM_CTX = "32768";
        };
        loadModels = cfg.local.models;
      };

      # Ensure amdgpu kernel module loads at boot
      boot.kernelModules = [ "amdgpu" ];

      # Local LLM packages
      environment.systemPackages =
        with pkgs;
        [
          # ROCm debugging
          rocmPackages.rocminfo

          # MCP server runtimes (nodejs already in base config)
          python3
          uv # Python package manager for uvx
        ]
        ++ lib.optional cfg.local.cli pkgs.opencode;
    })

    # Ollama reverse proxy configuration (conditional on ollamaReverseProxy.enable)
    (lib.mkIf (cfg.enable && cfg.local.enable && cfg.local.ollamaReverseProxy.enable) {
      selfHosted.caddy.routes.ollama =
        let
          tailscaleDomain = config.networking.tailscale.domain or null;
          domain =
            if cfg.local.ollamaReverseProxy.domain != null then
              cfg.local.ollamaReverseProxy.domain
            else if tailscaleDomain != null then
              "${config.networking.hostName}.${tailscaleDomain}"
            else
              throw ''
                services.ai.local.ollamaReverseProxy requires either:
                - services.ai.local.ollamaReverseProxy.domain to be set explicitly, OR
                - networking.tailscale.domain to be configured (enable tailscale module)
              '';
          path = cfg.local.ollamaReverseProxy.path;
        in
        {
          inherit domain;
          path = "${path}/*";
          target = "http://127.0.0.1:11434";
          priority = 100; # Path-specific - evaluated before catch-all
        };
    })
  ];
}
