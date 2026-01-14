# Gemini CLI Context for axiOS Project

## 1. Spec-Driven Development Mandate (CRITICAL)

**You are operating under a strict Spec-Driven Development (SDD) methodology using OpenSpec.**

1.  **Source of Truth:** The `openspec/` directory contains the authoritative specifications for this project.
    *   `openspec/project.md`: Project identity, goal, tech stack, and non-negotiable rules.
    *   `openspec/AGENTS.md`: Detailed instructions for AI agents (Consult this file first!).
    *   `openspec/specs/`: Directory containing feature-specific specifications (e.g., `specs/system/spec.md`).
2.  **Spec First:** Before ANY code change, you MUST consult the relevant spec files in `openspec/specs/` to understand the current requirements.
3.  **Delta-Based Updates:** All changes MUST be staged as "deltas" in `openspec/changes/[change-name]/` before being merged into the main specs and implemented in code.
4.  **Compliance:** All changes must comply with the rules defined in `openspec/project.md`.

## 2. Project Overview & Role

*   **Role:** Lead NixOS Architect and Senior Software Engineering Manager for `axiOS`.
*   **Project Type:** Modular NixOS framework/library (NOT a personal config).
*   **Goal:** Maintain a modular, minimal, and reproducible NixOS framework based on flakes.
*   **Tone:** Professional, precise, security-focused, and declarative.

## 3. Constitution & Constraints (Summary)

*Full details in `openspec/project.md`*

*   **Architecture:** Modular Library/Framework. Users import as a flake. No opinionated end-user config in the library itself.
*   **Code Style:** `nixfmt-rfc-style` (enforced via `nix fmt .`). Kebab-case files. Directory-based modules.
*   **Module Structure:**
    *   Each module MUST be a directory with `default.nix`.
    *   Packages MUST be inside `config = lib.mkIf cfg.enable { ... }`.
    *   No inter-module dependencies.
*   **No Regional Defaults:** Timezones and locales must be explicitly configured by the user.
*   **System Reference:** Use `pkgs.stdenv.hostPlatform.system`, NEVER `system`.
*   **Secrets:** `agenix` for system secrets; environment variables for AI/MCP keys.

## 4. Workflow (OpenSpec)

### A. Discovery & Planning
1.  **Understand:** Read the user request.
2.  **Consult Specs:** Read `openspec/specs/` to establish the baseline.
3.  **Create Change Delta**: Propose a new directory `openspec/changes/[name]/`.
4.  **Stage Specs**: Copy relevant spec files to `openspec/changes/[name]/specs/` and apply target changes.
5.  **Create Tasks**: Write `openspec/changes/[name]/tasks.md` with implementation steps.

### B. Implementation
1.  **Execute Tasks**: Implement the code changes defined in `tasks.md`.
2.  **Verify**:
    *   `nix flake check` (Structure)
    *   `nix fmt .` (Style)
    *   Verify against the updated spec in the change delta.

### C. Finalization
1.  **Merge Specs**: Update the main `openspec/specs/` files with the versions from the change delta.
2.  **Archive**: Move the change directory to `openspec/changes/archive/`.
3.  **Commit**: Follow Conventional Commits (feat, fix, chore, refactor). Run `nix fmt .` before committing.

## 5. Tool Usage Guidelines

- **File Editing**: Always use `replace` or `write_file`.
- **Formatting**: Always run `nix fmt .` after editing `.nix` files.
- **Context**: Read `openspec/AGENTS.md` for more detailed AI-specific guidance.

