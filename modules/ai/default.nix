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
      enable = lib.mkEnableOption "AI tools and services (copilot-cli, claude-code)";

      mcp = {
        enable = lib.mkEnableOption "Model Context Protocol (MCP) server integration" // {
          default = true;
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
      environment.systemPackages = with pkgs; [
        # AI assistant tools
        whisper-cpp # Speech-to-text
        nodejs # For npx MCP servers
        claude-monitor # Real-time Claude Code usage monitoring
        mcp-cli # Dynamic MCP tool discovery for reduced context usage

        # CLI Coding Agents (3 distinct AI ecosystems)
        claude-code # Anthropic - MCP support, deep integration
        claude-code-acp # Claude Code Agent Communication Protocol
        claude-code-router # Claude Code request router
        copilot-cli # GitHub/OpenAI - Enterprise, GitHub features
        gemini-cli-bin # Google - Multimodal, free tier

        # Workflow & Support Tools
        spec-kit # Spec-driven development framework

        # VSCode extension compatibility: claude-code symlink
        (writeShellScriptBin "claude-code" ''
          exec ${claude-code}/bin/claude "$@"
        '')
      ];
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
