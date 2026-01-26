# Tasks: Open WebUI Integration

## Overview

Add Open WebUI as an axios service with server/client roles, Tailscale serve integration, and PWA desktop entry generation.

**Depends On**: AI Module Server/Client Refactor (proposal #1) ✅

---

## Phase 1: Research and Preparation ✅

### Task 1.1: Verify Open WebUI in nixpkgs
- [x] Check `nixpkgs` for `open-webui` package (v0.7.2 available)
- [x] Verify package version and options
- [x] Document NixOS service options (8 options available)

### Task 1.2: Test Open WebUI Manually
- [x] Verified Ollama integration via environment variables
- [x] Identified required environment variables (OLLAMA_BASE_URL)
- [x] Documented default port (8080) and configuration

---

## Phase 2: NixOS Module Creation ✅

### Task 2.1: Create Module Structure
- [x] Create `modules/ai/webui.nix`
- [x] Import in `modules/ai/default.nix`

### Task 2.2: Define Module Options
- [x] Add `services.ai.webui.enable` option
- [x] Add `services.ai.webui.role` option (server/client)
- [x] Add `services.ai.webui.port` option (default 8081)
- [x] Add `services.ai.webui.ollama.endpoint` option
- [x] Add `services.ai.webui.tailscaleServe.*` options
- [x] Add `services.ai.webui.pwa.*` options
- [x] Add `services.ai.webui.serverHost` option (client role)
- [x] Add `services.ai.webui.serverPort` option (client role)

### Task 2.3: Implement Server Role
- [x] Enable `services.open-webui` when role == "server"
- [x] Configure Ollama endpoint
- [x] Set privacy-preserving environment variables (telemetry disabled)
- [x] Configure Tailscale serve when enabled

### Task 2.4: Add Assertions
- [x] Assert PWA requires tailnetDomain
- [x] Assert client role requires serverHost
- [x] Assert tailscaleServe only for server role

---

## Phase 3: Home-Manager Module (PWA) ✅

### Task 3.1: Create Home Module
- [x] Create `home/ai/webui.nix`
- [x] Import in `home/ai/default.nix`

### Task 3.2: Implement PWA Desktop Entry
- [x] Generate desktop entry when `pwa.enable = true`
- [x] Calculate correct URL based on role and serverHost
- [x] Set StartupWMClass for Brave PWA

---

## Phase 4: Icon Creation ✅

### Task 4.1: Design Icon
- [x] Placeholder icon created (copy of axios-ai-mail)
- [ ] Create proper icon with chat bubble center element (deferred)

### Task 4.2: Add Icon to Resources
- [x] Save to `home/resources/pwa-icons/axios-ai-chat.png`

---

## Phase 5: Integration with AI Module ✅

### Task 5.1: Import webui.nix
- [x] Add import to `modules/ai/default.nix`

### Task 5.2: Auto-configure Ollama Endpoint for Client
- [x] Default endpoint uses localhost:11434 (works for server role)
- [x] Client role can override via serverHost/serverPort

---

## Phase 6: Documentation ✅

### Task 6.1: Update Module Documentation
- [x] Add webui section to `docs/MODULE_REFERENCE.md`
- [x] Include server and client configuration examples

### Task 6.2: Update AI Spec
- [x] Add webui to `openspec/specs/ai/spec.md`
- [x] Document PWA access pattern
- [x] Update port registry status to Active

---

## Phase 7: Testing

### Task 7.1: Server Role Tests
- [ ] Test: Open WebUI service starts on edge
- [ ] Test: Connects to local Ollama
- [ ] Test: Tailscale serve exposes correctly
- [ ] Test: Web UI accessible via browser

### Task 7.2: Client Role Tests
- [ ] Test: No service installed for client role on pangolin
- [ ] Test: PWA desktop entry created
- [ ] Test: PWA URL points to remote server

### Task 7.3: PWA Tests
- [ ] Test: Icon displays in app launcher
- [ ] Test: PWA opens in app mode (no browser chrome)

### Task 7.4: Mobile Tests (Manual)
- [ ] Test: Access from phone via Tailscale
- [ ] Test: Add to home screen works

---

## Phase 8: Finalization

### Task 8.1: Code Review Checklist
- [x] Options follow axios patterns
- [x] Server/client pattern matches axios-ai-mail
- [x] PWA generation matches existing pattern
- [x] Privacy settings configured

### Task 8.2: Merge Specs
- [ ] Update specs and archive (pending testing)

---

## Files Created

| File | Purpose |
|------|---------|
| `modules/ai/webui.nix` | NixOS module for Open WebUI |
| `home/ai/webui.nix` | Home-manager module for PWA |
| `home/resources/pwa-icons/axios-ai-chat.png` | PWA icon (placeholder) |

## Files Modified

| File | Changes |
|------|---------|
| `modules/ai/default.nix` | Import webui.nix |
| `home/ai/default.nix` | Import home webui module |

## User Config Updated

| File | Changes |
|------|---------|
| `~/.config/nixos_config/hosts/edge.nix` | Server role, Tailscale 8444 |
| `~/.config/nixos_config/hosts/pangolin.nix` | Client role, connects to edge |

---

## Port Allocations (per registry)

| Service | Local Port | Tailscale Port |
|---------|------------|----------------|
| Open WebUI | 8081 | 8444 |

---

## Next Steps

1. Rebuild edge first (server role)
2. Test Open WebUI at https://edge.taile0fb4.ts.net:8444/
3. Create first user account (signup disabled after first user)
4. Rebuild pangolin (client role)
5. Test PWA on both machines
