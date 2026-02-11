# AI & Development Assistance

## Purpose
Integrates advanced AI agents and local inference capabilities into the developer workflow, prioritizing efficiency and context-awareness.

## Components

### CLI Coding Agents
- **Claude Ecosystem**:
    - `claude-code`: Primary CLI agent with deep MCP integration.
    - `claude-code-acp`: Agent Communication Protocol support.
    - `claude-code-router`: Request routing for Claude services.
    - `claude-desktop`: Desktop integration layer.
- **Gemini Ecosystem**:
    - `gemini-cli-bin`: Multimodal CLI agent.
    - **Authentication**: Uses an OAuth flow for Pro accounts (`gemini auth login`). API keys are not recommended for Pro users as they bypass the subscription.
    - **Configuration**: System prompt is managed via the `GEMINI_SYSTEM_MD` environment variable, set declaratively in `home/ai/mcp.nix`.
    - `antigravity`: Advanced agentic assistant for axiOS development.
- **Workflow Tools**:
    - `openspec`: OpenSpec SDD workflow CLI for spec-driven development.
    - `whisper-cpp`: Speech-to-text.
    - `claude-monitor`: Resource monitoring for AI sessions.
- **Implementation**: `modules/ai/default.nix`, `home/ai/`

### System Prompt Management
- **Unified Prompt**: axiOS provides a system prompt at `~/.config/ai/prompts/axios.md` containing PIM domain hints and custom user instructions.
- **Auto-Injection**: Automatically injected into `~/.claude.json` during system activation.
- **Customization**: Users can append instructions via `services.ai.systemPrompt.extraInstructions`.

### Model Context Protocol (MCP)
- **Token Reduction Strategy**: Claude Code uses built-in tools only; MCP servers are accessed on-demand via the `/mcp-cli` skill, reducing context window usage by up to 99%.
- **No Native MCP**: `~/.mcp.json` generation is disabled by default (`generateClaudeConfig = false`). Claude Code does not spawn MCP servers natively.
- **mcp-cli**: Binary and `/mcp-cli` skill are provided by the mcp-gateway module (not axios).
- **Servers**: Git, GitHub, Filesystem, Journal, Nix-devshell, etc.
- **Configuration**: Declarative via `services.mcp-gateway` (from external mcp-gateway repo).
- **Implementation**: Server definitions in `home/ai/mcp.nix`, module logic in `github.com/kcalvelli/mcp-gateway`

### Local Inference Stack (Ollama)

**Deployment Roles:**

The local LLM stack supports server/client architecture for distributed inference:

- **Server Role** (`role = "server"`, default):
  - Run Ollama locally with GPU acceleration
  - Supports both AMD (ROCm) and Nvidia (CUDA) GPUs
  - Auto-registers as `axios-ollama.<tailnet>.ts.net` via Tailscale Services

- **Client Role** (`role = "client"`):
  - Connect to remote Ollama server via Tailscale Services
  - No local GPU stack installed (lighter footprint)
  - Sets `OLLAMA_HOST` to `https://axios-ollama.<tailnet>.ts.net`
  - Only requires `tailnetDomain` configuration
  - Ideal for lightweight laptops using a desktop as inference server

> **Note**: Client role requires a server with `networking.tailscale.authMode = "authkey"` running on the tailnet. The server must be deployed first to register the Tailscale Services.

**Default Models**: Minimal set for general use:
- `mistral:7b` (4.4 GB) - General purpose, excellent quality/size ratio
- `nomic-embed-text` (274 MB) - For RAG/semantic search

**Multi-Vendor GPU Support:**

The server role automatically detects GPU vendor from the host's `hardware.gpu` configuration:

| Aspect | AMD | Nvidia |
|--------|-----|--------|
| Package | `ollama-rocm` | `ollama` (CUDA) |
| Flash Attention | Disabled | Enabled |
| Architecture Override | `rocmOverrideGfx` | N/A |
| Kernel Modules | `amdgpu` | (via nixos-hardware) |
| Debug Tools | `rocmPackages.rocminfo` | N/A |

```nix
# Host config determines GPU vendor (no additional AI module config needed)
{ hardware.gpu = "amd"; }   # Uses ollama-rocm, disables Flash Attention
{ hardware.gpu = "nvidia"; } # Uses ollama with CUDA, Flash Attention enabled
```

**Acceleration**: Vendor-specific GPU acceleration (server role only).

**Context Window**: Configured for 32K tokens (`OLLAMA_NUM_CTX`) to support agentic workflows.

**Memory Management**: Configurable `OLLAMA_KEEP_ALIVE` duration (default: 1 minute) to automatically unload idle models and prevent GPU memory exhaustion.

**Concurrency Limit**: Single model loading (`OLLAMA_MAX_LOADED_MODELS=1`) to prevent queue evictions.

**Network Access**:
- **Tailscale Services** (default for authkey mode): Auto-registers as `axios-ollama.<tailnet>.ts.net` on port 443.
- **Tailscale Serve** (legacy): `services.ai.local.tailscaleServe.enable = true` exposes on custom port (interactive auth mode only).
- **Caddy Reverse Proxy** (deprecated): `services.ai.local.ollamaReverseProxy` - legacy path-based routing via Caddy.

**Implementation**: `modules/ai/default.nix`

### MCP Gateway (External Repository)

REST API gateway that exposes axios MCP servers via OpenAPI endpoints and MCP HTTP transport.

**Repository**: `github.com/kcalvelli/mcp-gateway`

**Purpose**:
- Bridge between axios MCP ecosystem and tools that don't natively support MCP
- Provide MCP HTTP transport for Claude.ai Integrations and Claude Desktop
- Own the declarative MCP configuration module (single source of truth)

**Architecture:**

mcp-gateway is a standalone repository that provides:
- **Package**: `mcp-gateway` Python FastAPI application
- **Home-Manager Module**: Declarative MCP server configuration

axios imports mcp-gateway's module and layers on axios-specific features:
- **System Prompts**: `axios.md` (in `home/ai/prompts/`) — PIM domain hints and custom user instructions
- **OpenSpec Commands**: `/proposal`, `/apply`, `/archive` (in `home/ai/commands/`)
- **Global CLAUDE.md**: `~/.claude/CLAUDE.md` with `@import` of axios prompt

```
┌─────────────────────────────────────────────────────────────────┐
│                   axios (home/ai/mcp.nix)                       │
│  - Imports mcp-gateway's home-manager module                    │
│  - Provides server definitions with resolved nix store paths    │
│  - Adds system prompts (PIM hints), commands, ~/.claude/CLAUDE.md│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    mcp-gateway module                           │
│  - Evaluates server declarations                                │
│  - Generates ~/.config/mcp/mcp_servers.json                     │
│  - Installs mcp-cli binary + /mcp-cli skill for Claude Code    │
│  - Configures systemd service                                   │
└─────────────────────────────────────────────────────────────────┘
```

**API Endpoints:**
- `GET /api/servers` - List all configured MCP servers
- `PATCH /api/servers/{id}` - Enable/disable a server
- `GET /api/tools` - List all available tools
- `POST /api/tools/{server}/{tool}` - Execute a tool
- `GET /health` - Health check
- `GET /mcp` - MCP HTTP transport endpoint (SSE)
- `POST /mcp/message` - MCP message endpoint

**Configuration** (via mcp-gateway home-manager module):
```nix
services.mcp-gateway = {
  enable = true;
  port = 8085;
  autoEnable = [ "git" "github" "filesystem" "context7" ];

  servers = {
    git = {
      enable = true;
      command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
    };
    github = {
      enable = true;
      command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
      args = [ "stdio" ];
      passwordCommand.GITHUB_PERSONAL_ACCESS_TOKEN = [ "gh" "auth" "token" ];
    };
    # ... more servers
  };
};
```

**Port Allocations:**
| Service | Local Port | Tailscale Services |
|---------|------------|-------------------|
| MCP Gateway | 8085 | axios-mcp-gateway (443) |

**Implementation**:
- Repository: `github.com/kcalvelli/mcp-gateway`
- axios integration: `home/ai/mcp.nix`

**SDK Architecture:**
The MCP Gateway uses official MCP SDK libraries for protocol compliance:
- **Client**: Uses `mcp` package (`mcp.client.stdio`, `ClientSession`) for connecting to MCP servers
- **Servers**: axios MCP servers use `fastmcp` or `mcp.server.fastmcp` for the server side

| Component | SDK | Package |
|-----------|-----|---------|
| mcp-gateway (client) | `mcp` | `python3Packages.mcp` |
| mcp-dav (server) | `fastmcp` | `python3Packages.fastmcp` |
| axios-ai-mail (server) | `mcp.server.fastmcp` | `python3Packages.mcp` |

**Features:**
- `passwordCommand` support for secure secret retrieval (e.g., `gh auth token`)
- MCP HTTP transport for Claude.ai Integrations
- Automatic npx server support (bash, nodejs in service PATH)
- Non-blocking auto-enable on startup
- Generates configs for Gemini CLI and mcp-cli (`~/.config/mcp/mcp_servers.json`)
- `generateClaudeConfig` (default: `false`) — controls `~/.mcp.json` generation
- `generateClaudeSkill` (default: `true`) — installs `/mcp-cli` skill to `~/.claude/commands/mcp-cli.md`
- Provides `mcp-cli` binary via `home.packages`

## Requirements

### Requirement: GPU Discovery Timeout Awareness

Ollama's GPU discovery timeout is **hardcoded upstream** and cannot be configured by axiOS.

#### Known Limitation

- **Memory refresh timeout**: 3 seconds (hardcoded in Ollama)
- **Bootstrap timeout**: 30 seconds (hardcoded in Ollama)
- **No env var exists**: `OLLAMA_GPU_DISCOVERY_TIMEOUT` is not supported
- **Upstream PR**: #13186 (open) would extend to 10s when `HSA_OVERRIDE_GFX_VERSION` is set

#### Scenario: GPU discovery during desktop activity

- **Given**: User is running a Wayland desktop with GPU-accelerated compositor
- **And**: Ollama attempts to refresh GPU memory availability (3-second timeout)
- **When**: ROCm runtime queries take longer than 3 seconds due to GPU load
- **Then**: Ollama logs "failed to finish discovery before timeout"
- **And**: Ollama falls back to stale memory values (may cause oversubscription)

## Constraints
- **Secrets**: API keys (e.g., `BRAVE_API_KEY`) SHOULD be set via `agenix` for security. Fallback to environment variables is provided. `gemini` Pro accounts should use OAuth (`gemini auth login`) instead of API keys.
- **GPU Recovery**: AMD GPU hang recovery enabled by default via graphics module; prevents hard freezes from GPU hangs.
- **GPU Memory**: Long-running inference workloads may cause VRAM exhaustion; `keepAlive` option mitigates this by unloading idle models.
- **Model Size**: Models larger than available VRAM trigger CPU offload, causing ROCm queue evictions and degraded performance.
- **GPU Discovery**: ROCm GPU discovery has a hardcoded 3-second timeout in Ollama; this cannot be configured and may cause stale memory fallback under load.
- **Flash Attention (AMD)**: Flash Attention is disabled for AMD ROCm GPUs (`OLLAMA_FLASH_ATTENTION=0`) due to assertion failures on RDNA 2 (gfx1030) architecture. Nvidia GPUs are unaffected. GPU vendor is determined by the host's `hardware.gpu` configuration.

## Model Size Guidance

| VRAM | Recommended Max Model | Examples |
|------|----------------------|----------|
| 8 GB | 7B-8B parameters | mistral:7b, phi3 |
| 12 GB | 14B parameters | qwen3:14b, deepseek-coder-v2:16b |
| 16 GB | 22B-30B parameters | qwen3-coder:30b |
| 24 GB | 70B parameters | Large coding models |

Users needing coding models can extend the defaults:
```nix
services.ai.local.models = [ "mistral:7b" "nomic-embed-text" "qwen3:14b" ];
```

**Warning**: Running models larger than VRAM causes partial CPU offload, which creates excessive ROCm compute queues and triggers "queue evicted" kernel warnings. This can lead to system instability.

## GPU Troubleshooting

### Symptoms: "failure during GPU discovery" / "failed to finish discovery before timeout"

**Cause**: ROCm runtime queries exceeding Ollama's hardcoded 3-second timeout.

**Root Cause**: Ollama's GPU memory refresh timeout is hardcoded at 3 seconds and cannot be configured. Under GPU load (compositor, other apps), ROCm queries may take longer.

**Mitigations** (workarounds, not fixes):
1. Reduce concurrent GPU workloads during ollama inference
2. Use smaller models that fit comfortably in VRAM with headroom
3. Avoid `keep_alive: 0` patterns that cause frequent model load/unload cycles
4. Accept that discovery timeouts will occur under load; Ollama will use stale values

**Note**: With GPU recovery enabled (default for AMD), discovery timeout issues won't cause hard freezes—worst case is suboptimal model scheduling.

### Symptoms: "queue evicted" kernel warnings

**Cause**: ROCm compute queue oversubscription from multiple GPU processes or oversized models.

**Mitigations**:
1. Ensure `OLLAMA_MAX_LOADED_MODELS=1` (default in axiOS)
2. Avoid models that require CPU offload
3. Check `amd_smi` or `rocm-smi` for VRAM usage before loading large models

### Symptoms: "GGML_ASSERT(max_blocks_per_sm > 0) failed" / Ollama crash on chat

**Cause**: Flash Attention auto-enabled on AMD GPU that doesn't support it.

**Applies to**: AMD ROCm only (Nvidia unaffected)

**Error Pattern**:
```
llama_context: Flash Attention was auto, set to enabled
fattn-common.cuh:903: GGML_ASSERT(max_blocks_per_sm > 0) failed
SIGABRT: abort
```

**Fix**: axiOS automatically disables Flash Attention when `hardware.gpu = "amd"`. If you see this error, verify your host config has the correct GPU vendor set.

**Note**: Flash Attention primarily benefits larger models (30B+) with very long contexts. For 7B-14B models typical in axiOS, the performance difference is negligible.

## References

- **Port Allocations**: See `openspec/specs/networking/ports.md` for axios port registry
  - Ollama API: Local 11434, Tailscale 8447
- **PIM Module**: See `openspec/specs/pim/spec.md` for axios-ai-mail (uses Ollama for AI classification)
- **Crash Diagnostics**: See `openspec/specs/hardware/crash-diagnostics.md` for GPU hang recovery
