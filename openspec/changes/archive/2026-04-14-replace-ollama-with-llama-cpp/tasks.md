## Tasks

### 1. Rewrite `modules/ai/default.nix` — options block

Replace Ollama-specific options with llama-cpp options under `services.ai.local`:

- [x] Remove `models` option (list of Ollama model names)
- [x] Remove `keepAlive` option
- [x] Remove `rocmOverrideGfx` option
- [x] Add `model` option (`types.path`, required when local.enable && server role)
- [x] Add `contextSize` option (`types.int`, default 32768)
- [x] Add `port` option (`types.port`, default 11434)
- [x] Add `gpuLayers` option (`types.int`, default -1)
- [x] Add `extraArgs` option (`types.listOf types.str`, default [])
- [x] Update `role` option description to reference llama-server instead of Ollama
- [x] Update `enable` description from "Ollama, OpenCode" to "llama.cpp, OpenCode"

### 2. Rewrite `modules/ai/default.nix` — server role config block

Replace `services.ollama` with custom systemd service:

- [x] Remove entire `services.ollama` block (lines ~276-302)
- [x] Add `systemd.services.llama-server` with:
  - `ExecStart` using `llamaPkg/bin/llama-server` with args built from options
  - `DynamicUser = true`
  - `Restart = "on-failure"`
  - `HSA_OVERRIDE_GFX_VERSION` env var for AMD
- [x] Define `llamaPkg = if isAmdGpu then pkgs.llama-cpp-rocm else pkgs.llama-cpp`
- [x] Keep `boot.kernelModules` for AMD
- [x] Keep `rocmPackages.rocminfo` in server packages
- [x] Update Tailscale Services from `cairn-ollama` to `cairn-llama`
- [x] Update `networking.hosts` from `cairn-ollama.local` to `cairn-llama.local`
- [x] Add assertion: server role requires `cfg.local.model` to be set (handled by types.path — no default means Nix errors at eval)

### 3. Rewrite `modules/ai/default.nix` — client role config block

- [x] Replace `OLLAMA_HOST` with `LLAMA_API_URL` pointing at `https://cairn-llama.${cfg.local.tailnetDomain}`
- [x] Remove `pkgs.ollama` from client packages (no CLI needed)
- [x] Keep OpenCode in client packages

### 4. Update `scripts/download-llama-models.sh`

- [x] Update script description/comments to remove Ollama references (already clean — no Ollama refs)
- [x] Update the `services.ai.local.llamaServer.model` hint to `services.ai.local.model`
- [x] Verify model download paths and GGUF URLs are still current (HuggingFace URLs verified)

### 5. Update specs

- [x] Sync delta `specs/ai/spec.md` into `openspec/specs/ai/spec.md` — replace Ollama sections with llama-cpp equivalents
- [x] Sync delta `specs/networking/spec.md` into `openspec/specs/networking/ports.md` — update port table and service name
- [x] Update `openspec/specs/pim/spec.md` — remove any remaining Ollama references
- [x] Update `openspec/specs/services/spec.md` — update reverse proxy reference from Ollama to llama-server
- [x] Update `openspec/specs/desktop/spec.md` — update GPU stability references

### 6. Update docs

- [x] Update `docs/MODULE_REFERENCE.md` — rewrite Ollama configuration section for llama-cpp
- [x] Update `docs/APPLICATIONS.md` — update local LLM backend description
- [x] Update `docs/TAILSCALE_SERVICES.md` — update service name and DNS
- [x] Update `docs/LIBRARY_USAGE.md` — update optional local LLM stack description
- [x] Update `README.md` — updated local LLM reference
- [x] Update `CHANGELOG.md` with migration notes

### 7. Update `openspec/glossary.md`

- [x] Update or replace Ollama glossary entry with llama-cpp

### 8. Run formatter and validate

- [x] Run `nix fmt .` on changed Nix files
- [x] Run `nix flake check` to validate module structure
- [x] Update `scripts/init-config.sh` — installer references
- [x] Update `scripts/templates/ai-install-prompt.md.template`
- [x] Fix straggler Ollama reference in `modules/pim/default.nix` assertion
