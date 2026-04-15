# Tasks: MCP Calendar Integration (via cairn-dav)

## Overview

Integrate the external cairn-dav flake to provide declarative calendar and contacts sync with MCP server for AI access.

**Note**: The implementation work happens in the cairn-dav repository. This tasks file tracks the cairn-side integration only.

---

## Phase 1: cairn-dav Development (External)

> **Location**: `~/Projects/cairn-dav`
> **Tracked in**: `cairn-dav/openspec/changes/greenfield-setup/tasks.md`

This phase is completed in the cairn-dav repository:
- [ ] Flake foundation
- [ ] vdirsyncer config generation
- [ ] khal config generation
- [ ] Contacts support (khard)
- [ ] MCP server (mcp-dav)
- [ ] Documentation

---

## Phase 2: cairn Integration

### Task 2.1: Add Flake Input

**File**: `flake.nix`

- [ ] Add cairn-dav input
- [ ] Follow nixpkgs

```nix
inputs.cairn-dav = {
  url = "github:kcalvelli/cairn-dav";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Task 2.2: Import NixOS Module

**File**: `lib/default.nix` or `modules/pim/default.nix`

- [ ] Import cairn-dav NixOS module
- [ ] Conditional on PIM enable flag

```nix
imports = lib.optional (hostCfg.modules.pim or false)
  inputs.cairn-dav.nixosModules.default;
```

### Task 2.3: Import Home-Manager Module

**File**: `home/default.nix`

- [ ] Import cairn-dav home-manager module
- [ ] Conditional on services.cairn-dav.enable

```nix
imports = [
  inputs.cairn-dav.homeModules.default
];
```

### Task 2.4: Register MCP Server

**File**: `home/ai/mcp.nix`

- [ ] Add mcp-dav to MCP server configuration
- [ ] Conditional on `services.cairn-dav.mcp.enable`

```nix
settings.servers.dav = lib.mkIf (osConfig.services.cairn-dav.mcp.enable or false) {
  command = "${pkgs.mcp-dav}/bin/mcp-dav";
  args = [];
};
```

---

## Phase 3: Remove Redundant Code

### Task 3.1: Remove Old Calendar Module

**File**: `home/calendar/default.nix`

- [ ] Remove file entirely (cairn-dav provides this)
- [ ] Or rename to legacy/deprecated module

### Task 3.2: Update PIM Module

**File**: `modules/pim/default.nix`

- [ ] Remove vdirsyncer from systemPackages (cairn-dav installs it)
- [ ] Keep any DMS-specific calendar integration

### Task 3.3: Update Module Registry

**File**: `home/default.nix`

- [ ] Remove import of old calendar module
- [ ] Ensure cairn-dav home module is imported

---

## Phase 4: Documentation

### Task 4.1: Update Module Reference

**File**: `docs/MODULE_REFERENCE.md`

- [ ] Update PIM section to reference cairn-dav
- [ ] Add cairn-dav configuration examples

### Task 4.2: Update CLAUDE.md

**File**: `CLAUDE.md` (via .claude/project.md)

- [ ] Add mcp-dav to MCP server list
- [ ] Document calendar and contacts tools

### Task 4.3: Update Specs

**Files**: `openspec/specs/pim/spec.md`

- [ ] Update to reflect cairn-dav integration
- [ ] Document configuration options

---

## Phase 5: Testing

### Task 5.1: Build Test

- [ ] `nix flake check` passes with cairn-dav input
- [ ] Example configurations build with cairn-dav

### Task 5.2: Integration Test

- [ ] cairn-dav module options available in NixOS config
- [ ] Home-manager options available
- [ ] mcp-dav appears in mcp-cli
- [ ] Calendar tools work from Claude Code

---

## Phase 6: Finalization

### Task 6.1: Code Review

- [ ] Integration follows cairn patterns
- [ ] No duplicate functionality
- [ ] Backward compatible (users with manual configs can migrate)

### Task 6.2: Archive Specs

- [ ] Merge spec updates to `openspec/specs/pim/`
- [ ] Move this change directory to archive

---

## Files to Modify

| File | Changes |
|------|---------|
| `flake.nix` | Add cairn-dav input |
| `lib/default.nix` | Import cairn-dav NixOS module |
| `home/default.nix` | Import cairn-dav home module |
| `home/ai/mcp.nix` | Add mcp-dav server |
| `modules/pim/default.nix` | Remove vdirsyncer (now in cairn-dav) |
| `home/calendar/default.nix` | Remove (replaced by cairn-dav) |
| `docs/MODULE_REFERENCE.md` | Update PIM documentation |

## Files to Create

None - all implementation is in cairn-dav repository.

---

## Dependencies

| Dependency | Status |
|------------|--------|
| cairn-dav repository created | ✅ Done |
| cairn-dav flake foundation | 🔄 In progress |
| cairn-dav vdirsyncer config generation | ⏳ Pending |
| cairn-dav MCP server | ⏳ Pending |

---

## Estimated Effort

| Phase | Effort |
|-------|--------|
| Phase 1: cairn-dav Development | See cairn-dav |
| Phase 2: cairn Integration | 2 hours |
| Phase 3: Remove Redundant Code | 1 hour |
| Phase 4: Documentation | 2 hours |
| Phase 5: Testing | 2 hours |
| Phase 6: Finalization | 1 hour |
| **Total (cairn side)** | **~8 hours** |

---

## Open Questions

1. **Transition period**: Should we keep old calendar module during migration?
   - **Proposed**: Yes, mark deprecated, remove after cairn-dav is stable

2. **Namespace**: `services.cairn-dav` or `services.calendar`/`services.contacts`?
   - **Proposed**: `services.cairn-dav` for clarity (external flake provides it)
