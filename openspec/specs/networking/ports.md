# axios Port Registry

## Overview

This document defines port allocations for axios services. All services follow a consistent pattern:

- **Local port**: Service listens on localhost (or 0.0.0.0 for LAN access)
- **Tailscale port**: HTTPS exposure via `tailscale serve` for secure remote access

## Allocation Principles

1. **Local ports**: 8080-8099 for web services, upstream defaults for third-party services
2. **Tailscale ports**: 8443-8459 for HTTPS exposure
3. **Offset convention**: Tailscale port = Local port + 363 (where practical)
4. **Reserved ranges**: Leave gaps for related services
5. **Upstream defaults**: Preserve upstream port conventions (Ollama 11434, Immich 2283)

## Current Allocations

### Web Application Services

| Service | Local Port | Tailscale Port | Module | Status |
|---------|------------|----------------|--------|--------|
| axios-ai-mail | 8080 | 8443 | `pim` | Active |
| Open WebUI | 8081 | 8444 | `ai.webui` | Active |
| axios Portal | 8082 | 8445 | `portal` | Planned |
| axios Calendar | 8083 | 8446 | `pim.calendar` | Planned |
| *Reserved* | 8084-8089 | — | — | Future |

### API Services

| Service | Local Port | Tailscale Port | Module | Status |
|---------|------------|----------------|--------|--------|
| Ollama API | 11434 | 8447 | `ai.local` | Active |
| MCP Gateway | 8085 | 8448 | `ai.mcpGateway` | In Progress |
| *Reserved* | — | 8449 | — | Future APIs |

### Media Services

| Service | Local Port | Tailscale Port | Module | Status |
|---------|------------|----------------|--------|--------|
| Immich | 2283 | 8450 | `selfHosted.immich` | Active |
| *Reserved* | — | 8451-8459 | — | Future media |

## Port Ranges Summary

| Range | Purpose |
|-------|---------|
| 8080-8089 | Local web application services |
| 8443-8446 | Tailscale HTTPS (axios web apps) |
| 8447-8449 | Tailscale HTTPS (APIs) |
| 8450-8459 | Tailscale HTTPS (media services) |
| 11434 | Ollama (upstream default) |
| 2283 | Immich (upstream default) |

## Adding New Services

When adding a new axios service:

1. **Check this registry** for conflicts
2. **Choose next available port** in appropriate range
3. **Update this document** in your proposal's delta
4. **Follow naming convention**:
   - `services.{name}.port` for local port
   - `services.{name}.tailscaleServe.httpsPort` for Tailscale port

## Configuration Pattern

All axios services should follow this NixOS module pattern:

```nix
services.example = {
  enable = lib.mkEnableOption "Example service";

  port = lib.mkOption {
    type = lib.types.port;
    default = 80XX;  # From registry
    description = "Local port for Example service";
  };

  tailscaleServe = {
    enable = lib.mkEnableOption "Expose via Tailscale HTTPS";
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 84XX;  # From registry
      description = "HTTPS port for Tailscale serve";
    };
  };
};
```

## Server/Client Pattern

For services that support distributed deployment:

```nix
# Server role exposes service via Tailscale
services.example.role = "server";
services.example.tailscaleServe.enable = true;

# Client role connects to remote server
services.example.role = "client";
services.example.serverHost = "edge";
services.example.tailnetDomain = "taile0fb4.ts.net";
services.example.serverPort = 84XX;  # Matches server's httpsPort
```

## Cross-References

- **axios-ai-mail**: See `openspec/specs/pim/spec.md`
- **AI/Ollama**: See `openspec/specs/ai/spec.md`
- **Open WebUI**: See `openspec/specs/ai/spec.md` (Open WebUI section)
- **Immich**: See `selfHosted` module documentation

---

*Last updated: January 2026*
