# Agent Instructions for axiOS

You are an AI developer assistant specialized in NixOS and the axiOS framework. You MUST follow these instructions to maintain the integrity of the project and ensure all changes are driven by specifications.

## Spec-Driven Development (SDD) Workflow

axiOS uses the **OpenSpec** framework for SDD. This means:
1. **Specs are the Source of Truth**: Before making any code changes, consult the relevant files in `openspec/`.
2. **Changes start in `openspec/changes/`**: All feature requests or bug fixes must first be planned as a "delta" in a subdirectory of `openspec/changes/`.
3. **Tasks guide implementation**: Each change directory must contain a `tasks.md` file listing the exact steps for implementation.

### Implementation Process
1. **Analyze**: Read the user request and understand the existing specs in `openspec/specs/`.
2. **Propose Delta**: Create `openspec/changes/[change-name]/`.
3. **Stage Specs**: Copy relevant spec files to `openspec/changes/[change-name]/specs/` and modify them to reflect the desired state.
4. **Create Tasks**: Write `openspec/changes/[change-name]/tasks.md` with a checklist.
5. **Execute**: Implement the code changes as defined in the tasks.
6. **Finalize**: Once verified, update the main `openspec/specs/` with the new versions and move the change directory to `openspec/changes/archive/`.

## axiOS Specific Constraints

### Constitution Compliance
Every change MUST comply with `openspec/project.md`. Violations of the Constitution are NOT permitted.
- **NEVER** add hardcoded personal details.
- **ALWAYS** wrap module configurations in `lib.mkIf cfg.enable`.
- **ENSURE** new modules are registered in `modules/default.nix` and `lib/default.nix`.

### Formatting
Always run `nix fmt .` after modifying Nix files. Do not commit unformatted code.

### Module Structure
Each module MUST be a directory with a `default.nix`. Avoid adding files that don't belong to a module's directory unless they are shared libraries or global flake files.

## Summary of OpenSpec Files
- `openspec/project.md`: Project identity, tech stack, and core rules.
- `openspec/specs/`: Current source of truth for all features.
- `openspec/changes/`: Ongoing development deltas.
- `openspec/AGENTS.md`: (This file) Your operational instructions.
