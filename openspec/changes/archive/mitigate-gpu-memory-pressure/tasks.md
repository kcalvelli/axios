# Mitigate GPU Memory Pressure - Tasks

## Summary

Reduce AMDGPU queue evictions by adjusting Ollama memory management defaults and limiting concurrent model loads.

## Tasks

### Phase 1: Ollama Configuration Changes

- [ ] Change `services.ai.local.keepAlive` default from `"5m"` to `"1m"`
- [ ] Add `OLLAMA_MAX_LOADED_MODELS=1` environment variable
- [ ] Update `modules/ai/default.nix` with new defaults
- [ ] Format code with `nix fmt .`
- [ ] Run `nix flake check --no-build` to validate

### Phase 2: Documentation

- [ ] Update AI spec with VRAM constraint guidance
- [ ] Document recommended model sizes for 12GB systems
- [ ] Add queue eviction troubleshooting notes

### Phase 3: Validation

- [ ] Test configuration builds successfully
- [ ] Monitor logs for reduced eviction frequency after deployment
- [ ] Update tasks.md with results

## Implementation Details

### Ollama Environment Variables

**File**: `modules/ai/default.nix`

Current:
```nix
environment.sessionVariables = {
  OLLAMA_KEEP_ALIVE = cfg.local.keepAlive;  # default "5m"
  OLLAMA_NUM_CTX = "32768";
};
```

Proposed:
```nix
environment.sessionVariables = {
  OLLAMA_KEEP_ALIVE = cfg.local.keepAlive;  # default "1m" (changed)
  OLLAMA_NUM_CTX = "32768";
  OLLAMA_MAX_LOADED_MODELS = "1";  # prevent concurrent model loads
};
```

### Model Size Guidance (for AI spec)

| VRAM | Recommended Max Model | Notes |
|------|----------------------|-------|
| 8 GB | 7B-8B | Full GPU, minimal headroom |
| 12 GB | 14B | Full GPU, ~3GB headroom |
| 16 GB | 22B-30B | Comfortable headroom |
| 24 GB | 70B | Large models, full GPU |

Models larger than VRAM trigger CPU offload, causing queue evictions.

## Acceptance Criteria

1. [ ] `keepAlive` default changed to `"1m"`
2. [ ] `OLLAMA_MAX_LOADED_MODELS=1` added
3. [ ] AI spec documents VRAM constraints
4. [ ] Configuration passes flake check
5. [ ] (Post-deploy) Reduced eviction frequency in logs
