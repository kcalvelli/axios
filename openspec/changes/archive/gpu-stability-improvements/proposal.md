# GPU Stability Improvements

## Summary

This proposal addresses GPU-related stability issues discovered through log analysis on 2026-01-22, including a **hard system freeze requiring power cycle** and Ollama GPU discovery timeouts that correlate with AMDGPU queue evictions.

## Problem Statement

System logs reveal multiple stability issues:

### Critical: Hard System Freeze (2026-01-22 ~11:30 AM)

A complete system freeze occurred requiring manual power cycle:
- **Evidence**: Kernel boot log shows `Previous system reset reason [0x00200800]: ACPI power state transition occurred` (abnormal power-off)
- **No pstore data**: Indicates freeze, not kernel panic (panic handlers never triggered)
- **Boot -1 last entry**: 11:19 AM aligns with reported freeze time (~11:30 ±20min)
- **Root cause**: Likely GPU hang that froze the entire system (common with AMD GPUs under memory pressure)

### Secondary: GPU Discovery Timeouts and Queue Evictions

System logs also reveal a cascade pattern:

1. **Ollama GPU discovery times out** - Multiple "failure during GPU discovery" and "failed to finish discovery before timeout" errors
2. **AMDGPU queue evictions occur** - Kernel warnings: "Freeing queue vital buffer... queue evicted"
3. **Ollama falls back to stale memory values** - "unable to refresh free memory, using old values"
4. **Desktop components may become unstable** - Quickshell/DMS crashes correlate with GPU memory pressure periods

## Root Cause Analysis

### Evidence from 2026-01-22 logs

```
15:27:39 - amdgpu: Freeing queue vital buffer 0x7f40c8c00000, queue evicted (x5)
15:27:39 - ollama: failure during GPU discovery... error="failed to finish discovery before timeout"
15:27:39 - ollama: unable to refresh free memory, using old values
15:27:42 - ollama: failure during GPU discovery (repeated)
15:27:44 - ollama: failure during GPU discovery (repeated)
```

### Root Cause

The GPU discovery timeout in Ollama occurs when:
1. ROCm's `amd_smi` or HSA runtime queries take too long under load
2. Multiple GPU-using applications compete for resources (compositor, quickshell, ollama)
3. The default timeout is insufficient for AMD GPUs under memory pressure

When discovery times out, Ollama uses cached memory values which may be stale, leading to:
- Incorrect scheduling decisions (loading models that don't fit)
- Queue oversubscription
- Kernel-level queue evictions

### Correlation with Quickshell Crashes

The DMS/Quickshell SIGSEGV crashes at greeter startup may be exacerbated by:
- GPU memory fragmentation from previous ollama sessions
- Stale ROCm state after queue evictions
- Competition for GPU resources during session initialization

### Hard Freeze Root Cause

The hard freeze is likely caused by:
1. **GPU hang during heavy compute** - ROCm/AMDGPU can hang when queues are oversubscribed
2. **No GPU reset capability** - System lacks enabled GPU hang recovery
3. **Kernel lockup from GPU** - When GPU hangs, the compositor hangs, then the entire system

## Proposed Solutions

### Solution 1: Enable AMD GPU Hang Recovery (Critical)

Enable kernel-level GPU reset capabilities:
- Add `amdgpu.gpu_recovery=1` kernel parameter (enables GPU reset on hang)
- Add `amdgpu.lockup_timeout=5000` to detect hangs within 5 seconds
- Configure crash diagnostics module to capture GPU state

This allows the kernel to reset the GPU instead of freezing the entire system.

### Solution 2: Extend GPU Discovery Timeout (Primary)

Add `OLLAMA_GPU_DISCOVERY_TIMEOUT` environment variable if supported, or implement a wrapper that pre-warms the ROCm runtime before ollama starts.

### Solution 3: GPU Memory Headroom (Primary)

Reserve GPU memory headroom to prevent oversubscription:
- Add `services.ai.local.gpuMemoryReserve` option (default: 512MB)
- Configure Ollama to leave headroom for desktop GPU usage

### Solution 4: Pre-session GPU State Reset (Experimental)

Add optional greeter hook to reset ROCm state before user login:
- Clear stale GPU allocations
- Ensure clean state for quickshell initialization

### Solution 5: GPU Memory Watchdog (Deferred)

Implement monitoring that:
- Tracks VRAM usage via `amd_smi` or `/sys/class/drm`
- Warns when approaching limits
- Can trigger ollama model unloading preemptively

## Scope

This proposal focuses on:
1. **AMD GPU hang recovery** - Critical fix to prevent hard freezes
2. **GPU discovery timeout mitigation** - Primary stability improvement
3. **GPU memory headroom** - Prevent oversubscription
4. **Documentation** - Update specs with GPU troubleshooting guidance

Out of scope:
- DMS/Quickshell crash fix (upstream dependency)
- Full GPU memory watchdog (complex, separate proposal)
- ROCm runtime patching

## Success Criteria

1. No "failed to finish discovery before timeout" errors during normal operation
2. Reduced frequency of AMDGPU queue evictions
3. Stable desktop session startup after ollama usage

## References

- Journal analysis: 2026-01-22 crash investigation
- Previous work: `openspec/changes/archive/improve-system-stability/`
- Previous work: `openspec/changes/archive/ollama-memory-management/`
- Upstream: Ollama GPU scheduling code
