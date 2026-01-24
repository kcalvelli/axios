# Tasks: AI CLI Tools Additions

## Overview

This is a living task list for the blanket AI CLI tools proposal. Tasks are added as new tools are identified for integration.

---

## Pending Additions

### goose-cli

Block's open-source AI coding assistant with multi-provider support.

- [x] Verify goose-cli is available in nixpkgs (using llm-agents.nix for bleeding edge)
- [x] Add flake input for llm-agents.nix
- [x] Add to `modules/ai/default.nix` package list (with services.ai.goose.enable option)
- [x] Generate `~/.config/goose/config.yaml` with all MCP servers
- [x] Add shell aliases (axios-goose, axgo)
- [ ] Test basic functionality after rebuild
- [ ] Update `openspec/specs/ai/spec.md` CLI Coding Agents section

**References:**
- https://github.com/block/goose
- https://block.github.io/goose/
- https://github.com/numtide/llm-agents.nix

---

## Completed Additions

_None yet (goose-cli pending user testing)_

---

## Notes

- Each tool addition should update the "Tracked Additions" table in `proposal.md`
- Move completed tasks to the "Completed Additions" section with date
- For tools requiring significant configuration, consider a dedicated proposal instead
