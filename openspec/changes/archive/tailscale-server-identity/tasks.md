# Tasks: Tailscale Server Identity & Services Integration

## Status: Critical

## Overview

Enable tag-based Tailscale identity for axios server machines, with automatic Tailscale Services registration for unique DNS names per service. Solves PWA icon/app_id problem on Wayland.

---

## Phase 1: Tailscale Module Creation

### Task 1.1: Create Tailscale Module Structure
- [ ] Create `modules/networking/tailscale.nix`
- [ ] Import in `modules/networking/default.nix`
- [ ] Register in `modules/default.nix`

### Task 1.2: Define Auth Mode Options
- [ ] Add `networking.tailscale.authMode` option (interactive/authkey)
- [ ] Add `networking.tailscale.authKeySecret` option
- [ ] Add `networking.tailscale.tags` option
- [ ] Add assertions: authkey requires authKeySecret

### Task 1.3: Implement Auth Key Authentication
- [ ] Read auth key from agenix secret
- [ ] Configure tailscaled to use auth key on first boot
- [ ] Handle re-authentication on key change

---

## Phase 2: Tailscale Services Support

### Task 2.1: Define Services Options
- [ ] Add `networking.tailscale.services` attrsOf submodule
- [ ] Options: enable, port, backend
- [ ] Add assertions: services require authMode = "authkey"

### Task 2.2: Generate Systemd Services
- [ ] Create systemd service per Tailscale service
- [ ] Use `tailscale serve --service` command
- [ ] Handle cleanup on service disable
- [ ] Proper ordering: After tailscaled.service

### Task 2.3: Handle Service Lifecycle
- [ ] ExecStart: Register service
- [ ] ExecStop: Unregister service
- [ ] Handle tailscaled restarts gracefully

---

## Phase 3: Service Auto-Registration

### Task 3.1: Update PIM Module (axios-ai-mail)
- [ ] Server role registers `axios-mail` service
- [ ] Remove legacy tailscaleServe options (deprecate)
- [ ] Update port configuration

### Task 3.2: Update AI WebUI Module (axios-ai-chat)
- [ ] Server role registers `axios-chat` service
- [ ] Remove legacy tailscaleServe options (deprecate)
- [ ] Update port configuration

### Task 3.3: Update AI Ollama Module
- [ ] Server role registers `axios-ollama` service
- [ ] Remove legacy tailscaleServe options (deprecate)
- [ ] Update port configuration

---

## Phase 4: PWA URL Generation Updates

### Task 4.1: Update Home PIM Module
- [ ] Detect if Tailscale Services enabled
- [ ] Generate URL using service DNS name
- [ ] Fallback to legacy port-based URL if not

### Task 4.2: Update Home AI WebUI Module
- [ ] Detect if Tailscale Services enabled
- [ ] Generate URL using service DNS name
- [ ] Fallback to legacy port-based URL if not

### Task 4.3: Update pwa-apps Package
- [ ] Support service-based URLs in urlToAppId
- [ ] Verify app_id generation for service URLs

---

## Phase 5: Client Role Updates

### Task 5.1: Update Client Configuration
- [ ] Client role uses service DNS name for server
- [ ] Simplify: just need tailnetDomain, service name derived
- [ ] Update serverHost to accept service name or hostname

### Task 5.2: Update PWA Generation for Clients
- [ ] Client PWAs point to service URLs
- [ ] Icon matching works correctly

---

## Phase 6: Documentation

### Task 6.1: User Setup Guide
- [ ] Document auth key creation in Tailscale admin
- [ ] Document ACL configuration
- [ ] Document agenix secret creation
- [ ] Provide example host configuration

### Task 6.2: Update Module Docs
- [ ] Update MODULE_REFERENCE.md
- [ ] Update networking section
- [ ] Document migration path

### Task 6.3: Update Specs
- [ ] Update `openspec/specs/networking/` for Tailscale
- [ ] Update `openspec/specs/ai/spec.md`
- [ ] Update `openspec/specs/pim/spec.md`
- [ ] Update port registry (services use 443)

---

## Phase 7: Testing

### Task 7.1: Auth Key Authentication
- [ ] Test: Device authenticates with auth key
- [ ] Test: Tags applied correctly
- [ ] Test: Re-authentication after rebuild

### Task 7.2: Services Registration
- [ ] Test: Services register on boot
- [ ] Test: Services accessible via DNS name
- [ ] Test: Services cleanup on stop

### Task 7.3: PWA Icon Fix Verification
- [ ] Test: Each PWA has unique app_id
- [ ] Test: Icons display correctly in dock
- [ ] Test: Window grouping works

### Task 7.4: Client Access
- [ ] Test: User-owned devices can access services
- [ ] Test: Mobile devices can access services
- [ ] Test: PWAs work on client machines

---

## Phase 8: Migration & Cleanup

### Task 8.1: Deprecation Warnings
- [ ] Add warnings for legacy tailscaleServe options
- [ ] Document migration in UPGRADE.md

### Task 8.2: Backwards Compatibility
- [ ] Ensure authMode = "interactive" still works
- [ ] Legacy port-based URLs still functional

### Task 8.3: Archive
- [ ] Merge specs to openspec/specs/
- [ ] Archive this change directory

---

## Implementation Order

1. **Phase 1** - Tailscale module (foundation)
2. **Phase 2** - Services support (core feature)
3. **Phase 3** - Service auto-registration (integration)
4. **Phase 4** - PWA updates (user-facing fix)
5. **Phase 5** - Client updates (complete the loop)
6. **Phase 6** - Documentation (user enablement)
7. **Phase 7** - Testing (validation)
8. **Phase 8** - Cleanup (finalization)

---

## User Migration Checklist

When implementing, user must:

1. [ ] Create Tailscale auth key with `tag:axios-server`
2. [ ] Configure ACLs in Tailscale admin
3. [ ] Create agenix secret for auth key
4. [ ] Update edge.nix with new config
5. [ ] Rebuild edge (will re-authenticate)
6. [ ] Verify services in `tailscale serve status`
7. [ ] Update pangolin.nix for client role
8. [ ] Rebuild pangolin
9. [ ] Test PWAs on both machines

---

## Files to Create

| File | Purpose |
|------|---------|
| `modules/networking/tailscale.nix` | Tailscale auth and services module |

## Files to Modify

| File | Changes |
|------|---------|
| `modules/networking/default.nix` | Import tailscale.nix |
| `modules/default.nix` | Register tailscale module |
| `modules/pim/default.nix` | Register axios-mail service |
| `modules/ai/webui.nix` | Register axios-chat service |
| `modules/ai/default.nix` | Register axios-ollama service |
| `home/pim/default.nix` | Service-based PWA URL |
| `home/ai/webui.nix` | Service-based PWA URL |
| `docs/MODULE_REFERENCE.md` | Document new options |
| `docs/UPGRADE.md` | Migration guide |

---

## Blocked By

None - ready to implement.

## Blocks

- Open WebUI testing (icons won't work correctly until this is done)
- Future axios services (all should use this pattern)

---

## Open Questions

1. **Service naming convention**: `axios-mail` vs `mail` vs `axios-ai-mail`?
   - Proposal: Use `axios-` prefix to avoid conflicts

2. **Default HTTPS port**: 443 for all services, or unique ports?
   - Proposal: All services on 443 (cleaner URLs)

3. **Immich integration**: Should Immich also use this pattern?
   - Proposal: Yes, add `axios-photos` service
