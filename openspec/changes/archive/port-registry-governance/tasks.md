# Tasks: Port Registry Governance

## Overview

Establish a formal port allocation registry for axios services. This is a documentation-only proposal with no code changes.

---

## Phase 1: Create Port Registry Document ✅

### Task 1.1: Create Directory Structure
- [x] Create `openspec/specs/networking/` directory

### Task 1.2: Write Port Registry Spec
- [x] Create `openspec/specs/networking/ports.md`
- [x] Document allocation principles
- [x] List all current allocations (axios-ai-mail, Ollama, Immich)
- [x] Define reserved ranges
- [x] Add configuration pattern examples

---

## Phase 2: Update Existing Documentation ✅

### Task 2.1: Update PIM Spec
- [x] Add References section to `openspec/specs/pim/spec.md`
- [x] Link to port registry with specific port allocations

### Task 2.2: Update AI Spec
- [x] Add References section to `openspec/specs/ai/spec.md`
- [x] Link to port registry with Ollama port allocations

### Task 2.3: Cross-Reference in CLAUDE.md
- [x] Not needed - port registry is discoverable via openspec/specs/

---

## Phase 3: Validation ✅

### Task 3.1: Audit Existing Code
- [x] Verified axios-ai-mail uses 8080/8443 (pim module defaults)
- [x] Verified Ollama uses 11434/8447 (ai module defaults)
- [x] No conflicts found

### Task 3.2: Review with Proposals
- [x] Open WebUI proposal uses 8081/8444 (correct)
- [x] AI refactor proposal uses 8447 (correct, now implemented)
- [x] Portal proposal uses 8082/8445 (correct)

---

## Phase 4: Finalization ✅

- [x] Archive this change directory

---

## Files Created

| File | Purpose |
|------|---------|
| `openspec/specs/networking/ports.md` | Port registry document |

## Files Modified

| File | Changes |
|------|---------|
| `openspec/specs/pim/spec.md` | Added References section with port info |
| `openspec/specs/ai/spec.md` | Added References section with port info |

---

## Completion Notes

Port registry established with:
- Web services: 8080-8089 local, 8443-8446 Tailscale
- API services: 11434 (Ollama), 8447-8449 Tailscale
- Media services: 2283 (Immich), 8450-8459 Tailscale

All existing specs updated with cross-references.
