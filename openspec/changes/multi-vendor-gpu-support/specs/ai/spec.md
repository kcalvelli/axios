## MODIFIED Requirements

### Requirement: Multi-Vendor GPU Support for Local Inference

axiOS MUST support both AMD and Nvidia GPUs for local LLM inference in the server role, using the existing `hardware.gpu` host configuration.

#### GPU Vendor Detection

The AI module reads the GPU vendor from the existing host configuration:

```nix
# Host config already defines this:
{ hardware.gpu = "amd"; }  # or "nvidia"

# AI module reads via:
gpuType = config.axios.hardware.gpuType or null;
```

**No new options required** - follows the same pattern as `modules/graphics/default.nix`.

#### Vendor-Specific Behavior

| Aspect | AMD | Nvidia |
|--------|-----|--------|
| Package | `ollama-rocm` | `ollama` |
| Flash Attention | Disabled (`OLLAMA_FLASH_ATTENTION=0`) | Enabled (default) |
| Architecture Override | `rocmOverrideGfx` option | N/A |
| Kernel Modules | `amdgpu` | (handled by nixos-hardware) |
| Debug Tools | `rocmPackages.rocminfo` | N/A |

#### Scenario: AMD user runs local inference

- **Given**: User has AMD GPU (e.g., RX 6750 XT)
- **And**: Host config has `hardware.gpu = "amd"`
- **When**: User enables `services.ai.local.enable = true` with `role = "server"`
- **Then**: Ollama uses `ollama-rocm` package
- **And**: Flash Attention is disabled to prevent crashes
- **And**: `rocmOverrideGfx` is applied if configured

#### Scenario: Nvidia user runs local inference

- **Given**: User has Nvidia GPU (e.g., RTX 3080)
- **And**: Host config has `hardware.gpu = "nvidia"`
- **When**: User enables `services.ai.local.enable = true` with `role = "server"`
- **Then**: Ollama uses standard `ollama` package with CUDA support
- **And**: Flash Attention remains enabled (works correctly on Nvidia)
- **And**: No ROCm-specific configuration is applied

#### Scenario: Chat request on AMD with Flash Attention disabled

- **Given**: User has AMD gfx1030 GPU
- **And**: Ollama configured with `OLLAMA_FLASH_ATTENTION=0` (automatic for AMD)
- **When**: User sends a chat request via Open WebUI or API
- **Then**: Ollama uses standard attention mechanism
- **And**: Request completes successfully without assertion failures

### Configuration Examples

**AMD Server** (existing config works unchanged):
```nix
# Host config
{
  hardware.gpu = "amd";
}

# Module config
{
  services.ai = {
    enable = true;
    local = {
      enable = true;
      role = "server";
      rocmOverrideGfx = "10.3.0";  # For RX 6000 series
    };
  };
}
```

**Nvidia Server** (now works with existing hardware.gpu):
```nix
# Host config
{
  hardware.gpu = "nvidia";
}

# Module config
{
  services.ai = {
    enable = true;
    local = {
      enable = true;
      role = "server";
      # rocmOverrideGfx not applicable for Nvidia
    };
  };
}
```

### Constraint Addition: Flash Attention (AMD)

Add to Constraints section:
- **Flash Attention (AMD)**: Flash Attention is disabled for AMD ROCm GPUs (`OLLAMA_FLASH_ATTENTION=0`) due to assertion failures on RDNA 2 (gfx1030) architecture. Nvidia GPUs are unaffected. The GPU vendor is determined by the existing `hardware.gpu` host configuration.

### GPU Troubleshooting Addition

Add new troubleshooting subsection:

**Symptoms**: "GGML_ASSERT(max_blocks_per_sm > 0) failed" / Ollama crash on chat

**Cause**: Flash Attention auto-enabled on AMD GPU that doesn't support it.

**Applies to**: AMD ROCm only (Nvidia unaffected)

**Error Pattern**:
```
llama_context: Flash Attention was auto, set to enabled
fattn-common.cuh:903: GGML_ASSERT(max_blocks_per_sm > 0) failed
SIGABRT: abort
```

**Fix**: axiOS automatically disables Flash Attention when `hardware.gpu = "amd"`. If you see this error, verify your host config has the correct GPU vendor set.

**Note**: Flash Attention primarily benefits larger models (30B+) with very long contexts. For 7B-14B models typical in axiOS, the performance difference is negligible.
