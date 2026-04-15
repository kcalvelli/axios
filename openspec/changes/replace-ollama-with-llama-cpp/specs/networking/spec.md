# Networking Spec — Delta: Ollama → llama-cpp port/service changes

## Changed: Port Allocations

| Service | Local Port | Tailscale Services | Module | Status |
|---------|------------|-------------------|--------|--------|
| ~~Ollama API~~ | ~~11434~~ | ~~8447~~ | ~~`ai.local`~~ | **Removed** |
| llama-server API | 11434 | axios-llama (443) | `ai.local` | **Active** |

Port 11434 is reused for backward compatibility with any tooling that hardcoded it.

## Changed: Tailscale Services

| Old Name | New Name |
|----------|----------|
| `axios-ollama` | `axios-llama` |

DNS changes from `axios-ollama.<tailnet>.ts.net` to `axios-llama.<tailnet>.ts.net`.
