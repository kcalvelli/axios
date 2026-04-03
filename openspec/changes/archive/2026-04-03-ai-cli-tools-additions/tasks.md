# Tasks: AI CLI Tools Additions

## Overview

This is a living task list for the blanket AI CLI tools proposal. Tasks are added as new tools are identified for integration.

---

## Pending Additions

_None_

---

## Completed Additions

### goose-cli (REMOVED)

Block's open-source AI coding assistant. Was added 2025-01-24 but removed 2025-01-26 as redundant with claude-code and gemini-cli. The tool quality was poor and didn't add value beyond existing tools.

- [x] ~~Verify goose-cli is available in nixpkgs~~ (Removed)
- [x] ~~Add flake input for llm-agents.nix~~ (Removed)
- [x] ~~Add to modules/ai/default.nix~~ (Removed)
- [x] ~~Generate goose config~~ (Removed)
- [x] ~~Add shell aliases~~ (Removed)

---

## Notes

- Each tool addition should update the "Tracked Additions" table in `proposal.md`
- Move completed tasks to the "Completed Additions" section with date
- For tools requiring significant configuration, consider a dedicated proposal instead
