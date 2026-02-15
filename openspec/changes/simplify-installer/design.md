## Context

The axiOS installer (`scripts/init-config.sh`) generates a downstream NixOS configuration. It currently uses raw ANSI escape codes for prompts and has no way to add a host to an existing configuration. The downstream config format was recently standardized (multi-user, canonical directory layout with `hosts/` and `users/`), and the installer needs to support both fresh setups and adding machines to existing configs.

## Goals / Non-Goals

**Goals:**
- Modern TUI via gum (styled boxes, spinners, multi-select)
- Dual-mode: new configuration (Mode A) and add host to existing config (Mode B)
- Flatten all nested questions into a single multi-select for features
- Auto git-init + commit in Mode A; auto git-commit in Mode B
- `--help` flag for CI compatibility
- Generated output format stays identical to current

**Non-Goals:**
- Changing templates or generated file format
- Adding new module types
- Supporting non-NixOS systems beyond limited detection

## Decisions

- **TUI Library**: gum (already in nixpkgs, provided via flake.nix wrapper PATH)
- **Mode Selection**: Explicit user choice at startup (no auto-detection of existing config)
- **Feature Selection**: Single `gum choose --no-limit` replaces individual yes/no prompts and nested virt sub-options; `ENABLE_VIRT` derived from whether either virt option is selected
- **Mode B User Assignment**: Users select from existing `users/*.nix` files via multi-select; first selected = primary admin; option to create new users
- **Mode B flake.nix Insertion**: Find last `mkHost` line, insert new entry after it via sed; duplicate detection prevents double-insertion
- **Dependencies**: All tools provided via `pkgs.lib.makeBinPath` in flake.nix wrapper (gum, git, coreutils, gnugrep, gnused, pciutils, util-linux, gawk)

## Risks / Trade-offs

- **Risk**: gum not available if user runs script directly → **Mitigation**: prerequisite check with clear error message pointing to `nix run`
- **Risk**: Mode B flake.nix insertion could break non-standard flake formats → **Mitigation**: fallback message with manual instructions if mkHost pattern not found
- **Trade-off**: Flat multi-select means users see virt options even if they don't want virt → acceptable, as skipping is trivial
