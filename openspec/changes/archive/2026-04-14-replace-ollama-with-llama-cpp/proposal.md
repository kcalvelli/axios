## Why

Ollama wraps llama.cpp but adds its own failure modes — GPU discovery timeouts, flash attention crashes on AMD, memory management issues (`OLLAMA_KEEP_ALIVE` saga), model queue evictions, and a proprietary model format layer on top of GGUF. The downstream consumer (axios-ai-mail) has already migrated to a generic OpenAI-compatible API, so the Ollama abstraction provides zero value and nonzero pain. llama-cpp's `llama-server` speaks the same `/v1/chat/completions` API natively, loads GGUF files directly, and is already packaged in nixpkgs with ROCm and CUDA support.

## What Changes

- **BREAKING**: Remove `services.ollama` configuration and all Ollama-specific environment variables (`OLLAMA_NUM_CTX`, `OLLAMA_KEEP_ALIVE`, `OLLAMA_MAX_LOADED_MODELS`, `OLLAMA_FLASH_ATTENTION`)
- **BREAKING**: Replace `services.ai.local.models` (Ollama model names) with `services.ai.local.model` (path to a single GGUF file)
- **BREAKING**: Remove `services.ai.local.keepAlive` option (llama-server manages its own memory without the eviction problems)
- **BREAKING**: Remove client-role `OLLAMA_HOST` env var; replace with `LLAMA_API_URL` or equivalent pointing at Tailscale Service
- **BREAKING**: Tailscale Services registration changes from `axios-ollama` to `axios-llama`
- Replace `pkgs.ollama` / `pkgs.ollama-rocm` with `pkgs.llama-cpp` (supports ROCm and CUDA via nixpkgs build flags)
- Add a systemd service for `llama-server` (Ollama used NixOS's `services.ollama`; llama-cpp needs a custom unit)
- Update `download-llama-models.sh` references and the `services.ai.local.llamaServer.model` option hint
- Remove `rocmOverrideGfx` option (llama-cpp uses `HSA_OVERRIDE_GFX_VERSION` directly)
- Update all docs and specs to reflect the new stack

## Capabilities

### New Capabilities

_(none — this is a backend replacement, not a new capability)_

### Modified Capabilities

- `ai`: Local inference stack changes from Ollama to llama-cpp. Server/client architecture, GPU acceleration, Tailscale Services registration, and model management all change at the implementation level. Several spec requirements around Ollama-specific behavior (GPU discovery timeouts, flash attention workaround, model preloading) are removed or replaced.
- `networking`: Port allocation changes — Ollama's 11434 is replaced by llama-server's port. Tailscale service name changes from `axios-ollama` to `axios-llama`.

## Impact

- **Code**: `modules/ai/default.nix` — full rewrite of the `services.ai.local` server/client blocks
- **Scripts**: `scripts/download-llama-models.sh` — already targets GGUF, just needs reference updates
- **Downstream**: axios-ai-mail already uses OpenAI-compatible API; no changes needed there
- **Downstream config**: Users with `services.ai.local.enable = true` must update their host configs (model paths instead of model names, removed options)
- **Tailscale**: DNS name changes from `axios-ollama.<tailnet>` to `axios-llama.<tailnet>`
- **Docs**: MODULE_REFERENCE.md, APPLICATIONS.md, TAILSCALE_SERVICES.md, LIBRARY_USAGE.md, specs
