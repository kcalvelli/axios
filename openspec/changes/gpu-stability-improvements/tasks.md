# GPU Stability Improvements - Tasks

## Summary

Address GPU stability issues causing hard freezes and application crashes on AMD systems with local AI inference workloads.

## Tasks

### Phase 1: Critical - Enable GPU Hang Recovery by Default

- [x] Update `modules/graphics/default.nix` to enable GPU recovery by default for AMD GPUs
- [x] Add `amdgpu.lockup_timeout=5000` parameter alongside `gpu_recovery=1`
- [x] Change option default from `false` to `true` when `gpuType == "amd"`
- [x] Update option description to reflect new default behavior
- [ ] Test GPU hang recovery by simulating load (optional - requires careful testing)

### Phase 2: GPU Discovery Timeout Mitigation

- [x] Research if Ollama supports `OLLAMA_GPU_DISCOVERY_TIMEOUT` or similar environment variable
  - **Finding**: No such env var exists. Timeouts are hardcoded:
    - Bootstrap discovery: 30 seconds (hardcoded)
    - Memory refresh: 3 seconds (hardcoded) ← causes "failed to finish discovery before timeout"
    - Model load: 5 minutes (`OLLAMA_LOAD_TIMEOUT`, configurable but unrelated)
  - **Upstream**: PR #13186 (open, not merged) would extend to 10s when `HSA_OVERRIDE_GFX_VERSION` is set
- [x] If not supported: Document the limitation
  - Limitation documented below; no axios-side fix possible
- [ ] Consider upstream contribution to add `OLLAMA_GPU_DISCOVERY_TIMEOUT` (optional, future work)

### Phase 3: GPU Memory Headroom (Deferred)

- [ ] Research how Ollama calculates available VRAM
- [ ] Determine if headroom can be configured via environment variable
- [ ] Add option `services.ai.local.gpuMemoryReserve` if feasible
- [ ] Document recommended VRAM headroom for desktop usage

### Phase 4: Documentation & Spec Updates

- [ ] Update `openspec/specs/ai/spec.md` with GPU troubleshooting section
- [ ] Update `openspec/specs/desktop/spec.md` with GPU correlation notes
- [ ] Update `openspec/specs/graphics/spec.md` with recovery recommendation for AI workloads
- [ ] Add entry to `openspec/discovery/unknowns.md` for deferred GPU watchdog

### Phase 5: Validation

- [x] Format code with `nix fmt .`
- [x] Run `nix flake check --no-build` to validate configuration
- [ ] Test on downstream system with AI local inference enabled
- [ ] Monitor for GPU discovery timeout errors after changes
- [ ] Archive this change after validation

## Implementation Details

### GPU Hang Recovery - Enable by Default

**File**: `modules/graphics/default.nix`

Change default to enabled for AMD GPUs and add lockup timeout:

```nix
enableGPURecovery = lib.mkOption {
  type = lib.types.bool;
  default = isAmd;  # Enable by default for AMD GPUs
  description = ''
    Enable automatic GPU hang recovery (AMD GPUs only).
    Adds kernel parameters amdgpu.gpu_recovery=1 and amdgpu.lockup_timeout=5000.
    This allows the kernel to reset the GPU on hang instead of freezing the system.
    Enabled by default for AMD GPUs. Disable only if experiencing issues with GPU resets.
  '';
};

boot.kernelParams =
  lib.optionals (isAmd && config.axios.hardware.enableGPURecovery) [
    "amdgpu.gpu_recovery=1"
    "amdgpu.lockup_timeout=5000"  # Detect GPU hangs within 5 seconds
  ]
```

### Root Cause Summary

| Issue | Root Cause | Fix | Status |
|-------|------------|-----|--------|
| Hard system freeze | GPU hang without recovery | Enable `amdgpu.gpu_recovery=1` + lockup_timeout | **DONE** |
| GPU discovery timeout | ROCm queries too slow under load | Research timeout option | Deferred |
| Queue evictions | VRAM oversubscription | Document, recommend smaller models | Documented |
| Quickshell crashes | Upstream issue, exacerbated by GPU state | Document correlation | Documented |

### axios-ai-mail Correlation Analysis

Investigation of `~/Projects/axios-ai-mail` revealed the likely trigger for consistent hard freezes:

**Finding**: The `ai_classifier.py` uses `keep_alive: 0`, causing model load/unload for every email:
```python
"keep_alive": 0,  # Unload model immediately after request to free VRAM
```

**Impact**: High-frequency GPU memory churn creates:
- Repeated ROCm/HSA runtime state transitions
- GPU memory allocation/deallocation storms
- Increased probability of GPU hang during transitions

**Recommendation** (for axios-ai-mail, not axios):
- Change `keep_alive` from `0` to `300` (5 minutes) to reduce GPU memory churn
- This would allow model to stay loaded across batch processing

**axiOS Fix**: GPU recovery enabled by default mitigates the freeze risk regardless of workload patterns.

## Acceptance Criteria

1. [x] GPU recovery parameters added to graphics module
2. [x] GPU recovery enabled by default for AMD GPUs (no warning needed)
3. [ ] Specs updated with GPU troubleshooting guidance (delta created, pending merge)
4. [ ] No hard system freezes after enabling GPU recovery (user validation)
5. [x] Configuration passes `nix flake check`

## User Action Required (Downstream)

**None** - GPU recovery will be enabled by default for AMD GPUs after this change.

Users who experience issues with GPU resets can disable it:

```nix
{
  axios.hardware.enableGPURecovery = false;
}
```
