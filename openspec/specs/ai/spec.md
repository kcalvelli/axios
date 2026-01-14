# AI & Development Assistance

## Purpose
Integrates advanced AI agents and local inference capabilities into the developer workflow.

## Components

### CLI Agents
- **Tools**: Claude Code, Gemini CLI, Copilot CLI.
- **Workflow**: Auto-injected system prompts for context awareness.
- **Implementation**: `modules/ai/default.nix`, `home/ai/`

### Model Context Protocol (MCP)
- **Servers**: Git, GitHub, Filesystem, Journal, Nix-devshell, etc.
- **Configuration**: Declarative via `programs.claude-code.mcpServers`.
- **Implementation**: `home/ai/mcp.nix`

### Local Inference Stack
- **Backend**: Ollama with ROCm acceleration (AMD GPUs).
- **Frontend**: OpenCode agentic CLI.
- **Reverse Proxy**: Optional Caddy integration for remote access.
- **Implementation**: `modules/ai/default.nix` (Local LLM section)

## Constraints
- **Secrets**: API keys for MCP servers MUST be set via environment variables (e.g., `BRAVE_API_KEY`), not agenix.
- **Context Window**: Ollama is configured with a 32K context window by default for agentic use.
