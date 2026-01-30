# Personal Information Management (PIM)

> **Delta**: Updates for loopback secure context -- HTTPS-only server access, removal of `.local` domain and insecure Chromium flags.

## MODIFIED Requirements

### Requirement: Cross-Device Access

axios-ai-mail SHALL support secure cross-device access via Tailscale Services.

#### Scenario: Tailscale Services (server with authkey mode)

- **Given**: Server has `networking.tailscale.authMode = "authkey"`
- **And**: `pim.role = "server"`
- **And**: Device is connected to tailnet
- **When**: User accesses `https://axios-mail.<tailnet>.ts.net`
- **Then**: User can access axios-ai-mail web UI securely
- **And**: Service is auto-registered via Tailscale Services

#### Scenario: Server-local access via loopback proxy (MODIFIED)

- **Given**: `pim.role = "server"`
- **And**: `loopbackProxy.enable = true` on the `axios-mail` Tailscale service
- **When**: The server's browser navigates to `https://axios-mail.<tailnet>.ts.net`
- **Then**: `/etc/hosts` resolves the FQDN to `127.0.0.1`
- **And**: nginx on `127.0.0.1:443` serves the request with a valid LE certificate
- **And**: nginx proxies the request to `http://127.0.0.1:<pim.port>/`
- **And**: The browser has a valid HTTPS secure context
- **And**: Web Push notifications (`PushManager.subscribe()`) succeed

### Requirement: PWA Desktop Entry

Users SHALL be able to generate a desktop entry for axios-ai-mail.

#### Scenario: PWA on server role (MODIFIED)

- **Given**: `pim.role = "server"`
- **And**: `pim.pwa.enable = true`
- **And**: `pim.pwa.tailnetDomain` is set
- **When**: Home-manager activates
- **Then**: Desktop entry is created for "Axios Mail"
- **And**: URL is `https://axios-mail.${tailnetDomain}/` (same as client)
- **And**: Icon is axios-mail icon
- **And**: StartupWMClass is `brave-axios-mail.${tailnetDomain}__-Default`
- **And**: No `--unsafely-treat-insecure-origin-as-secure` flag is present
- **And**: No `--test-type` flag is present

#### Scenario: PWA on client role (unchanged)

- **Given**: `pim.role = "client"`
- **And**: `pim.pwa.enable = true`
- **And**: `pim.pwa.tailnetDomain` is set
- **When**: Home-manager activates
- **Then**: Desktop entry is created for "Axios Mail"
- **And**: URL is `https://axios-mail.${tailnetDomain}/`
- **And**: Icon is axios-mail icon
- **And**: StartupWMClass is `brave-axios-mail.${tailnetDomain}__-Default`

### Requirement: Tailscale Service Registration (Server)

PIM server role SHALL register an `axios-mail` Tailscale service with loopback proxy enabled.

#### Scenario: Server role Tailscale service (MODIFIED)

- **Given**: `pim.role = "server"`
- **When**: NixOS configuration is evaluated
- **Then**: `networking.tailscale.services."axios-mail"` is enabled
- **And**: `backend` is `http://127.0.0.1:${pim.port}`
- **And**: `loopbackProxy.enable` is `true`

## REMOVED Requirements

### Requirement: Local Domain Hostname (`.local`)

The `/etc/hosts` entry mapping `axios-mail.local` to `127.0.0.1` is removed from the PIM module.

**Rationale**: The Tailscale module now manages `/etc/hosts` entries for loopback-proxied services using the real FQDN. The `.local` convention is no longer needed.

### Requirement: Insecure Origin Chromium Flags

The `--test-type --unsafely-treat-insecure-origin-as-secure=http://axios-mail.local:<port>` Chromium flags are removed from the PWA desktop entry.

**Rationale**: With the loopback proxy providing a valid HTTPS secure context, these flags are unnecessary. They also did not fix the PushManager API, which was the motivation for the loopback proxy.
