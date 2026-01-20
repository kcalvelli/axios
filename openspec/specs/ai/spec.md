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
- **Memory Management**: Configurable `OLLAMA_KEEP_ALIVE` duration (default: 5 minutes) to automatically unload idle models and prevent GPU memory exhaustion.
- **Reverse Proxy**: Optional Caddy integration (`services.ai.local.ollamaReverseProxy`) for secure remote access via Tailscale.
- **Implementation**: `modules/ai/default.nix`

## Constraints
- **Secrets**: API keys (e.g., `BRAVE_API_KEY`) MUST be set via environment variables, not `agenix`.
- **GPU Recovery**: Optional AMD GPU hang recovery provided by the graphics module.
- **GPU Memory**: Long-running inference workloads may cause VRAM exhaustion; `keepAlive` option mitigates this by unloading idle models.
