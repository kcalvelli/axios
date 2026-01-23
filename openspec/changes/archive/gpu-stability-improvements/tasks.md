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

- [x] Update `openspec/specs/ai/spec.md` with GPU troubleshooting section
- [x] Update `openspec/specs/desktop/spec.md` with GPU correlation notes
- [x] Update `openspec/specs/graphics/spec.md` with recovery recommendation for AI workloads
- [x] Specs merged from delta to main

### Phase 5: Hardware Watchdog Timer (Critical - Added 2026-01-23)

- [x] Update `modules/hardware/crash-diagnostics.nix` to add hardware watchdog options
- [x] Add `enableHardwareWatchdog` option (default: true when crashDiagnostics enabled)
- [x] Configure `systemd.extraConfig` with RuntimeWatchdogSec, RebootWatchdogSec, KExecWatchdogSec
- [x] Update spec documentation for crash diagnostics (ops/spec.md in delta)
- [ ] Test hardware watchdog activation (verify `/dev/watchdog` is being petted)

### Phase 6: Validation

- [x] Format code with `nix fmt .`
- [x] Run `nix flake check --no-build` to validate configuration
- [ ] Test on downstream system with AI local inference enabled
- [ ] Monitor for GPU discovery timeout errors after changes
- [ ] Verify hardware watchdog is active after rebuild
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

### Hardware Watchdog Timer - systemd Integration

**File**: `modules/hardware/crash-diagnostics.nix`

Add hardware watchdog support that operates independently of CPU state:

```nix
enableHardwareWatchdog = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = ''
    Enable hardware watchdog timer via systemd.

    This provides last-resort recovery from hard system freezes that bypass
    all software-based detection (NMI watchdog, softlockup, GPU recovery).

    The hardware watchdog (e.g., sp5100-tco on AMD) operates independently
    of the CPU and will force a reboot if systemd stops responding.
  '';
};

# In config:
systemd.extraConfig = lib.mkIf cfg.enableHardwareWatchdog ''
  RuntimeWatchdogSec=30
  RebootWatchdogSec=60
  KExecWatchdogSec=60
'';
```

### Root Cause Summary

| Issue | Root Cause | Fix | Status |
|-------|------------|-----|--------|
| Hard system freeze (soft) | GPU hang without recovery | Enable `amdgpu.gpu_recovery=1` + lockup_timeout | **DONE** |
| Hard system freeze (PCIe lockup) | GPU hang locks bus, bypasses CPU | Enable hardware watchdog timer | **TODO** |
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
3. [x] Specs updated with GPU troubleshooting guidance (delta specs updated)
4. [ ] No hard system freezes after enabling GPU recovery (user validation)
5. [x] Configuration passes `nix flake check`
6. [x] Hardware watchdog enabled in crash-diagnostics module
7. [ ] Hardware watchdog verified active after rebuild (`systemctl show | grep Watchdog`)

## User Action Required (Downstream)

**None** - GPU recovery will be enabled by default for AMD GPUs after this change.

Users who experience issues with GPU resets can disable it:

```nix
{
  axios.hardware.enableGPURecovery = false;
}
```
