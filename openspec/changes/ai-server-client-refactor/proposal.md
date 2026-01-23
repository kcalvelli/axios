# Proposal: AI Module Server/Client Refactor

## Summary

Refactor the AI module to support server/client roles, enabling lightweight laptop configurations that use remote Ollama instances while maintaining full AI development capabilities.

## Motivation

### Problem Statement

The current AI module bundles local LLM infrastructure (Ollama + ROCm) with cloud AI tools (Claude Code, Gemini CLI). This creates an all-or-nothing situation:

- **Desktop**: Wants full local LLM stack with GPU acceleration
- **Laptop**: Wants Claude/Gemini tools but should use desktop's Ollama remotely

Currently, a laptop user must either:
1. Install the full GPU stack (wasteful, may not have compatible GPU)
2. Disable `services.ai.local` entirely (loses OpenCode, future Open WebUI access)

### Solution

Introduce `role = "server" | "client"` pattern (matching axios-ai-mail) to the AI local module:

- **Server role**: Run Ollama locally, expose via Tailscale
- **Client role**: Configure `OLLAMA_HOST` to point to remote server, no local Ollama

## Proposed Changes

### New Options

```nix
services.ai.local = {
  enable = lib.mkEnableOption "local LLM capabilities";

  role = lib.mkOption {
    type = lib.types.enum [ "server" "client" ];
    default = "server";
    description = ''
      Local LLM deployment role:
      - "server": Run Ollama locally with GPU acceleration
      - "client": Use remote Ollama server (no local GPU required)
    '';
  };

  # Client-only options
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

  # Server-only options (existing, reorganized)
  tailscaleServe = {
    enable = lib.mkEnableOption "Expose Ollama API via Tailscale HTTPS";
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8447;
      description = "HTTPS port for Ollama API on Tailscale";
    };
  };

  # Existing options remain unchanged
  models = lib.mkOption { ... };
  rocmOverrideGfx = lib.mkOption { ... };
  keepAlive = lib.mkOption { ... };
  cli = lib.mkEnableOption "OpenCode agentic CLI";
};
```

### Server Role Behavior

When `role = "server"` (default):

```nix
# Current behavior, unchanged
services.ollama = {
  enable = true;
  package = pkgs.ollama-rocm;
  # ... existing config
};

boot.kernelModules = [ "amdgpu" ];

environment.systemPackages = [
  rocmPackages.rocminfo
  python3
  uv
] ++ lib.optional cfg.local.cli pkgs.opencode;

# NEW: Tailscale serve for Ollama API
# When tailscaleServe.enable = true
# Exposes https://{hostname}.{tailnet}:{port} → localhost:11434
```

### Client Role Behavior

When `role = "client"`:

```nix
# NO Ollama service
# NO ROCm packages
# NO amdgpu kernel module

# Set environment variable for all tools
environment.sessionVariables = {
  OLLAMA_HOST = "https://${cfg.local.serverHost}.${cfg.local.tailnetDomain}:${toString cfg.local.tailscaleServe.httpsPort}";
};

# Still install client tools
environment.systemPackages = [
  python3
  uv
] ++ lib.optional cfg.local.cli pkgs.opencode;
```

### Assertions

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

## Configuration Examples

### Desktop (Server)

```nix
{
  services.ai = {
    enable = true;

    local = {
      enable = true;
      role = "server";  # Default, explicit for clarity

      models = [ "mistral:7b" "qwen3:14b" ];

      tailscaleServe = {
        enable = true;
        httpsPort = 8447;
      };
    };
  };
}
```

### Laptop (Client)

```nix
{
  services.ai = {
    enable = true;  # Full Claude/Gemini/MCP experience

    local = {
      enable = true;
      role = "client";
      serverHost = "edge";
      tailnetDomain = "taile0fb4.ts.net";
      # OpenCode will use OLLAMA_HOST=https://edge.taile0fb4.ts.net:8447
    };
  };
}
```

## Impact Analysis

### What Changes

| Component | Server Role | Client Role |
|-----------|-------------|-------------|
| Ollama service | Installed & running | NOT installed |
| ROCm packages | Installed | NOT installed |
| amdgpu module | Loaded | NOT loaded |
| OpenCode | Uses localhost:11434 | Uses OLLAMA_HOST |
| OLLAMA_HOST env | Not set (default) | Set to remote URL |

### What Stays the Same

- `services.ai.enable` behavior unchanged
- Claude Code, Gemini CLI, MCP servers work identically
- All existing server configurations remain compatible

### Migration Path

**No breaking changes for existing users:**
- `services.ai.local.enable = true` continues to work (defaults to server role)
- New `role` option defaults to "server"

## Dependencies

- Requires: Tailscale module for serve configuration
- Enables: Open WebUI integration (separate proposal)
- Enables: axios Portal (separate proposal)

## Port Allocation

| Service | Local Port | Tailscale Port |
|---------|------------|----------------|
| Ollama API | 11434 | 8447 |

## Testing Requirements

- [ ] Server role: Verify Ollama starts with ROCm
- [ ] Server role: Verify Tailscale serve exposes API
- [ ] Client role: Verify no Ollama service installed
- [ ] Client role: Verify OLLAMA_HOST environment variable set
- [ ] Client role: Verify OpenCode connects to remote
- [ ] Assertion: Client without serverHost fails
- [ ] Assertion: Client without tailnetDomain fails
- [ ] Migration: Existing configs continue to work

## Alternatives Considered

### Alternative 1: Separate modules

Split into `services.ai.ollama-server` and `services.ai.ollama-client`.

**Rejected**: Inconsistent with axios-ai-mail pattern, more complex configuration.

### Alternative 2: Auto-detect GPU

Automatically choose role based on GPU presence.

**Rejected**: User may have GPU but want client mode, or vice versa. Explicit is better.

## References

- axios-ai-mail server/client pattern: `modules/pim/default.nix`
- Current AI module: `modules/ai/default.nix`
- Tailscale serve documentation
