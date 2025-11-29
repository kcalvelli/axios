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

      local = {
        enable = lib.mkEnableOption "local LLM inference stack (Ollama, LM Studio, OpenCode)";

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

        gui = lib.mkEnableOption "LM Studio native GUI" // {
          default = true;
        };

        cli = lib.mkEnableOption "OpenCode agentic CLI" // {
          default = true;
        };

        llamaServer = {
          enable = lib.mkEnableOption "llama-cpp inference server with ROCm acceleration" // {
            default = true;
          };

          model = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "/models/mistral-instruct-7b-q4_k_m.gguf";
            description = ''
              Path to GGUF model file for llama-cpp server.
              If null, service will not start until configured.
              Recommended quantization: Q4_K_M for balanced performance.
            '';
          };

          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Binding address for llama-cpp server";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 8081;
            description = "Server listening port (default 8081 to avoid conflict with Ollama on 11434)";
          };

          contextSize = lib.mkOption {
            type = lib.types.int;
            default = 4096;
            description = "Context window size in tokens";
          };

          gpuLayers = lib.mkOption {
            type = lib.types.int;
            default = -1;
            description = ''
              Number of layers to offload to GPU.
              -1 = offload all layers (recommended for AMD GPUs with ROCm)
              0 = CPU only
            '';
          };

          extraFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "--numa"
              "numactl"
            ];
            description = ''
              Additional command-line arguments for llama-cpp server.
              Default includes NUMA optimization for multi-die AMD CPUs.
            '';
          };

          reverseProxy = {
            enable = lib.mkEnableOption "Caddy reverse proxy with Tailscale HTTPS" // {
              default = false;
            };

            path = lib.mkOption {
              type = lib.types.str;
              default = "/llama";
              example = "/ai/llama";
              description = ''
                Path prefix for reverse proxy.
                Server will be accessible at: {domain}{path}/*
                Example: hostname.tail1234ab.ts.net/llama
              '';
            };

            domain = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "hostname.tail1234ab.ts.net";
              description = ''
                Domain for reverse proxy. If null, uses {hostname}.{tailscale.domain}.
                Must match the domain used by other services (e.g., Immich) for path-based routing.
              '';
            };
          };
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
            cfg.enable -> (cfg.local.llamaServer.reverseProxy.enable -> config.selfHosted.enable or false);
          message = ''
            services.ai.local.llamaServer.reverseProxy requires selfHosted.enable = true.

            Add to your configuration:
              selfHosted.enable = true;
          '';
        }
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
          # AI assistant tools
          llama-cpp
          whisper-cpp
          nodejs # For npx MCP servers
          claude-monitor # Real-time Claude Code usage monitoring
          (pkgs.writeShellScriptBin "jules" ''
            exec ${pkgs.nodejs_20}/bin/npx @google/jules@latest "$@"
          '')
        ]
        ++ (
          let
            ai-tools = inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system};
          in
          [
            # AI tools
            ai-tools.copilot-cli # GitHub Copilot CLI
            ai-tools.claude-code # Claude CLI with MCP support
            ai-tools.goose-cli
            ai-tools.claude-code-router
            ai-tools.backlog-md
            ai-tools.crush
            ai-tools.forge
            ai-tools.codex
            ai-tools.catnip
            ai-tools.gemini-cli
            ai-tools.spec-kit
          ]
        );
    })

    # Local LLM configuration (conditional on services.ai.local.enable)
    (lib.mkIf (cfg.enable && cfg.local.enable) {
      # Ollama service with ROCm acceleration
      services.ollama = {
        enable = true;
        acceleration = "rocm";
        rocmOverrideGfx = cfg.local.rocmOverrideGfx;
        environmentVariables = {
          # 32K context window for agentic tool use
          OLLAMA_NUM_CTX = "32768";
        };
        loadModels = cfg.local.models;
      };

      # llama-cpp inference server with ROCm acceleration
      services.llama-cpp =
        lib.mkIf (cfg.local.llamaServer.enable && cfg.local.llamaServer.model != null)
          {
            enable = true;
            package = (
              (pkgs.llama-cpp.overrideAttrs (
                finalAttrs: previousAttrs: {
                  cmakeFlags = (previousAttrs.cmakeFlags or [ ]) ++ [
                    "-DGGML_HIP=ON"
                  ];
                }
              )).override
                {
                  rocmSupport = true;
                }
            );
            model = cfg.local.llamaServer.model;
            host = cfg.local.llamaServer.host;
            port = cfg.local.llamaServer.port;
            extraFlags = [
              "-c"
              (toString cfg.local.llamaServer.contextSize)
              "-ngl"
              (toString cfg.local.llamaServer.gpuLayers)
            ]
            # Add API prefix when reverse proxy is enabled
            ++ lib.optionals cfg.local.llamaServer.reverseProxy.enable [
              "--api-prefix"
              cfg.local.llamaServer.reverseProxy.path
            ]
            ++ cfg.local.llamaServer.extraFlags;
          };

      # Add ROCm environment variable for GPU acceleration
      systemd.services.llama-cpp =
        lib.mkIf (cfg.local.llamaServer.enable && cfg.local.llamaServer.model != null)
          {
            environment = {
              HSA_OVERRIDE_GFX_VERSION = cfg.local.rocmOverrideGfx;
            };
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
        ++ lib.optional cfg.local.gui lmstudio
        ++ lib.optional cfg.local.cli (
          inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.opencode
        );
    })

    # llama-server reverse proxy configuration (conditional on reverseProxy.enable)
    (lib.mkIf (cfg.enable && cfg.local.enable && cfg.local.llamaServer.reverseProxy.enable) {
      selfHosted.caddy.routes.llama =
        let
          domain =
            if cfg.local.llamaServer.reverseProxy.domain != null then
              cfg.local.llamaServer.reverseProxy.domain
            else
              "${config.networking.hostName}.${config.networking.tailscale.domain}";
          path = cfg.local.llamaServer.reverseProxy.path;
        in
        {
          inherit domain;
          path = "${path}/*";
          target = "http://127.0.0.1:${toString cfg.local.llamaServer.port}";
          priority = 100; # Path-specific - evaluated before catch-all
        };
    })

    # Ollama reverse proxy configuration (conditional on ollamaReverseProxy.enable)
    (lib.mkIf (cfg.enable && cfg.local.enable && cfg.local.ollamaReverseProxy.enable) {
      selfHosted.caddy.routes.ollama =
        let
          domain =
            if cfg.local.ollamaReverseProxy.domain != null then
              cfg.local.ollamaReverseProxy.domain
            else
              "${config.networking.hostName}.${config.networking.tailscale.domain}";
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
