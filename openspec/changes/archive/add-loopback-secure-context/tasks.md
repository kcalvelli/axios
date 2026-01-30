# Implementation Tasks: Loopback Secure Context for Server PWAs

## Phase 1: Tailscale Module -- loopbackProxy Infrastructure

- [x] **1.1** Add `loopbackProxy` sub-option to `serviceModule` in `modules/networking/tailscale.nix`
  ```nix
  loopbackProxy = {
    enable = lib.mkEnableOption "local nginx HTTPS proxy for secure context";
  };
  ```

- [x] **1.2** Add assertion: `loopbackProxy.enable` requires `networking.tailscale.domain` to be set
  ```nix
  {
    assertion = !hasLoopbackServices || cfg.domain != null;
    message = ''
      Tailscale loopbackProxy requires networking.tailscale.domain to be set.
      ...
    '';
  }
  ```

- [x] **1.3** Create certificate directory via `systemd.tmpfiles.rules`
  - Path: `/var/lib/tailscale/certs/`
  - Permissions: `0750 root nginx`
  - Only created when at least one service has `loopbackProxy.enable = true`

- [x] **1.4** Generate systemd cert sync oneshot service per loopback-proxied service
  - Service name: `tailscale-cert-<service>`
  - After/Wants: `tailscaled.service`, `network-online.target`
  - PreStart: Wait for Tailscale to reach Running state (same pattern as existing `mkTailscaleService`)
  - ExecStart: `tailscale cert --cert-file /var/lib/tailscale/certs/<fqdn>.crt --key-file /var/lib/tailscale/certs/<fqdn>.key <fqdn>`
  - ExecStartPost: `chmod 640 /var/lib/tailscale/certs/<fqdn>.key` and `systemctl reload-or-restart nginx`
  - WantedBy: `multi-user.target`

- [x] **1.5** Generate systemd daily timer per loopback-proxied service
  - Timer name: `tailscale-cert-<service>`
  - `OnCalendar = "daily"`
  - `Persistent = true` (catch up after missed runs)

- [x] **1.6** Enable nginx and generate virtualHosts for loopback-proxied services
  - `services.nginx.enable = true` (only if at least one loopback-proxied service exists)
  - Per-service virtualHost:
    - `serverName = "<service>.${cfg.domain}"`
    - `listen = [{ addr = "127.0.0.1"; port = 443; ssl = true; }]`
    - `sslCertificate = "/var/lib/tailscale/certs/<fqdn>.crt"`
    - `sslCertificateKey = "/var/lib/tailscale/certs/<fqdn>.key"`
    - `locations."/" = { proxyPass = svc.backend; proxyWebsockets = true; }`
    - Headers: `proxy_set_header Host $host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`

- [x] **1.7** Generate `/etc/hosts` entries for loopback-proxied services
  - Map `<service>.${cfg.domain}` to `127.0.0.1`
  - Only for services with `loopbackProxy.enable = true`
  - This replaces per-module `.local` hostname entries

- [x] **1.8** Verify: `nix flake check` passes with the new tailscale module options

## Phase 2: PIM Module -- Enable loopbackProxy for axios-mail

- [x] **2.1** Update `modules/pim/default.nix`: enable `loopbackProxy` on axios-mail service
  ```nix
  networking.tailscale.services."axios-mail" = lib.mkIf isServer {
    enable = true;
    backend = "http://127.0.0.1:${toString cfg.port}";
    loopbackProxy.enable = true;
  };
  ```

- [x] **2.2** Remove the old `networking.hosts` block from `modules/pim/default.nix`
  - Deleted the `networking.hosts = lib.mkIf isServer { "127.0.0.1" = [ "axios-mail.local" ]; };` block
  - The Tailscale module now handles `/etc/hosts` with the real FQDN

- [x] **2.3** Verify: `nix flake check` passes after PIM module changes

## Phase 3: Home-Manager PWA -- Unify URL and Remove Insecure Flags

- [x] **3.1** Update `home/pim/default.nix`: unify `pwaUrl` to always use HTTPS
  - Removed the `if isServer then ... else ...` conditional
  - Set: `pwaUrl = "https://axios-mail.${tailnetDomain}/";`

- [x] **3.2** Update `home/pim/default.nix`: unify `pwaHost`
  - Removed the `if isServer then ... else ...` conditional
  - Set: `pwaHost = "axios-mail.${tailnetDomain}";`

- [x] **3.3** Remove insecure Chromium flags from the PWA exec command
  - Removed: `--test-type --unsafely-treat-insecure-origin-as-secure=http://axios-mail.local:${toString localPort}`
  - The `localPort` variable is no longer needed

- [x] **3.4** Clean up unused `let` bindings
  - Removed `localPort` (was only used for server URL and insecure flag)
  - `isServer` retained for the `imports` conditional (axios-ai-mail home module import)

- [x] **3.5** Verify: `nix flake check` passes after home module changes

## Phase 4: Formatting and Validation

- [x] **4.1** Run `nix fmt .` on all modified files

- [x] **4.2** Final `nix flake check` to confirm everything builds

## Phase 5: Spec Finalization

- [ ] **5.1** Merge networking spec delta into `openspec/specs/networking/`
  - If `openspec/specs/networking/spec.md` does not exist, create it from the delta
  - If it exists, merge the ADDED/MODIFIED requirements

- [ ] **5.2** Update `openspec/specs/pim/spec.md` with the MODIFIED/REMOVED requirements from the delta

- [ ] **5.3** Archive the change directory
  ```bash
  mv openspec/changes/add-loopback-secure-context openspec/changes/archive/
  ```

## Phase 6: Deploy and Verify

- [ ] **6.1** Push changes to remote (`git push`)

- [ ] **6.2** Rebuild NixOS on server host

- [ ] **6.3** Verify nginx starts on `127.0.0.1:443` with valid LE cert
  ```bash
  curl -v https://axios-mail.<tailnet>/api/version
  ```

- [ ] **6.4** Verify PWA opens with HTTPS URL and green lock icon

- [ ] **6.5** Verify Push notifications can be enabled (PushManager.subscribe() succeeds)

- [ ] **6.6** Verify remote client access via Tailscale Services VIP is unaffected

- [ ] **6.7** Verify `tailscale serve status` shows the service registered normally

## Notes

- **wmClass change**: The server PWA's `StartupWMClass` changes from `brave-axios-mail.local__-Default` to `brave-axios-mail.<tailnet>__-Default`. The user will need to re-pin the dock icon after the first rebuild.
- **Parallelizable**: Phases 1 and 3 can be developed in parallel since they modify different files. Phase 2 depends on Phase 1.
- **Future services**: After this change lands, `axios-immich`, `axios-ollama`, and `mcp-gateway` can opt into the loopback proxy by adding `loopbackProxy.enable = true` to their service definitions in separate changes.
