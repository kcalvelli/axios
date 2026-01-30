# Proposal: Add Loopback Secure Context for Server PWAs

## Summary

Add a `loopbackProxy` option to the Tailscale service submodule that deploys a local nginx reverse proxy on `127.0.0.1:443` with real Let's Encrypt certificates from `tailscale cert`. This gives server-local PWAs a valid HTTPS secure context, enabling Web Push notifications and other security-gated browser APIs.

## Problem Statement

### Current State

Server-role PWAs access local services via `http://<service>.local:<port>` to avoid Tailscale Services VIP hairpinning. This plain HTTP origin is **not** a W3C Secure Context, which causes:

1. **Web Push API failure**: `PushManager.subscribe()` requires a secure context and fails unconditionally on insecure origins.
2. **Chromium flag ineffective**: `--unsafely-treat-insecure-origin-as-secure` only affects some APIs (e.g., `isSecureContext` property) but does **not** fix PushManager.
3. **No HTTPS path exists**: Tailscale Services VIPs cannot be reached from the serving node (kernel-level hairpinning), and `tailscale serve` does not listen on the node's own Tailscale IP (100.x.y.z).

### Empirical Verification

The following was tested and confirmed:

- `tailscale serve` does NOT listen on the node's own Tailscale IP for Services traffic (curl: connection refused).
- Tailscale Services VIPs cannot be reached from the serving node (hairpinning restriction).
- `tailscale cert` successfully issues real Let's Encrypt certificates for Services FQDNs (verified with openssl: valid cert from LE issuer E8, CN matches service FQDN).

### Systemic Scope

This hairpinning workaround currently appears in **four** modules, all using the same `networking.hosts` + `.local` pattern:

| Module | Service | Current Pattern |
|--------|---------|-----------------|
| `modules/pim/default.nix` | axios-mail | `axios-mail.local:8080` |
| `modules/ai/default.nix` | axios-ollama | `axios-ollama.local:11434` |
| `modules/services/immich.nix` | axios-immich | `axios-immich.local:2283` |
| `home/ai/mcp-gateway.nix` | mcp-gateway | `mcp-gateway.local:8085` |

The loopback proxy provides a single, generic solution that all services can opt into.

## Proposed Solution

### Architecture

```
Browser -> https://axios-mail.<tailnet>.ts.net
        -> /etc/hosts resolves to 127.0.0.1 (server only)
        -> nginx (127.0.0.1:443) with real LE cert from `tailscale cert`
        -> proxy_pass to 127.0.0.1:<port> (app backend)
        -> valid secure context -> Push API works
```

Remote clients are completely unaffected -- they resolve via Tailscale DNS to the VIP as before.

### Key Design Decisions

1. **Generic, not service-specific**: The loopback proxy logic lives in `modules/networking/tailscale.nix` and iterates over `cfg.services` checking `loopbackProxy.enable`. No service names are hardcoded.

2. **nginx on loopback only**: nginx listens only on `127.0.0.1:443` to avoid conflicting with `tailscale serve` on the Tailscale interface. The `listen` directive is explicit.

3. **Real LE certs via `tailscale cert`**: No self-signed certificates. The browser sees a valid chain of trust (Let's Encrypt issuer). A systemd timer renews daily.

4. **`/etc/hosts` migration**: The tailscale module now manages `/etc/hosts` entries for loopback-proxied services using the real FQDN (e.g., `axios-mail.<tailnet>.ts.net -> 127.0.0.1`) instead of the old `.local` convention.

5. **PWA URL unification**: Since both server and client now use the same HTTPS URL, all server/client conditionals and insecure Chromium flags are removed from home modules.

### Scope (This Proposal)

- **Implement now**: `axios-mail` (PIM module) -- the immediate need for Web Push.
- **Opt-in later**: `mcp-gateway`, `axios-immich`, `axios-ollama` can enable `loopbackProxy.enable = true` in future changes.
- **This proposal only modifies existing modules** -- no new module registration required.

## Capabilities Affected

1. **Networking / Tailscale** (`openspec/specs/networking/`) -- new `loopbackProxy` sub-option on services, cert sync service, nginx generation, /etc/hosts generation.
2. **PIM** (`openspec/specs/pim/spec.md`) -- enable loopback proxy for axios-mail, update PWA requirements to reflect HTTPS-only access.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| nginx port 443 conflict with other local services | Listen only on `127.0.0.1`, not `0.0.0.0`. Check with assertions. |
| Certificate renewal failure | Daily timer with retry logic; `tailscale cert` is idempotent. Service health unaffected (existing cert remains valid until expiry). |
| wmClass change on server PWA | `StartupWMClass` will change from `brave-axios-mail.local__-Default` to `brave-axios-mail.<tailnet>__-Default`. User may need to re-pin the dock icon once. Documented in tasks. |
| nginx not enabled on minimal installs | nginx is only enabled when at least one service has `loopbackProxy.enable = true`. No impact on systems without it. |

## Related Documents

- `openspec/specs/pim/spec.md` -- current PIM spec
- `openspec/specs/networking/ports.md` -- port registry (443 is standard HTTPS, no registration needed)
- `openspec/specs/services/spec.md` -- self-hosted services patterns
- `modules/networking/tailscale.nix` -- current Tailscale module
