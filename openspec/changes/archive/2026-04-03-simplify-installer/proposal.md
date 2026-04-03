## Why

The current installer uses raw ANSI prompts, has nested questions (virtualization sub-options inside a virtualization toggle), and cannot add hosts to an existing configuration. Users on a second machine must manually edit their flake.nix to add a new host entry. The installer also lacks a `--help` flag for CI compatibility.

## What Changes

- Replace all ANSI prompt helpers with **gum** (charmbracelet/gum) for a modern TUI
- Add **dual-mode flow**: new configuration vs add host to existing config
- **Flatten nested questions** into a single multi-select screen (no more virt sub-toggles)
- Add `--help` flag, Ctrl-C trap, and gum prerequisite check
- Auto git-init + commit in Mode A; auto git-commit in Mode B
- Update flake.nix wrapper to provide gum and all dependencies on PATH

## Capabilities

### New Capabilities
- `add-host-mode`: Clone an existing config repo, scan hosts/users, add a new host with user assignment, auto-insert into flake.nix
- `gum-tui`: Modern styled TUI with bordered boxes, spinners, and multi-select

### Modified Capabilities
- `axios-config-generator`: Rewritten with gum TUI, flattened feature selection, auto git init + commit

## Impact

- `scripts/init-config.sh` — major rewrite
- `flake.nix` — wrapper updated to provide gum + dependencies via makeBinPath
- No changes to templates, lib, or modules — generated output format is identical
