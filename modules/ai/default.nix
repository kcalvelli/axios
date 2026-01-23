{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.ai;
  isServer = cfg.local.role == "server";
  isClient = cfg.local.role == "client";

in
{
  imports = [
    ./webui.nix
  ];

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

      local = {
        enable = lib.mkEnableOption "local LLM inference stack (Ollama, OpenCode)";

        role = lib.mkOption {
          type = lib.types.enum [
            "server"
            "client"
          ];
          default = "server";
          description = ''
            Local LLM deployment role:
            - "server": Run Ollama locally with GPU acceleration
            - "client": Use remote Ollama server (no local GPU required)
          '';
        };

        # Client role options
        serverHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "edge";
          description = "Hostname of Ollama server on tailnet (client role only)";
        };

        tailnetDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "taile0fb4.ts.net";
          description = "Tailscale tailnet domain";
        };

        serverPort = lib.mkOption {
          type = lib.types.port;
          default = 8447;
          description = "HTTPS port of the remote Ollama server (client role only)";
        };

        # Server role options
        tailscaleServe = {
          enable = lib.mkEnableOption "Expose Ollama API via Tailscale HTTPS (server role only)";
          httpsPort = lib.mkOption {
            type = lib.types.port;
            default = 8447;
            description = "HTTPS port for Ollama API on Tailscale";
          };
        };

        models = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "mistral:7b" # 4.4 GB - excellent quality/size ratio, general purpose
            "nomic-embed-text" # 274 MB - for RAG/semantic search
          ];
          description = ''
            List of Ollama models to preload on first run.
            Models are pulled automatically when the service starts.

            Users needing coding models can add them:
              services.ai.local.models = [ "mistral:7b" "nomic-embed-text" "qwen3:14b" ];
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

        keepAlive = lib.mkOption {
          type = lib.types.str;
          default = "1m";
          example = "0";
          description = ''
            Duration to keep models loaded in GPU memory after last request.
            Set to "0" to unload immediately after each request.

            Lower values reduce GPU memory usage but increase model load latency.
            Higher values improve response time but risk VRAM exhaustion during
            continuous operation (e.g., frequent axios-ai-mail queries).

            Default is 1 minute to balance responsiveness with GPU memory pressure.
            Format: "5m" (minutes), "1h" (hours), "0" (immediate unload)
          '';
        };

        cli = lib.mkEnableOption "OpenCode agentic CLI" // {
          default = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    # Assertions for role and configuration validation
    {
      assertions = [
        # Client role requires serverHost
        {
          assertion = !(cfg.enable && cfg.local.enable && isClient) || cfg.local.serverHost != null;
          message = ''
            services.ai.local.role = "client" requires serverHost to be set.

            Example:
              services.ai.local.serverHost = "edge";  # hostname of your Ollama server
          '';
        }
        # Client role requires tailnetDomain
        {
          assertion = !(cfg.enable && cfg.local.enable && isClient) || cfg.local.tailnetDomain != null;
          message = ''
            services.ai.local.role = "client" requires tailnetDomain to be set.

            Example:
              services.ai.local.tailnetDomain = "taile0fb4.ts.net";
          '';
        }
        # Tailscale serve requires server role
        {
          assertion = !cfg.local.tailscaleServe.enable || isServer;
          message = ''
            services.ai.local.tailscaleServe is only available for server role.

            You have role = "client" with tailscaleServe.enable = true.
            Remove tailscaleServe or set role = "server".
          '';
        }
        # Legacy ollamaReverseProxy requires selfHosted (deprecated)
        {
          assertion =
            cfg.enable -> (cfg.local.ollamaReverseProxy.enable -> config.selfHosted.enable or false);
          message = ''
            services.ai.local.ollamaReverseProxy requires selfHosted.enable = true.

            NOTE: ollamaReverseProxy is deprecated. Consider using tailscaleServe instead:
              services.ai.local.tailscaleServe.enable = true;
          '';
        }
      ];

      # Deprecation warning for ollamaReverseProxy
      warnings = lib.optional cfg.local.ollamaReverseProxy.enable ''
        services.ai.local.ollamaReverseProxy is deprecated.

        Use services.ai.local.tailscaleServe instead for simpler Tailscale HTTPS exposure:
          services.ai.local.ollamaReverseProxy.enable = false;
          services.ai.local.tailscaleServe.enable = true;

        The ollamaReverseProxy option will be removed in a future release.
      '';
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
          openspec # OpenSpec CLI tool for SDD workflow
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
        ++ lib.optionals cfg.gemini.enable [
          gemini-cli-bin
          inputs.antigravity-nix.packages.x86_64-linux.default
        ];
    })

    # Server role: Local Ollama with GPU acceleration
    (lib.mkIf (cfg.enable && cfg.local.enable && isServer) {
      # Ollama service with ROCm acceleration
      services.ollama = {
        enable = true;
        package = pkgs.ollama-rocm;
        rocmOverrideGfx = cfg.local.rocmOverrideGfx;
        environmentVariables = {
          # 32K context window for agentic tool use
          OLLAMA_NUM_CTX = "32768";
          # Unload models after inactivity to prevent GPU memory exhaustion
          # Addresses: AMDGPU memory eviction warnings and system freezes
          OLLAMA_KEEP_ALIVE = cfg.local.keepAlive;
          # Prevent concurrent model loads to reduce GPU queue pressure
          OLLAMA_MAX_LOADED_MODELS = "1";
        };
        loadModels = cfg.local.models;
      };

      # Ensure amdgpu kernel module loads at boot
      boot.kernelModules = [ "amdgpu" ];

      # Server role packages (GPU stack + LLM tools)
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

    # Client role: Remote Ollama via Tailscale
    (lib.mkIf (cfg.enable && cfg.local.enable && isClient) {
      # Set OLLAMA_HOST environment variable for all tools that use Ollama
      environment.sessionVariables = {
        OLLAMA_HOST = "https://${cfg.local.serverHost}.${cfg.local.tailnetDomain}:${toString cfg.local.serverPort}";
      };

      # Client role packages (no GPU stack, lighter footprint)
      environment.systemPackages =
        with pkgs;
        [
          # Ollama CLI (uses OLLAMA_HOST for remote server)
          ollama

          # MCP server runtimes
          python3
          uv # Python package manager for uvx
        ]
        ++ lib.optional cfg.local.cli pkgs.opencode;
    })

    # Tailscale serve for Ollama API (server role only)
    (lib.mkIf (cfg.enable && cfg.local.enable && isServer && cfg.local.tailscaleServe.enable) {
      # Systemd service to configure Tailscale serve
      # Note: tailscale serve configuration persists until reset
      systemd.services.tailscale-serve-ollama = {
        description = "Configure Tailscale serve for Ollama API";
        after = [
          "network-online.target"
          "tailscaled.service"
          "ollama.service"
        ];
        wants = [
          "network-online.target"
          "tailscaled.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https ${toString cfg.local.tailscaleServe.httpsPort} http://127.0.0.1:11434";
          ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https ${toString cfg.local.tailscaleServe.httpsPort} off";
        };
      };
    })

    # Legacy: Ollama reverse proxy via Caddy (deprecated, server role only)
    (lib.mkIf (cfg.enable && cfg.local.enable && isServer && cfg.local.ollamaReverseProxy.enable) {
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
