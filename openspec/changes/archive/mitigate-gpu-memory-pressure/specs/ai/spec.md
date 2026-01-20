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
- **Acceleration**: ROCm for AMD GPUs (default gfx1030/10.3.0 override).
- **Context Window**: Configured for 32K tokens (`OLLAMA_NUM_CTX`) to support agentic workflows.
- **Memory Management**: Configurable `OLLAMA_KEEP_ALIVE` duration (default: 1 minute) to automatically unload idle models and prevent GPU memory exhaustion.
- **Concurrency Limit**: Single model loading (`OLLAMA_MAX_LOADED_MODELS=1`) to prevent queue evictions.
- **Reverse Proxy**: Optional Caddy integration (`services.ai.local.ollamaReverseProxy`) for secure remote access via Tailscale.
- **Implementation**: `modules/ai/default.nix`

## MODIFIED Requirements

### Requirement: Ollama Memory Management Defaults

Ollama MUST be configured with conservative memory management defaults to prevent GPU queue evictions on systems with limited VRAM.

#### Scenario: Idle model unloading

- **Given**: An Ollama model has been loaded for inference
- **And**: No requests have been made for 1 minute
- **When**: The keepAlive timeout expires
- **Then**: The model is automatically unloaded from VRAM
- **And**: GPU memory is freed for other applications

#### Scenario: Concurrent model prevention

- **Given**: A user requests inference with model A
- **And**: Model A is currently loaded
- **When**: Another request arrives for model B
- **Then**: Model A is unloaded before model B loads
- **And**: Only one model occupies VRAM at a time

## ADDED Requirements

### Requirement: VRAM Constraint Documentation

Users MUST be informed of recommended model sizes based on their GPU VRAM capacity to avoid performance degradation from CPU offloading.

#### Scenario: User selects appropriate model for 12GB VRAM

- **Given**: User has a GPU with 12GB VRAM (e.g., RX 6700 XT, RX 6750 XT)
- **When**: User consults the model size guidance
- **Then**: User sees that models up to 14B parameters are recommended
- **And**: User understands that larger models cause CPU offload and queue evictions

## Constraints
- **Secrets**: API keys (e.g., `BRAVE_API_KEY`) MUST be set via environment variables, not `agenix`.
- **GPU Recovery**: Optional AMD GPU hang recovery provided by the graphics module.
- **GPU Memory**: Long-running inference workloads may cause VRAM exhaustion; `keepAlive` option mitigates this by unloading idle models.
- **Model Size**: Models larger than available VRAM trigger CPU offload, causing ROCm queue evictions and degraded performance.

## Model Size Guidance

| VRAM | Recommended Max Model | Examples |
|------|----------------------|----------|
| 8 GB | 7B-8B parameters | mistral:7b, phi3 |
| 12 GB | 14B parameters | qwen3:14b, deepseek-coder-v2:16b |
| 16 GB | 22B-30B parameters | qwen3-coder:30b |
| 24 GB | 70B parameters | Large coding models |

**Warning**: Running models larger than VRAM causes partial CPU offload, which creates excessive ROCm compute queues and triggers "queue evicted" kernel warnings. This can lead to system instability.
