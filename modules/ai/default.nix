{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.ai;
  chatCfg = cfg.chat;
  isServer = cfg.local.role == "server";
  isClient = cfg.local.role == "client";
  tsCfg = config.networking.tailscale;
  useServices = tsCfg.authMode == "authkey";

  # GPU type detection (follows graphics module pattern)
  gpuType = config.axios.hardware.gpuType or null;
  isAmdGpu = gpuType == "amd";
  isNvidiaGpu = gpuType == "nvidia";
in
{
  # Import axios-ai-chat module for Prosody + bot service options
  imports = [
    inputs.axios-ai-chat.nixosModules.default
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

      # axios-ai-chat: Family XMPP chat with AI assistant
      # Optional - requires XMPP infrastructure and LLM backend (Claude API or Ollama)
      chat = {
        enable = lib.mkEnableOption "axios-ai-chat (XMPP + AI bot)";

        domain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "chat.taile0fb4.ts.net";
          description = ''
            XMPP domain for the chat server.
            Defaults to <hostname>.<tailnet> (e.g., edge.taile0fb4.ts.net).

            If you want a custom domain like "chat.taile0fb4.ts.net", you must
            configure DNS to resolve it to this machine's Tailscale IP.
          '';
        };

        xmppPasswordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/agenix/xmpp-bot-password";
          description = ''
            Path to file containing XMPP password for the AI bot.
            Typically points to an agenix-managed secret.
          '';
        };

        # LLM Backend selection
        llmBackend = lib.mkOption {
          type = lib.types.enum [ "anthropic" "ollama" ];
          default = "anthropic";
          description = ''
            LLM backend to use for AI responses:
            - "anthropic": Use Claude API (requires claudeApiKeyFile)
            - "ollama": Use local Ollama server (requires ollamaUrl)
          '';
        };

        # Anthropic/Claude options
        claudeApiKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/agenix/claude-api-key";
          description = ''
            Path to file containing Claude/Anthropic API key.
            Required when llmBackend = "anthropic".
          '';
        };

        # Ollama options
        ollamaUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:11434";
          description = "Ollama API endpoint URL.";
        };

        ollamaModel = lib.mkOption {
          type = lib.types.str;
          default = "qwen3:14b-q4_K_M";
          description = ''
            Ollama model to use. Recommended models for tool calling:
            - qwen3:14b-q4_K_M (best balance, ~8GB VRAM)
            - qwen3:32b-q4_K_M (higher quality, ~18GB VRAM)
            - qwen3:8b-q4_K_M (faster, less accurate, ~5GB VRAM)
          '';
        };

        ollamaTemperature = lib.mkOption {
          type = lib.types.float;
          default = 0.2;
          description = ''
            Temperature for Ollama responses. Lower = more deterministic.
            0.2 is recommended for reliable tool calling.
          '';
        };

        systemPromptFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Optional custom system prompt file for the AI bot.";
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
                        Auto-registers as axios-ollama.<tailnet>.ts.net via Tailscale Services
            - "client": Use remote Ollama server via Tailscale Services (no local GPU required)
          '';
        };

        # Client role options
        tailnetDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "taile0fb4.ts.net";
          description = "Tailscale tailnet domain";
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
        # Client role requires tailnetDomain for Tailscale Services DNS
        {
          assertion = !(cfg.enable && cfg.local.enable && isClient) || cfg.local.tailnetDomain != null;
          message = ''
            services.ai.local.role = "client" requires tailnetDomain to be set.

            Example:
              services.ai.local.tailnetDomain = "taile0fb4.ts.net";
          '';
        }
        # Server role requires authkey mode for Tailscale Services
        {
          assertion = !(cfg.enable && cfg.local.enable && isServer) || useServices;
          message = ''
            services.ai.local.role = "server" requires networking.tailscale.authMode = "authkey".

            Server role uses Tailscale Services for HTTPS, which requires tag-based identity.
            Set up an auth key in the Tailscale admin console with appropriate tags.
          '';
        }
        # axios-chat requires tailnet domain
        {
          assertion = !(cfg.enable && chatCfg.enable) || tsCfg.domain != null;
          message = ''
            services.ai.chat.enable requires networking.tailscale.domain to be set.

            Example:
              networking.tailscale.domain = "taile0fb4.ts.net";
          '';
        }
        # axios-chat requires xmppPasswordFile
        {
          assertion = !(cfg.enable && chatCfg.enable) || chatCfg.xmppPasswordFile != null;
          message = ''
            services.ai.chat.enable requires xmppPasswordFile to be set.

            Example using agenix:
              services.ai.chat.xmppPasswordFile = config.age.secrets.xmpp-bot-password.path;
          '';
        }
        # axios-chat requires claudeApiKeyFile when using anthropic backend
        {
          assertion = !(cfg.enable && chatCfg.enable && chatCfg.llmBackend == "anthropic") || chatCfg.claudeApiKeyFile != null;
          message = ''
            services.ai.chat with llmBackend = "anthropic" requires claudeApiKeyFile to be set.

            Example using agenix:
              services.ai.chat.claudeApiKeyFile = config.age.secrets.claude-api-key.path;

            Or switch to local Ollama:
              services.ai.chat.llmBackend = "ollama";
          '';
        }
        # axios-chat requires authkey mode for Tailscale (Prosody binds to Tailscale IP)
        {
          assertion = !(cfg.enable && chatCfg.enable) || useServices;
          message = ''
            services.ai.chat.enable requires networking.tailscale.authMode = "authkey".

            axios-chat uses Prosody bound to Tailscale IP, which requires tag-based identity.
            Set up an auth key in the Tailscale admin console with appropriate tags.
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
      # Ollama service with GPU acceleration (vendor-specific)
      services.ollama = lib.mkMerge [
        {
          enable = true;
          # Use ollama-rocm for AMD, standard ollama (with CUDA) for Nvidia
          package = if isAmdGpu then pkgs.ollama-rocm else pkgs.ollama;
          environmentVariables = {
            # 32K context window for agentic tool use
            OLLAMA_NUM_CTX = "32768";
            # Unload models after inactivity to prevent GPU memory exhaustion
            # Addresses: AMDGPU memory eviction warnings and system freezes
            OLLAMA_KEEP_ALIVE = cfg.local.keepAlive;
            # Prevent concurrent model loads to reduce GPU queue pressure
            OLLAMA_MAX_LOADED_MODELS = "1";
          }
          // lib.optionalAttrs isAmdGpu {
            # Disable Flash Attention for AMD ROCm - causes assertion failures on RDNA 2 (gfx1030)
            # Error: GGML_ASSERT(max_blocks_per_sm > 0) failed in fattn-common.cuh
            # See: https://github.com/ollama/ollama/issues/6953
            OLLAMA_FLASH_ATTENTION = "0";
          };
          loadModels = cfg.local.models;
        }
        # AMD-specific: ROCm architecture override
        (lib.mkIf isAmdGpu {
          rocmOverrideGfx = cfg.local.rocmOverrideGfx;
        })
      ];

      # Kernel modules (AMD-specific)
      boot.kernelModules = lib.optionals isAmdGpu [ "amdgpu" ];

      # Server role packages (GPU stack + LLM tools)
      environment.systemPackages =
        with pkgs;
        [
          # MCP server runtimes (nodejs already in base config)
          python3
          uv # Python package manager for uvx
        ]
        # AMD-specific: ROCm debugging tools
        ++ lib.optionals isAmdGpu [ rocmPackages.rocminfo ]
        ++ lib.optional cfg.local.cli pkgs.opencode;

      # Tailscale Services registration
      # Provides unique DNS name: axios-ollama.<tailnet>.ts.net
      networking.tailscale.services."axios-ollama" = {
        enable = true;
        backend = "http://127.0.0.1:11434";
      };

      # Local hostname for server access (hairpinning workaround)
      networking.hosts = {
        "127.0.0.1" = [ "axios-ollama.local" ];
      };
    })

    # Client role: Remote Ollama via Tailscale Services
    (lib.mkIf (cfg.enable && cfg.local.enable && isClient) {
      # Set OLLAMA_HOST environment variable for all tools that use Ollama
      # Uses Tailscale Services DNS name (no port needed)
      environment.sessionVariables = {
        OLLAMA_HOST = "https://axios-ollama.${cfg.local.tailnetDomain}";
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

    # axios-chat: Family XMPP chat with AI assistant
    (lib.mkIf (cfg.enable && chatCfg.enable) (
      let
        chatDomain = if chatCfg.domain != null then chatCfg.domain else "chat.${tsCfg.domain}";
      in
      {
        # Apply axios-ai-chat overlay to make axios-ai-bot package available
        nixpkgs.overlays = [ inputs.axios-ai-chat.overlays.default ];

        # Enable Prosody XMPP server (Tailnet-only)
        services.axios-chat.prosody = {
          enable = true;
          domain = chatDomain;
          # Uses Tailscale serve by default - creates chat.<tailnet>.ts.net
          tailscaleServe.enable = true;
          admins = [ "ai@${chatDomain}" ];
        };

        # Enable AI bot
        services.axios-chat.bot = {
          enable = true;
          xmppDomain = chatDomain;
          xmppPasswordFile = chatCfg.xmppPasswordFile;
          # LLM backend configuration
          llmBackend = chatCfg.llmBackend;
          claudeApiKeyFile = chatCfg.claudeApiKeyFile;
          ollamaUrl = chatCfg.ollamaUrl;
          ollamaModel = chatCfg.ollamaModel;
          ollamaTemperature = chatCfg.ollamaTemperature;
          # mcp-gateway runs on localhost:8085 by default
          mcpGatewayUrl = "http://localhost:8085";
          systemPromptFile = chatCfg.systemPromptFile;
        };
      }
    ))
  ];
}
