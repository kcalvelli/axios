# Tasks: Add OpenSpec CLI Package

Create a Nix derivation for the OpenSpec CLI tool and add it to the system configuration.

## Task List

- [x] **Package Creation**
    - [x] Create `pkgs/openspec/default.nix` using `pnpm` hooks.
    - [x] Fetch the source from `https://github.com/Fission-AI/OpenSpec`.
    - [x] Determine the correct version/tag (`v0.18.0`).
- [x] **Integration**
    - [x] Verify the package build with `nix build .#openspec`.
    - [x] Add `openspec` to `modules/ai/default.nix` system packages.
- [x] **Spec Update**
    - [x] Update `openspec/specs/ops/spec.md` to include `openspec` as a core tool.

## Completion Criteria
1. `openspec` command is available in the shell.
2. The package is managed via Nix and builds successfully.
3. Documentation/Specs reflect the tool's availability.
