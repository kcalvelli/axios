# Multi-Vendor GPU Support for Ollama Server

## Summary

Enable the Ollama server role to support both AMD and Nvidia GPUs by using the existing `hardware.gpu` host configuration, with vendor-specific settings including disabling Flash Attention for AMD ROCm.

## Problem Statement

### Issue 1: AMD-Only Server Role (Architectural Gap)

The current server role hardcodes AMD ROCm:

```nix
package = pkgs.ollama-rocm;  # No Nvidia option!
rocmOverrideGfx = cfg.local.rocmOverrideGfx;
```

**Impact**: Users with Nvidia GPUs cannot run as inference servers - they're forced into client role even with capable hardware.

### Issue 2: Flash Attention Crash on AMD (Immediate Bug)

Ollama 0.14.3 auto-enables Flash Attention on AMD GPUs, but RDNA 2 (gfx1030) doesn't support it:

```
llama_context: Flash Attention was auto, set to enabled
fattn-common.cuh:903: GGML_ASSERT(max_blocks_per_sm > 0) failed
```

**Impact**: Any chat request crashes Ollama on AMD GPUs.

## Existing Infrastructure Discovery

**Key finding**: axios already tracks GPU vendor via `hardware.gpu` in host configurations:

```nix
# Host config (e.g., hosts/edge.nix)
{
  hardware = {
    cpu = "amd";
    gpu = "amd";  # <-- Already defined!
  };
}
```

This flows through the system:
1. `lib/default.nix` validates and passes `hardware.gpu` to modules
2. `axios.hardware.gpuType` option is set from host config
3. Graphics module already uses this: `gpuType = config.axios.hardware.gpuType or null;`

**Solution**: Follow the same pattern in the AI module - no new options needed!

## Proposed Solution

### 1. Read Existing GPU Type (No New Option)

Follow the graphics module pattern:

```nix
# modules/ai/default.nix
let
  cfg = config.services.ai;
  gpuType = config.axios.hardware.gpuType or null;
  isAmdGpu = gpuType == "amd";
  isNvidiaGpu = gpuType == "nvidia";
  isServer = cfg.local.role == "server";
in
```

### 2. Conditional Package Selection

```nix
services.ollama = {
  enable = true;
  package = if isAmdGpu then pkgs.ollama-rocm else pkgs.ollama;
  # ...
};
```

### 3. Vendor-Specific Configuration

**AMD (ROCm)**:
- `OLLAMA_FLASH_ATTENTION = "0"` (disable - causes crashes)
- `rocmOverrideGfx` option applied
- ROCm debugging tools installed
- `amdgpu` kernel module loaded

**Nvidia (CUDA)**:
- Flash Attention enabled (works correctly)
- Standard `ollama` package with CUDA support
- No ROCm-specific options applied

### 4. Conditional Environment Variables

```nix
environmentVariables = {
  OLLAMA_NUM_CTX = "32768";
  OLLAMA_KEEP_ALIVE = cfg.local.keepAlive;
  OLLAMA_MAX_LOADED_MODELS = "1";
} // lib.optionalAttrs isAmdGpu {
  OLLAMA_FLASH_ATTENTION = "0";
};
```

### 5. Conditional Options

The `rocmOverrideGfx` option should only apply for AMD GPUs:

```nix
# Only set rocmOverrideGfx when using AMD
services.ollama = lib.mkMerge [
  { enable = true; ... }
  (lib.mkIf isAmdGpu {
    rocmOverrideGfx = cfg.local.rocmOverrideGfx;
  })
];
```

## Scope

**In Scope**:
- Read existing `axios.hardware.gpuType` in AI module
- Conditional package selection (ollama vs ollama-rocm)
- Vendor-specific environment variables (FA disabled for AMD)
- Vendor-specific kernel modules and packages
- Update spec documentation

**Out of Scope**:
- New configuration options (use existing `hardware.gpu`)
- CPU-only fallback option (separate proposal)
- Hybrid multi-GPU configurations

## Migration

**No migration needed!** The `hardware.gpu` is already defined in host configs:

```nix
# Existing AMD host - no changes needed
{ hardware.gpu = "amd"; }

# Existing Nvidia host - already has this, now server role works
{ hardware.gpu = "nvidia"; }
```

## Success Criteria

1. Nvidia GPU users can run as inference servers (with existing `hardware.gpu = "nvidia"`)
2. AMD GPU users don't experience Flash Attention crashes
3. No new configuration options required
4. Open WebUI → Ollama flow works on both vendors

## References

- Ollama Issue #6953: https://github.com/ollama/ollama/issues/6953 (AMD FA crash)
- Ollama Issue #12432: https://github.com/ollama/ollama/issues/12432 (FA workaround)
- Pattern reference: `modules/graphics/default.nix` (uses same `gpuType` approach)
