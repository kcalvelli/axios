# Tasks: Port Registry Governance

## Overview

Establish a formal port allocation registry for axios services. This is a documentation-only proposal with no code changes.

---

## Phase 1: Create Port Registry Document

### Task 1.1: Create Directory Structure
- [ ] Create `openspec/specs/networking/` directory if not exists

```bash
mkdir -p openspec/specs/networking
```

### Task 1.2: Write Port Registry Spec
- [ ] Create `openspec/specs/networking/ports.md`
- [ ] Document allocation principles
- [ ] List all current allocations
- [ ] Define reserved ranges

```markdown
# axios Port Registry

## Overview

This document defines port allocations for axios services...

## Current Allocations

### Web Services

| Service | Local Port | Tailscale Port | Status |
|---------|------------|----------------|--------|
| axios-ai-mail | 8080 | 8443 | Active |
| Open WebUI | 8081 | 8444 | Proposed |
| axios Portal | 8082 | 8445 | Planned |
...
```

---

## Phase 2: Update Existing Documentation

### Task 2.1: Update PIM Spec
- [ ] Add port reference to `openspec/specs/pim/spec.md`
- [ ] Link to port registry

### Task 2.2: Update AI Spec
- [ ] Add port references for Ollama API
- [ ] Link to port registry

### Task 2.3: Cross-Reference in CLAUDE.md
- [ ] Add note about port registry location
- [ ] Brief summary of port ranges

---

## Phase 3: Validation

### Task 3.1: Audit Existing Code
- [ ] Verify axios-ai-mail uses documented ports
- [ ] Check for any hardcoded ports that should be documented
- [ ] Ensure no conflicts

### Task 3.2: Review with Proposals
- [ ] Verify Open WebUI proposal uses correct ports
- [ ] Verify AI refactor proposal uses correct ports
- [ ] Verify Portal proposal uses correct ports

---

## Files to Create

| File | Purpose |
|------|---------|
| `openspec/specs/networking/ports.md` | Port registry document |

## Files to Modify

| File | Changes |
|------|---------|
| `openspec/specs/pim/spec.md` | Add port reference |
| `openspec/specs/ai/spec.md` | Add port reference |
| `.claude/project.md` | Add port registry note |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: Create Document | 1 hour |
| Phase 2: Update Docs | 30 min |
| Phase 3: Validation | 30 min |
| **Total** | **~2 hours** |
