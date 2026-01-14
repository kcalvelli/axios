# Tasks: Spec Review & Update (Jan 2026)

This task involves reviewing the legacy specs migrated from `spec-kit-baseline` and updating them to reflect the actual implementation in the `axios` codebase.

## Task List

- [x] **AI Spec Review**
    - [x] Remove outdated `copilot-cli` reference.
    - [x] Add details about `claude-code-acp`, `claude-code-router`, and `claude-desktop`.
    - [x] Document the `systemPrompt` management options (`extraInstructions`).
    - [x] Document `mcp-cli` and token reduction strategy.
    - [x] Add `ollamaReverseProxy` details.
- [x] **System Spec Review**
    - [x] Add `Memory Tuning` (Zram, swappiness) from `memory.nix`.
    - [x] Add `Performance Tuning` (Network optimizations) from `boot.nix`.
    - [x] Clarify `Secure Boot` status and `Lanzaboote` integration.
- [x] **Services Spec Review**
    - [x] Update `Immich` section to include `subdomain` and `mediaLocation` options.
    - [x] Add `Ollama` to the list of services using the Caddy Route Registry.
    - [x] Clarify `Samba` and `Google Drive Sync` implementation details.
- [x] **Desktop Spec Review**
    - [x] Verify `DMS` (DankMaterialShell) integration details (runs as systemd service).
    - [x] Document `add-pwa` script and automated project structure detection.
    - [x] Ensure `PIM` module details match actual available clients (Geary/Evolution).
- [x] **Development Spec Review**
    - [x] Add `inotify` tuning details.
    - [x] List core editors and tools actually provided (VSCode, gh, etc.).
- [x] **Operational Spec Review**
    - [x] Verify CI/CD pipeline stages and triggers.
    - [x] Document `init` script's new `hardwareConfigPath` pattern.

## Completion Criteria
1. All specs in `openspec/specs/` accurately represent the current code.
2. No outdated or misleading information remains in the specs.
3. Conventional Commits are used for the merge.
