# Design: Loopback Secure Context for Server PWAs

## Problem

Server-role PWAs need a valid W3C Secure Context to use browser APIs like Push Notifications. The Tailscale Services hairpinning restriction prevents the server from reaching its own VIP, and plain HTTP `.local` URLs are not secure contexts.

## Solution Overview

Place nginx on `127.0.0.1:443` with real Let's Encrypt certificates obtained via `tailscale cert`, and map the service FQDN to `127.0.0.1` in `/etc/hosts` on the server only.

## Component Interactions

```
                          +--------------------------+
                          |   Tailscale Cert Sync    |
                          |   (systemd oneshot +     |
                          |    daily timer)          |
                          +------+-------------------+
                                 |
                                 | writes certs to
                                 | /var/lib/tailscale/certs/
                                 v
+----------+    HTTPS     +-----------+    HTTP    +------------+
| Browser  | ----------> |  nginx    | --------> | App Server |
| (PWA)    |  :443       | 127.0.0.1 |  :port    | 127.0.0.1  |
+----------+  LE cert    |  :443     |           |  :8080     |
     |                   +-----------+           +------------+
     |
     | DNS lookup: axios-mail.<tailnet>.ts.net
     v
  /etc/hosts -> 127.0.0.1  (server only)
  Tailscale DNS -> VIP     (remote clients)
```

## Trade-offs Considered

### Alternative 1: Self-Signed Certificates

**Rejected.** Self-signed certs require users to manually trust a CA or accept browser warnings. They also don't work cleanly with service workers, which enforce stricter cert validation. Since `tailscale cert` gives us real LE certs for free, there's no reason to go self-signed.

### Alternative 2: mkcert (Local CA)

**Rejected.** Requires installing a custom CA into the system trust store, adding configuration complexity. Also doesn't produce certificates for the actual Tailscale FQDN, so the URL would still differ between server and client roles. `tailscale cert` is simpler and produces the exact certificate we need.

### Alternative 3: Caddy Instead of nginx

**Considered but deferred.** axiOS already has a Caddy route registry pattern (`selfHosted.caddy.routes`), but the loopback proxy has fundamentally different requirements: it must listen only on `127.0.0.1`, uses externally-managed certificates (not ACME), and must coexist with `tailscale serve` on the Tailscale interface. Using nginx avoids coupling this concern to the Caddy registry. If Caddy is preferred later, the migration would be straightforward since the option interface is the same.

### Alternative 4: Per-Service nginx Configs in Each Module

**Rejected.** This would duplicate nginx configuration across PIM, AI, Immich, and MCP Gateway modules. Centralizing in the Tailscale module keeps the pattern DRY and ensures consistency.

## Certificate Lifecycle

1. **Provisioning**: `tailscale-cert-<service>.service` runs `tailscale cert` on first boot (after `tailscaled.service` reaches Running state).
2. **Storage**: Certs stored in `/var/lib/tailscale/certs/` with `0750 root:nginx` permissions.
3. **Renewal**: `tailscale-cert-<service>.timer` fires daily. `tailscale cert` is idempotent and only requests a new cert when the current one is near expiry.
4. **nginx Reload**: The cert service's `ExecStartPost` reloads nginx to pick up renewed certs.

## nginx Configuration Strategy

For each service with `loopbackProxy.enable = true`, the Tailscale module generates an `nginx.virtualHosts` entry:

- **`serverName`**: `<service>.<tailnetDomain>` (e.g., `axios-mail.example-tailnet.ts.net`)
- **`listen`**: `[{ addr = "127.0.0.1"; port = 443; ssl = true; }]` -- loopback only
- **`sslCertificate`/`sslCertificateKey`**: Paths in `/var/lib/tailscale/certs/`
- **`locations."/"`**: `proxyPass` to the service's `backend` URL
- **WebSocket support**: `proxyWebsockets = true` (required for axios-ai-mail real-time sync)
- **Headers**: `proxy_set_header Host $host` and standard forwarding headers

nginx itself is only enabled (`services.nginx.enable = true`) if at least one service uses the loopback proxy.

## /etc/hosts Strategy

The Tailscale module generates `/etc/hosts` entries mapping service FQDNs to `127.0.0.1` for all services with `loopbackProxy.enable = true`. This replaces the old per-module `.local` hostname pattern.

**Before** (per-module, scattered):
```
127.0.0.1  axios-mail.local         # in modules/pim/default.nix
127.0.0.1  axios-immich.local       # in modules/services/immich.nix
```

**After** (centralized in tailscale module):
```
127.0.0.1  axios-mail.example-tailnet.ts.net     # from loopbackProxy
127.0.0.1  axios-immich.example-tailnet.ts.net   # from loopbackProxy (future)
```

## PWA Impact

With the loopback proxy, server and client PWAs use identical URLs:
```
https://axios-mail.<tailnet>.ts.net/
```

This eliminates:
- The `if isServer then ... else ...` conditional in home modules
- The `--unsafely-treat-insecure-origin-as-secure` Chromium flag
- The `.local` domain convention for server access

**Breaking change**: The server PWA's `StartupWMClass` changes because the URL domain changes. Users will need to re-pin the dock icon after the first rebuild. This is a one-time inconvenience.

## Dependency Chain

```
tailscaled.service (must be Running)
    |
    v
tailscale-cert-<service>.service (provisions cert)
    |
    v
nginx.service (serves HTTPS with cert)
    |
    v
tailscale-service-<service>.service (registers with Tailscale Services)
```

The cert service must complete before nginx can start with valid certificates. The Tailscale service registration is independent of the loopback proxy.
