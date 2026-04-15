# AI Spec — Delta: Replace Ollama with llama-cpp

## Changed: Local Inference Stack

**Was**: "Local Inference Stack (Ollama)" with `services.ollama` NixOS module

**Now**: "Local Inference Stack (llama-cpp)" with custom `llama-server` systemd service

### Deployment Roles

_(Server/client architecture unchanged in concept, implementation details updated)_

- **Server Role** (`role = "server"`, default):
  - Runs `llama-server` locally with GPU acceleration
  - Supports both AMD (`llama-cpp-rocm`) and Nvidia (`llama-cpp` with CUDA) GPUs
  - Auto-registers as `cairn-llama.<tailnet>.ts.net` via Tailscale Services

- **Client Role** (`role = "client"`):
  - Connects to remote llama-server via Tailscale Services
  - No local GPU stack installed
  - Sets `LLAMA_API_URL` to `https://cairn-llama.<tailnet>.ts.net`
  - No client-side binary needed (consumers use HTTP API directly)

### Model Management

**Was**: Ollama model names (`mistral:7b`, `nomic-embed-text`) with automatic pull

**Now**: Single GGUF file path. Users download models via `nix run .#download-llama-models` and set:
```nix
services.ai.local.model = "/path/to/model.gguf";
```

### Multi-Vendor GPU Support

| Aspect | AMD | Nvidia |
|--------|-----|--------|
| Package | `llama-cpp-rocm` | `llama-cpp` (CUDA) |
| Flash Attention | Off by default (opt-in via `--flash-attn`) | Off by default |
| Architecture Override | `HSA_OVERRIDE_GFX_VERSION` env var | N/A |
| Kernel Modules | `amdgpu` | (via nixos-hardware) |
| Debug Tools | `rocmPackages.rocminfo` | N/A |

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `services.ai.local.model` | `path` | _(required)_ | Path to GGUF model file |
| `services.ai.local.contextSize` | `int` | `32768` | Context window tokens |
| `services.ai.local.port` | `port` | `11434` | Listen port |
| `services.ai.local.gpuLayers` | `int` | `-1` | GPU offload layers (-1 = all) |
| `services.ai.local.extraArgs` | `listOf str` | `[]` | Additional llama-server flags |

## Removed Requirements

- **GPU Discovery Timeout Awareness**: Ollama-specific hardcoded timeout issue. Not applicable to llama-cpp.
- **Flash Attention (AMD) workaround**: Ollama auto-enabled flash attention causing RDNA 2 crashes. llama-cpp defaults to flash attention off; opt-in only.
- **OLLAMA_KEEP_ALIVE memory management**: llama-server loads one model and keeps it loaded. No eviction timer needed.
- **OLLAMA_MAX_LOADED_MODELS concurrency limit**: llama-server serves one model by design.
- **Model preloading**: No model pull system. Model is specified at service start.

## Removed Options

| Option | Replacement |
|--------|-------------|
| `services.ai.local.models` | `services.ai.local.model` (single GGUF path) |
| `services.ai.local.keepAlive` | _(none — not needed)_ |
| `services.ai.local.rocmOverrideGfx` | `HSA_OVERRIDE_GFX_VERSION` set automatically on AMD |

## Updated Constraints

- **Model Size**: Same VRAM guidance applies. Models larger than VRAM will partially offload to CPU (controllable via `gpuLayers`).
- **GPU Recovery**: AMD GPU hang recovery still enabled by default via graphics module.
- **Secrets**: No change to API key handling.

## Updated References

- **Port Allocations**: llama-server uses port 11434 (same as Ollama was). Tailscale service name changes to `cairn-llama`.
- **PIM Module**: cairn-mail uses OpenAI-compatible API — no change needed, already migrated.
