# Ollama Memory Management - Defect Fix

## Summary
**Defect**: AMD GPU instability after extended Ollama usage due to VRAM exhaustion from models remaining loaded indefinitely.

**Root Cause**: Ollama's default `OLLAMA_KEEP_ALIVE` is 5 minutes, but without explicit configuration, models loaded via frequent API calls (e.g., axios-ai-mail) accumulate in GPU memory, leading to:
- AMDGPU memory eviction warnings
- GPU queue evictions
- Hard system freezes (no kernel panic logged)

**Solution**: Add configurable `OLLAMA_KEEP_ALIVE` option with a sensible default (5 minutes) to ensure idle models are unloaded, preventing VRAM exhaustion during continuous operation.

## Tasks

- [x] Create OpenSpec delta directory structure
- [x] Stage updated AI spec with new memory management documentation
- [x] Create tasks.md (this file)
- [x] Implement `services.ai.local.keepAlive` option in `modules/ai/default.nix`
- [x] Set `OLLAMA_KEEP_ALIVE` environment variable in Ollama service config
- [x] Format code with `nix fmt .`
- [x] Test configuration builds successfully (`nix flake check --no-build` passed)
- [ ] Update main specs and archive this change (after user verification)

## Implementation Details

### New Option
```nix
services.ai.local.keepAlive = lib.mkOption {
  type = lib.types.str;
  default = "5m";  # 5 minutes - conservative default
  description = ''
    Duration to keep models loaded in GPU memory after last request.
    Set to "0" to unload immediately after each request.

    Lower values reduce GPU memory usage but increase model load latency.
    Higher values improve response time but risk VRAM exhaustion.

    Format: "5m" (minutes), "1h" (hours), "0" (immediate unload)
  '';
};
```

### Environment Variable
Add to `services.ollama.environmentVariables`:
```nix
OLLAMA_KEEP_ALIVE = cfg.local.keepAlive;
```

## References
- Ollama environment variables: https://github.com/ollama/ollama/blob/main/docs/faq.md#how-do-i-configure-ollama-server
- Related GPU recovery: `openspec/specs/graphics/spec.md`
