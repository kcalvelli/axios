# Tasks: MCP Calendar Integration (via axios-dav)

## Overview

Integrate the external axios-dav flake to provide declarative calendar and contacts sync with MCP server for AI access.

**Note**: The implementation work happens in the axios-dav repository. This tasks file tracks the axios-side integration only.

---

## Phase 1: axios-dav Development (External)

> **Location**: `~/Projects/axios-dav`
> **Tracked in**: `axios-dav/openspec/changes/greenfield-setup/tasks.md`

This phase is completed in the axios-dav repository:
- [ ] Flake foundation
- [ ] vdirsyncer config generation
- [ ] khal config generation
- [ ] Contacts support (khard)
- [ ] MCP server (mcp-dav)
- [ ] Documentation

---

## Phase 2: axios Integration

### Task 2.1: Add Flake Input

**File**: `flake.nix`

- [ ] Add axios-dav input
- [ ] Follow nixpkgs

```nix
inputs.axios-dav = {
  url = "github:kcalvelli/axios-dav";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Task 2.2: Import NixOS Module

**File**: `lib/default.nix` or `modules/pim/default.nix`

- [ ] Import axios-dav NixOS module
- [ ] Conditional on PIM enable flag

```nix
imports = lib.optional (hostCfg.modules.pim or false)
  inputs.axios-dav.nixosModules.default;
```

### Task 2.3: Import Home-Manager Module

**File**: `home/default.nix`

- [ ] Import axios-dav home-manager module
- [ ] Conditional on services.axios-dav.enable

```nix
imports = [
  inputs.axios-dav.homeModules.default
];
```

### Task 2.4: Register MCP Server

**File**: `home/ai/mcp.nix`

- [ ] Add mcp-dav to MCP server configuration
- [ ] Conditional on `services.axios-dav.mcp.enable`

```nix
settings.servers.dav = lib.mkIf (osConfig.services.axios-dav.mcp.enable or false) {
  command = "${pkgs.mcp-dav}/bin/mcp-dav";
  args = [];
};
```

---

## Phase 3: Remove Redundant Code

### Task 3.1: Remove Old Calendar Module

**File**: `home/calendar/default.nix`

- [ ] Remove file entirely (axios-dav provides this)
- [ ] Or rename to legacy/deprecated module

### Task 3.2: Update PIM Module

**File**: `modules/pim/default.nix`

- [ ] Remove vdirsyncer from systemPackages (axios-dav installs it)
- [ ] Keep any DMS-specific calendar integration

### Task 3.3: Update Module Registry

**File**: `home/default.nix`

- [ ] Remove import of old calendar module
- [ ] Ensure axios-dav home module is imported

---

## Phase 4: Documentation

### Task 4.1: Update Module Reference

**File**: `docs/MODULE_REFERENCE.md`

- [ ] Update PIM section to reference axios-dav
- [ ] Add axios-dav configuration examples

### Task 4.2: Update CLAUDE.md

**File**: `CLAUDE.md` (via .claude/project.md)

- [ ] Add mcp-dav to MCP server list
- [ ] Document calendar and contacts tools

### Task 4.3: Update Specs

**Files**: `openspec/specs/pim/spec.md`

- [ ] Update to reflect axios-dav integration
- [ ] Document configuration options

---

## Phase 5: Testing

### Task 5.1: Build Test

- [ ] `nix flake check` passes with axios-dav input
- [ ] Example configurations build with axios-dav

### Task 5.2: Integration Test

- [ ] axios-dav module options available in NixOS config
- [ ] Home-manager options available
- [ ] mcp-dav appears in mcp-cli
- [ ] Calendar tools work from Claude Code

---

## Phase 6: Finalization

### Task 6.1: Code Review

- [ ] Integration follows axios patterns
- [ ] No duplicate functionality
- [ ] Backward compatible (users with manual configs can migrate)

### Task 6.2: Archive Specs

- [ ] Merge spec updates to `openspec/specs/pim/`
- [ ] Move this change directory to archive

---

## Files to Modify

| File | Changes |
|------|---------|
| `flake.nix` | Add axios-dav input |
| `lib/default.nix` | Import axios-dav NixOS module |
| `home/default.nix` | Import axios-dav home module |
| `home/ai/mcp.nix` | Add mcp-dav server |
| `modules/pim/default.nix` | Remove vdirsyncer (now in axios-dav) |
| `home/calendar/default.nix` | Remove (replaced by axios-dav) |
| `docs/MODULE_REFERENCE.md` | Update PIM documentation |

## Files to Create

None - all implementation is in axios-dav repository.

---

## Dependencies

| Dependency | Status |
|------------|--------|
| axios-dav repository created | ✅ Done |
| axios-dav flake foundation | 🔄 In progress |
| axios-dav vdirsyncer config generation | ⏳ Pending |
| axios-dav MCP server | ⏳ Pending |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: axios-dav Development | See axios-dav |
| Phase 2: axios Integration | 2 hours |
| Phase 3: Remove Redundant Code | 1 hour |
| Phase 4: Documentation | 2 hours |
| Phase 5: Testing | 2 hours |
| Phase 6: Finalization | 1 hour |
| **Total (axios side)** | **~8 hours** |

---

## Open Questions

1. **Transition period**: Should we keep old calendar module during migration?
   - **Proposed**: Yes, mark deprecated, remove after axios-dav is stable

2. **Namespace**: `services.axios-dav` or `services.calendar`/`services.contacts`?
   - **Proposed**: `services.axios-dav` for clarity (external flake provides it)
