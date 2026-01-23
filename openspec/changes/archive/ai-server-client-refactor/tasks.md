# Tasks: AI Module Server/Client Refactor

## Overview

Refactor `modules/ai/default.nix` to support server/client roles, enabling lightweight laptop configurations that use remote Ollama instances.

---

## Phase 1: Module Options Refactor ✅

### Task 1.1: Add Role Option
- [x] Add `services.ai.local.role` option with enum `[ "server" "client" ]`
- [x] Default to `"server"` for backward compatibility
- [x] Add documentation describing each role

```nix
role = lib.mkOption {
  type = lib.types.enum [ "server" "client" ];
  default = "server";
  description = ''
    Local LLM deployment role:
    - "server": Run Ollama locally with GPU acceleration
    - "client": Use remote Ollama server (no local GPU required)
  '';
};
```

### Task 1.2: Add Client Configuration Options
- [x] Add `services.ai.local.serverHost` option (string, required for client)
- [x] Add `services.ai.local.tailnetDomain` option (string, required for client)
- [x] Add `services.ai.local.serverPort` option (port, default 8447)

```nix
serverHost = lib.mkOption {
  type = lib.types.nullOr lib.types.str;
  default = null;
  example = "edge";
  description = "Hostname of Ollama server on tailnet (client role only)";
};

tailnetDomain = lib.mkOption {
  type = lib.types.nullOr lib.types.str;
  default = null;
  example = "taile0fb4.ts.net";
  description = "Tailscale tailnet domain";
};
```

### Task 1.3: Add Server Tailscale Serve Options
- [x] Add `services.ai.local.tailscaleServe.enable` option
- [x] Add `services.ai.local.tailscaleServe.httpsPort` option (default 8447)
- [x] Remove or deprecate existing `ollamaReverseProxy` options (Caddy-based) - deprecated with warning

```nix
tailscaleServe = {
  enable = lib.mkEnableOption "Expose Ollama API via Tailscale HTTPS";
  httpsPort = lib.mkOption {
    type = lib.types.port;
    default = 8447;
    description = "HTTPS port for Ollama API on Tailscale";
  };
};
```

---

## Phase 2: Server Role Implementation ✅

### Task 2.1: Refactor Existing Server Config
- [x] Wrap existing Ollama config in `lib.mkIf (cfg.local.role == "server")`
- [x] Keep all existing server functionality unchanged
- [x] Ensure ROCm, amdgpu, rocminfo only installed for server role

```nix
# Server role: Local Ollama with GPU
(lib.mkIf (cfg.enable && cfg.local.enable && cfg.local.role == "server") {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    # ... existing config
  };

  boot.kernelModules = [ "amdgpu" ];

  environment.systemPackages = with pkgs; [
    rocmPackages.rocminfo
    python3
    uv
  ] ++ lib.optional cfg.local.cli pkgs.opencode;
})
```

### Task 2.2: Implement Tailscale Serve for Server
- [x] Add Tailscale serve configuration when `tailscaleServe.enable = true`
- [x] Configure serve to forward `:{httpsPort}` → `localhost:11434`
- [x] Research: Determine if we use `services.tailscale.serve` or manual config - used systemd oneshot service

```nix
# Tailscale serve for Ollama API
(lib.mkIf (cfg.local.role == "server" && cfg.local.tailscaleServe.enable) {
  # Option A: If services.tailscale.serve exists
  services.tailscale.serve = {
    "/${toString cfg.local.tailscaleServe.httpsPort}" = "http://127.0.0.1:11434";
  };

  # Option B: Manual serve config file
  # Research needed
})
```

### Task 2.3: Deprecate Caddy Reverse Proxy
- [x] Mark `ollamaReverseProxy` options as deprecated
- [x] Add warning when `ollamaReverseProxy.enable = true`
- [x] Plan removal in future release

---

## Phase 3: Client Role Implementation ✅

### Task 3.1: Implement Client Config Block ✅
- [x] Create config block for `role == "client"`
- [x] Ensure NO Ollama service installed
- [x] Ensure NO ROCm packages installed
- [x] Ensure NO amdgpu kernel module loaded

```nix
# Client role: Remote Ollama
(lib.mkIf (cfg.enable && cfg.local.enable && cfg.local.role == "client") {
  # Set OLLAMA_HOST environment variable
  environment.sessionVariables = {
    OLLAMA_HOST = "https://${cfg.local.serverHost}.${cfg.local.tailnetDomain}:${toString cfg.local.tailscaleServe.httpsPort}";
  };

  # Install client tools only (no GPU stack)
  environment.systemPackages = with pkgs; [
    python3
    uv
  ] ++ lib.optional cfg.local.cli pkgs.opencode;
})
```

### Task 3.2: Verify Client Tools Work with Remote
- [x] Test OpenCode with `OLLAMA_HOST` pointing to remote
- [x] Test ollama CLI with remote server
- [x] Test mcp-cli on client

---

## Phase 4: Assertions and Validation ✅

### Task 4.1: Add Client Role Assertions
- [x] Assert `serverHost != null` when `role == "client"`
- [x] Assert `tailnetDomain != null` when `role == "client"`

```nix
assertions = [
  {
    assertion = cfg.local.role != "client" || cfg.local.serverHost != null;
    message = ''
      services.ai.local.role = "client" requires serverHost to be set.

      Example:
        services.ai.local.serverHost = "edge";
    '';
  }
  {
    assertion = cfg.local.role != "client" || cfg.local.tailnetDomain != null;
    message = ''
      services.ai.local.role = "client" requires tailnetDomain to be set.

      Example:
        services.ai.local.tailnetDomain = "taile0fb4.ts.net";
    '';
  }
];
```

### Task 4.2: Add Server Role Assertions
- [x] Assert Tailscale serve only for server role
- [ ] Warn if no GPU detected but server role selected (optional - deferred)

---

## Phase 5: Documentation ✅

### Task 5.1: Update Module Documentation
- [x] Update `docs/MODULE_REFERENCE.md` with new options
- [x] Add server/client configuration examples
- [x] Document migration path (none needed, backward compatible)

### Task 5.2: Update AI Spec
- [x] Update `openspec/specs/ai/spec.md` with server/client roles
- [ ] Add architecture diagram showing server/client topology (deferred)

---

## Phase 6: Testing ✅

### Task 6.1: Server Role Tests
- [x] Test: Server role starts Ollama with ROCm (flake check passes)
- [x] Test: Server role includes amdgpu module (code inspection)
- [x] Test: Server role installs rocminfo (code inspection)
- [x] Test: Tailscale serve exposes API (curl test from pangolin)

### Task 6.2: Client Role Tests
- [x] Test: Client role does NOT install Ollama service (code inspection)
- [x] Test: Client role does NOT install ROCm packages (code inspection)
- [x] Test: Client role sets OLLAMA_HOST correctly (code inspection)
- [x] Test: ollama CLI connects to remote Ollama
- [x] Test: mcp-cli works on client

### Task 6.3: Assertion Tests
- [x] Test: Client without serverHost fails with clear message (verified during development)
- [x] Test: Client without tailnetDomain fails with clear message (verified during development)

### Task 6.4: Backward Compatibility Tests
- [x] Test: Existing `services.ai.local.enable = true` works unchanged (flake check passes)
- [x] Test: All existing options still function (code inspection)

---

## Phase 7: Finalization ✅

### Task 7.1: Code Review Checklist
- [x] All new options documented
- [x] Assertions cover edge cases
- [x] No hardcoded values (use options)
- [x] Follows axios module patterns

### Task 7.2: Merge Specs
- [x] Specs updated in `openspec/specs/ai/spec.md` (done during implementation)
- [x] Archive this change directory

---

## Files to Modify

| File | Changes |
|------|---------|
| `modules/ai/default.nix` | Add role, client options, refactor config blocks |
| `openspec/specs/ai/spec.md` | Document server/client architecture |
| `docs/MODULE_REFERENCE.md` | Update AI module documentation |

## Files to Create

| File | Purpose |
|------|---------|
| None | This is a refactor of existing module |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Options | 1 hour |
| Phase 2: Server | 2 hours |
| Phase 3: Client | 1 hour |
| Phase 4: Assertions | 30 min |
| Phase 5: Documentation | 1 hour |
| Phase 6: Testing | 2 hours |
| Phase 7: Finalization | 30 min |
| **Total** | **~8 hours** |

---

## Open Questions

1. **Tailscale serve mechanism**: Does NixOS have a `services.tailscale.serve` option, or do we need manual configuration?

2. **GPU detection**: Should we warn users if they select server role without a compatible GPU?

3. **Multiple servers**: Should we support connecting to multiple Ollama servers (load balancing)? *Defer to future*
