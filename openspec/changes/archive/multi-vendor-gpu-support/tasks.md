# Tasks: Multi-Vendor GPU Support for Ollama Server

## Implementation Tasks

- [x] **1. Add GPU type detection to AI module**
  - File: `modules/ai/default.nix`
  - Add to `let` block (follow graphics module pattern):
    ```nix
    gpuType = config.axios.hardware.gpuType or null;
    isAmdGpu = gpuType == "amd";
    isNvidiaGpu = gpuType == "nvidia";
    ```
  - No new options needed - uses existing `hardware.gpu` from host config

- [x] **2. Conditional package selection**
  - File: `modules/ai/default.nix`
  - Change `package = pkgs.ollama-rocm;` to:
    ```nix
    package = if isAmdGpu then pkgs.ollama-rocm else pkgs.ollama;
    ```

- [x] **3. Conditional rocmOverrideGfx**
  - File: `modules/ai/default.nix`
  - Only set `rocmOverrideGfx` when `isAmdGpu`
  - Use `lib.mkIf isAmdGpu` to conditionally include

- [x] **4. Vendor-specific environment variables**
  - File: `modules/ai/default.nix`
  - Add `OLLAMA_FLASH_ATTENTION = "0"` only for AMD:
    ```nix
    environmentVariables = { ... } // lib.optionalAttrs isAmdGpu {
      OLLAMA_FLASH_ATTENTION = "0";
    };
    ```

- [x] **5. Conditional system packages**
  - File: `modules/ai/default.nix`
  - ROCm tools (`rocmPackages.rocminfo`) only for AMD:
    ```nix
    ++ lib.optionals isAmdGpu [ rocmPackages.rocminfo ]
    ```

- [x] **6. Conditional kernel modules**
  - File: `modules/ai/default.nix`
  - `boot.kernelModules = [ "amdgpu" ]` only when `isAmdGpu`

## Documentation Tasks

- [x] **7. Update AI spec with multi-vendor support**
  - File: `openspec/specs/ai/spec.md`
  - Document that GPU vendor is read from `hardware.gpu`
  - Update "Local Inference Stack" section for both vendors
  - Add vendor-specific behavior table

- [x] **8. Add Flash Attention constraint (AMD-specific)**
  - File: `openspec/specs/ai/spec.md`
  - Document FA disabled for AMD in Constraints section
  - Add GPU Troubleshooting subsection for FA crash

## Validation Tasks

- [x] **9. Format code**
  - Run `nix fmt .`

- [x] **10. Validate flake**
  - Run `nix flake check`
  - Verify module evaluates correctly

- [ ] **11. Test AMD configuration**
  - Rebuild with existing `hardware.gpu = "amd"`
  - Verify Ollama uses `ollama-rocm` package
  - Verify FA is disabled in environment
  - Test Open WebUI chat works without crash

- [ ] **12. Test Nvidia configuration** (if hardware available)
  - Host with `hardware.gpu = "nvidia"`
  - Verify Ollama uses standard `ollama` package
  - Verify FA is NOT disabled
  - Verify no ROCm-specific options applied

## Finalization

- [ ] **13. Archive change**
  - Merge spec delta into `openspec/specs/ai/spec.md`
  - Move change to `openspec/changes/archive/`
