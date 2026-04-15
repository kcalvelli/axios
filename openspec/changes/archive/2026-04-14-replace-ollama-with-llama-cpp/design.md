## Approach

Replace Ollama with a custom systemd service running `llama-server` from the `llama-cpp` nixpkgs package. The server speaks OpenAI-compatible `/v1/chat/completions` natively — all downstream consumers (axios-ai-mail, OpenCode) work without modification.

## Module Changes (`modules/ai/default.nix`)

### Options Removed

| Option | Reason |
|--------|--------|
| `services.ai.local.models` | Ollama model-pull system; replaced by single GGUF path |
| `services.ai.local.keepAlive` | Ollama-specific memory management; llama-server doesn't have this problem |
| `services.ai.local.rocmOverrideGfx` | Moved to env var on the systemd unit directly |

### Options Added/Changed

| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `services.ai.local.model` | `path` | required | Absolute path to GGUF model file |
| `services.ai.local.contextSize` | `int` | `32768` | Context window size (was hardcoded `OLLAMA_NUM_CTX`) |
| `services.ai.local.port` | `port` | `11434` | Listen port (keep same port for compatibility) |
| `services.ai.local.gpuLayers` | `int` | `-1` | GPU layers to offload (-1 = all, 0 = CPU only) |
| `services.ai.local.extraArgs` | `listOf str` | `[]` | Additional llama-server CLI flags |

### Server Role Implementation

Replace `services.ollama` with a custom systemd service:

```nix
systemd.services.llama-server = {
  description = "llama.cpp inference server";
  wantedBy = [ "multi-user.target" ];
  after = [ "network.target" ];

  environment = {
    # AMD ROCm architecture override (equivalent to old rocmOverrideGfx)
    HSA_OVERRIDE_GFX_VERSION = lib.mkIf isAmdGpu cfg.local.rocmGfxVersion;
  };

  serviceConfig = {
    ExecStart = "${llamaPkg}/bin/llama-server ${lib.escapeShellArgs serverArgs}";
    Restart = "on-failure";
    RestartSec = 5;
    DynamicUser = true;
    StateDirectory = "llama-server";
  };
};
```

Where `serverArgs` is built from:
```
--model <cfg.local.model>
--ctx-size <cfg.local.contextSize>
--port <cfg.local.port>
--host 0.0.0.0
--n-gpu-layers <cfg.local.gpuLayers>
<cfg.local.extraArgs>
```

### GPU Package Selection

Same pattern as Ollama, nixpkgs already has both:

```nix
llamaPkg = if isAmdGpu then pkgs.llama-cpp-rocm else pkgs.llama-cpp;
```

Nvidia gets CUDA via the standard `llama-cpp` package (CUDA support is built-in when nixpkgs detects CUDA toolkit). AMD gets `llama-cpp-rocm` with HIP/ROCm backend.

### Client Role

Replace `OLLAMA_HOST` with an env var pointing at the Tailscale Service:

```nix
environment.sessionVariables = {
  LLAMA_API_URL = "https://axios-llama.${cfg.local.tailnetDomain}";
};
```

Client no longer installs `pkgs.ollama` — there's no CLI needed. Consumers hit the OpenAI-compatible API directly.

### Tailscale Services

```nix
networking.tailscale.services."axios-llama" = {
  enable = true;
  backend = "http://127.0.0.1:${toString cfg.local.port}";
};
```

### Model Management

No automatic model pulling. Users download GGUF files using the existing `download-llama-models.sh` script (already in the repo) and point `services.ai.local.model` at the file. This is simpler and more predictable than Ollama's pull system.

### AMD-Specific Handling

- `HSA_OVERRIDE_GFX_VERSION` set as env var on the systemd unit (replaces `ollama.rocmOverrideGfx`)
- `amdgpu` kernel module still loaded
- `rocmPackages.rocminfo` still available for debugging
- Flash attention: llama-cpp handles this differently than Ollama — no blanket disable needed. The `--flash-attn` flag is opt-in (off by default), so the AMD crash issue doesn't apply.

## What Doesn't Change

- `services.ai.enable` and all CLI tool packages (claude-code, gemini, codex, etc.)
- `services.ai.mcp.*` configuration
- `services.ai.systemPrompt.*`
- `services.ai.local.cli` (OpenCode) — still installed on server role
- Server/client role architecture concept
- Tailscale Services pattern (just a name change)
- `python3` and `uv` in shared local LLM packages

## Migration Path

Downstream host configs need:
1. Remove `services.ai.local.models` → add `services.ai.local.model = "/path/to/model.gguf"`
2. Remove `services.ai.local.keepAlive` (no equivalent needed)
3. Remove `services.ai.local.rocmOverrideGfx` (handled automatically or via `extraArgs`)
4. Run `nix run .#download-llama-models` to get GGUF files if not already present
5. Update any hardcoded references to `axios-ollama` → `axios-llama`
