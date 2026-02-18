## Context

axiOS provides curated application sets within its desktop and development modules. An audit against the target persona (AI-enabled software engineers and power users) identified gaps: missing database clients, API testing tools, structural diff, system/network diagnostics, and no office suite. Additionally, three browsers are installed but undocumented, and Hoppscotch exists locally but isn't distributed as a default PWA.

The existing module structure cleanly accommodates these additions — packages go inline within `mkIf` blocks in their respective modules.

## Goals / Non-Goals

**Goals:**
- Add missing CLI tools to development module (pgcli, litecli, httpie, difftastic, btop, mtr, dog)
- Add libreoffice-qt to the desktop module for office productivity
- Add Hoppscotch as a default PWA via the existing `axios.pwa.apps` system
- Update APPLICATIONS.md to accurately reflect all installed applications

**Non-Goals:**
- Replacing nil with nixd (separate change, needs testing)
- Adding heavyweight opt-in tools like wireshark or DBeaver
- Docker/podman compatibility layer (separate change)
- LobeHub / local LLM chat UI (investigated and rejected — v2 requires PostgreSQL 17 + S3 server deployment; target persona already has CLI-based LLM access via ollama, opencode, claude-code, gemini, avante.nvim)

## Decisions

### D1: CLI tools placement — all in development module

**Decision**: Add btop, mtr, and dog to the development module alongside pgcli, litecli, httpie, and difftastic.

**Rationale**: These are developer/power-user tools. The desktop module is for GUI applications and Wayland infrastructure. The development module already houses CLI tools (bat, eza, jq, fzf). Keeping all CLI diagnostic tools together is consistent.

**Alternatives considered**:
- Split btop/mtr/dog into desktop module: Breaks the CLI-vs-GUI boundary. Desktop module would accumulate unrelated CLI tools.
- Create a new `cli-tools` module: Over-engineering — the development module already serves this purpose.

### D2: Hoppscotch as default PWA — promote from downstream to `pwa-defs.nix`

**Decision**: Add Hoppscotch to `pkgs/pwa-apps/pwa-defs.nix` (the axios default PWA definitions) and copy the icon from the local config (`~/.config/nixos_config/pwa-icons/hoppscotch.png`) into `home/resources/pwa-icons/`. Downstream user configs can then remove their duplicate Hoppscotch entries since `mkDefault` from the defaults will provide it automatically.

**Rationale**: The PWA default system (`pwa-defs.nix` + `home/resources/pwa-icons/`) is the single source of truth for axios-shipped PWAs. Adding Hoppscotch here follows the exact same pattern as Google Drive, YouTube, Element, and all other defaults. This avoids duplicating the definition across user configs and keeps the icon in the canonical location.

**Alternatives considered**:
- Add to `home/desktop/pwa-apps.nix` directly: Wrong layer — `pwa-apps.nix` is the module logic; `pwa-defs.nix` is where default app definitions live.
- Self-hosted Hoppscotch: Heavyweight (Docker/database), out of scope for a development tool.

### D3: dog vs doggo

**Decision**: Use `dog` (nixpkgs: `dog`).

**Rationale**: `dog` is available in nixpkgs and provides the needed functionality. If upstream maintenance stalls, swapping to `doggo` is a trivial single-line change. No need to preemptively choose the alternative.

### D4: libreoffice-qt variant

**Decision**: Use `libreoffice-qt` (not `libreoffice-fresh` or `libreoffice-still`).

**Rationale**: The `-qt` variant integrates with Qt theming (Material You via DMS). The desktop module already uses Qt-based applications (Dolphin, Okular, Qalculate-qt) and ships Qt6ct/Qt5ct for theme management. Qt integration provides visual consistency.

## Risks / Trade-offs

- **Closure size increase from libreoffice-qt** (~800MB) → Document opt-out pattern in APPLICATIONS.md. Users can remove via `environment.systemPackages = lib.mkForce (lib.filter ...)` or simply accept the size.

- **dog upstream maintenance** → Active but slow. Mitigation: doggo is a drop-in replacement if needed. Single-line swap.

- **btop/mtr require no special configuration** → Low risk. Standard CLI tools from nixpkgs.

## Open Questions

None — all decisions are straightforward applications of existing patterns.
