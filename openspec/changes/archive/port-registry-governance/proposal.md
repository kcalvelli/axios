# Proposal: Port Registry Governance

## Summary

Establish a formal port allocation registry for axios services, documenting both local service ports and Tailscale HTTPS ports to prevent conflicts and provide clear documentation.

## Motivation

### Problem Statement

As axios expands its service ecosystem (axios-ai-mail, Open WebUI, Ollama API, future services), port allocation becomes critical:

- Services must not conflict on local ports
- Tailscale serve ports need coordination
- Users need clear documentation of what runs where
- Future services need reserved ranges

### Solution

Create a governance document that:
1. Documents all current port allocations
2. Reserves ranges for future expansion
3. Establishes conventions for new services

## Proposed Changes

### New Document: openspec/specs/networking/ports.md

```markdown
# axios Port Registry

## Overview

This document defines port allocations for axios services. All services follow a consistent pattern:

- **Local port**: Service listens on localhost
- **Tailscale port**: HTTPS exposure via `tailscale serve`

## Allocation Principles

1. **Local ports**: 8080-8099 for web services, 11434 for Ollama (upstream default)
2. **Tailscale ports**: 8443-8499 for HTTPS exposure
3. **Offset convention**: Tailscale port = Local port + 363 (where practical)
4. **Reserved ranges**: Leave gaps for related services

## Current Allocations

### Web Services

| Service | Local Port | Tailscale Port | Status |
|---------|------------|----------------|--------|
| axios-ai-mail | 8080 | 8443 | Active |
| Open WebUI | 8081 | 8444 | Proposed |
| axios-portal | 8082 | 8445 | Planned |
| axios-calendar | 8083 | 8446 | Planned |
| *Reserved* | 8084-8089 | 8447-8452 | Future |

### API Services

| Service | Local Port | Tailscale Port | Status |
|---------|------------|----------------|--------|
| Ollama API | 11434 | 8447 | Proposed |
| *Reserved* | - | 8448-8449 | Future APIs |

### Media Services

| Service | Local Port | Tailscale Port | Status |
|---------|------------|----------------|--------|
| Immich | 2283 | 8450 | Planned |
| *Reserved* | - | 8451-8459 | Future media |

## Port Ranges Summary

| Range | Purpose |
|-------|---------|
| 8080-8089 | Web application services |
| 8443-8452 | Tailscale HTTPS (web apps) |
| 8447-8449 | Tailscale HTTPS (APIs) |
| 8450-8459 | Tailscale HTTPS (media) |
| 11434 | Ollama (upstream default) |
| 2283 | Immich (upstream default) |

## Adding New Services

When adding a new axios service:

1. Check this registry for conflicts
2. Choose next available port in appropriate range
3. Update this document in your proposal
4. Follow naming convention: `services.{name}.port` and `services.{name}.tailscaleServe.httpsPort`

## Configuration Pattern

All axios services should follow this pattern:

```nix
services.example = {
  port = lib.mkOption {
    type = lib.types.port;
    default = 80XX;  # From registry
  };

  tailscaleServe = {
    enable = lib.mkEnableOption "...";
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 84XX;  # From registry
    };
  };
};
```
```

### Updates to Existing Specs

Update `openspec/specs/pim/spec.md` to reference port registry.

## Impact Analysis

### Benefits

- Clear documentation for users
- Prevents port conflicts
- Guides future development
- Establishes conventions

### No Breaking Changes

This is documentation only - no code changes required.

## Testing Requirements

- [ ] Document created at correct location
- [ ] All existing services documented
- [ ] Cross-references added to service specs

## Future Considerations

- Could add CI check to validate port allocations in code match registry
- Could generate port documentation from Nix module definitions

## References

- axios-ai-mail: `modules/pim/default.nix`
- Tailscale serve documentation
