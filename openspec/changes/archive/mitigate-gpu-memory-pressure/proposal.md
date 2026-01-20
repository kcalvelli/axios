# Mitigate GPU Memory Pressure

## Summary

Address frequent AMDGPU queue evictions caused by ROCm compute workloads (primarily Ollama inference) competing for GPU resources on the RX 6750 XT (12GB VRAM).

## Problem Statement

System logs show consistent GPU memory pressure:

- **Frequency**: Queue evictions every 10-30 minutes during active use
- **Pattern**: ~5 queue buffers evicted per event
- **Warnings**: "Runlist is getting oversubscribed due to too many queues" (2x today)
- **Risk**: Can lead to system freezes when pressure becomes critical

### Evidence (Last 24 Hours)

```
2026-01-20T11:28:14 amdgpu: Runlist is getting oversubscribed due to too many queues
2026-01-20T11:01:04 amdgpu: Runlist is getting oversubscribed due to too many queues
+ 50+ queue eviction events
```

### Current VRAM State

```
VRAM: 1.6 GB / 12.0 GB (13%) - at rest
```

### Model Sizes vs VRAM

| Model | Size | Fits in 12GB? |
|-------|------|---------------|
| qwen3-coder:30b | 18 GB | No (requires offload) |
| qwen3:14b | 9.3 GB | Yes (leaves 2.7 GB) |
| deepseek-coder-v2:16b | 8.9 GB | Yes (leaves 3.1 GB) |
| mistral-nemo | 7.1 GB | Yes (leaves 4.9 GB) |

## Root Cause Analysis

The evictions are caused by **ROCm queue accumulation**, not raw VRAM exhaustion:

1. **Queue Accumulation**: Each Ollama inference request creates ROCm compute queues
2. **Context Windows**: 32K token contexts require significant queue resources
3. **Model Offload**: 30B model requires partial CPU offload, stressing the queue system
4. **Concurrent Use**: Browser GPU acceleration + Ollama = resource contention

The `OLLAMA_KEEP_ALIVE=5m` fix helps by unloading idle models, but doesn't address:
- Queue accumulation during active inference
- Oversized models requiring offload
- Concurrent GPU consumers

## Proposed Solutions

### Solution 1: Reduce Default keepAlive (Quick Win)

Change default from `5m` to `1m` or `30s`:
- Models unload faster after inference
- Reduces window for queue accumulation
- Trade-off: Slower cold-start for rapid re-inference

### Solution 2: Add GPU Memory Monitoring Service

Create a lightweight systemd service that:
- Monitors `/sys/class/drm/card*/device/mem_info_vram_used`
- Warns at 80% VRAM usage
- Optionally triggers `ollama stop` at 90%

### Solution 3: Limit Concurrent Ollama Requests

Set `OLLAMA_MAX_LOADED_MODELS=1` to prevent multiple models loading simultaneously.

### Solution 4: Documentation - Model Size Guidance

Document recommended model sizes for 12GB VRAM systems:
- Recommend ≤14B models for full GPU inference
- Warn about 30B+ models causing offload/evictions

## Recommended Approach

**Phase 1 (Immediate)**:
1. Reduce `keepAlive` default to `"1m"`
2. Add `OLLAMA_MAX_LOADED_MODELS=1`
3. Document model size guidance in AI spec

**Phase 2 (Future)**:
4. GPU memory monitoring service (optional)
5. Automatic model unloading at threshold (optional)

## Scope

**In Scope**:
- Adjust Ollama memory management defaults
- Add max loaded models limit
- Document VRAM constraints

**Out of Scope**:
- GPU hardware monitoring daemon (complex, needs dedicated proposal)
- Automatic model selection based on VRAM (AI assistant responsibility)

## References

- Journal logs: Queue eviction patterns over 24 hours
- Current AI spec: `openspec/specs/ai/spec.md`
- Ollama environment variables: https://github.com/ollama/ollama/blob/main/docs/faq.md
