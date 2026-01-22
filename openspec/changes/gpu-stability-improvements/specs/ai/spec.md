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
    - `antigravity`: Advanced agentic assistant for axiOS development.
- **Workflow Tools**:
    - `whisper-cpp`: Speech-to-text.
    - `claude-monitor`: Resource monitoring for AI sessions.
- **Implementation**: `modules/ai/default.nix`, `home/ai/`

### System Prompt Management
- **Unified Prompt**: axiOS provides a comprehensive system prompt at `~/.config/ai/prompts/axios.md`.
- **Auto-Injection**: Automatically injected into `~/.claude.json` during system activation.
- **Customization**: Users can append instructions via `services.ai.systemPrompt.extraInstructions`.

### Model Context Protocol (MCP)
- **Token Reduction Strategy**: Uses `mcp-cli` for dynamic tool discovery, reducing context window usage by up to 99%.
- **Servers**: Git, GitHub, Filesystem, Journal, Nix-devshell, etc.
- **Configuration**: Declarative via `programs.claude-code.mcpServers`.
- **Implementation**: `home/ai/mcp.nix`

### Local Inference Stack (Ollama)
- **Default Models**: Minimal set for general use:
    - `mistral:7b` (4.4 GB) - General purpose, excellent quality/size ratio
    - `nomic-embed-text` (274 MB) - For RAG/semantic search
- **Acceleration**: ROCm for AMD GPUs (default gfx1030/10.3.0 override).
- **Context Window**: Configured for 32K tokens (`OLLAMA_NUM_CTX`) to support agentic workflows.
- **Memory Management**: Configurable `OLLAMA_KEEP_ALIVE` duration (default: 1 minute) to automatically unload idle models and prevent GPU memory exhaustion.
- **Concurrency Limit**: Single model loading (`OLLAMA_MAX_LOADED_MODELS=1`) to prevent queue evictions.
- **Reverse Proxy**: Optional Caddy integration (`services.ai.local.ollamaReverseProxy`) for secure remote access via Tailscale.
- **Implementation**: `modules/ai/default.nix`

## ADDED Requirements

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

#### Scenario: Clean session startup after ollama usage

- **Given**: User ran ollama inference in a previous session
- **And**: User logs out and back in
- **When**: Desktop session initializes (quickshell, niri, etc.)
- **Then**: GPU state SHOULD be clean with no stale allocations
- **And**: Desktop components SHOULD start without SIGSEGV from GPU resource conflicts

### Requirement: GPU Memory Headroom

Ollama MUST reserve memory headroom for desktop GPU usage.

#### Scenario: Model loading with desktop running

- **Given**: Desktop compositor and shell are using GPU resources
- **And**: `services.ai.local.gpuMemoryReserve` is configured (default: 512MB)
- **When**: Ollama calculates available VRAM for model loading
- **Then**: Ollama SHOULD subtract the reserve from available memory
- **And**: Models SHOULD NOT trigger queue evictions during normal desktop use

## Constraints
- **Secrets**: API keys (e.g., `BRAVE_API_KEY`) MUST be set via environment variables, not `agenix`.
- **GPU Recovery**: AMD GPU hang recovery enabled by default via graphics module; prevents hard freezes from GPU hangs.
- **GPU Memory**: Long-running inference workloads may cause VRAM exhaustion; `keepAlive` option mitigates this by unloading idle models.
- **Model Size**: Models larger than available VRAM trigger CPU offload, causing ROCm queue evictions and degraded performance.
- **GPU Discovery**: ROCm GPU discovery has a hardcoded 3-second timeout in Ollama; this cannot be configured and may cause stale memory fallback under load.

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
