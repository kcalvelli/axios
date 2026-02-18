## Context

axiOS provides curated application sets within its desktop, development, and AI modules. An audit against the target persona (AI-enabled software engineers and power users) identified gaps: missing database clients, API testing tools, structural diff, system/network diagnostics, office suite, and no local LLM chat UI. Additionally, three browsers are installed but undocumented, and Hoppscotch exists locally but isn't distributed as a default PWA.

The existing module structure cleanly accommodates these additions — packages go inline within `mkIf` blocks in their respective modules. The only non-trivial work is packaging LobeHub as an AppImage derivation and wiring Hoppscotch into the `axios.pwa.apps` system.

## Goals / Non-Goals

**Goals:**
- Add missing CLI tools to development module (pgcli, litecli, httpie, difftastic, btop, mtr, dog)
- Add libreoffice-qt to the desktop module for office productivity
- Add Hoppscotch as a default PWA via the existing `axios.pwa.apps` system
- Package LobeHub desktop app as a custom Nix derivation and install it when `services.ai.local.enable = true`
- Update APPLICATIONS.md to accurately reflect all installed applications

**Non-Goals:**
- Replacing nil with nixd (separate change, needs testing)
- Adding heavyweight opt-in tools like wireshark or DBeaver
- LobeHub server-side deployment (AppImage desktop app is sufficient)
- Docker/podman compatibility layer (separate change)

## Decisions

### D1: LobeHub packaging via `appimageTools.wrapType2`

**Decision**: Package LobeHub using `appimageTools.wrapType2` with Wayland flags.

**Rationale**: LobeHub distributes official AppImage releases. `wrapType2` extracts and wraps the Electron app with proper library paths. This avoids maintaining a complex build-from-source derivation for an Electron app with a fast release cadence.

**Alternatives considered**:
- Build from source: Too complex — Electron + Next.js app with ~1200 dependencies. Maintenance burden far exceeds value.
- Flatpak: axiOS has Flatpak support but custom packages should be Nix-native when feasible for reproducibility.

**Wayland support**: Pass `--ozone-platform=wayland` and `--enable-wayland-ime` via `makeWrapper` to ensure native Wayland rendering under Niri.

### D2: CLI tools placement — all in development module

**Decision**: Add btop, mtr, and dog to the development module alongside pgcli, litecli, httpie, and difftastic.

**Rationale**: These are developer/power-user tools. The desktop module is for GUI applications and Wayland infrastructure. The development module already houses CLI tools (bat, eza, jq, fzf). Keeping all CLI diagnostic tools together is consistent.

**Alternatives considered**:
- Split btop/mtr/dog into desktop module: Breaks the CLI-vs-GUI boundary. Desktop module would accumulate unrelated CLI tools.
- Create a new `cli-tools` module: Over-engineering — the development module already serves this purpose.

### D3: Hoppscotch as default PWA — promote from downstream to `pwa-defs.nix`

**Decision**: Add Hoppscotch to `pkgs/pwa-apps/pwa-defs.nix` (the axios default PWA definitions) and copy the icon from the local config (`~/.config/nixos_config/pwa-icons/hoppscotch.png`) into `home/resources/pwa-icons/`. Downstream user configs can then remove their duplicate Hoppscotch entries since `mkDefault` from the defaults will provide it automatically.

**Rationale**: The PWA default system (`pwa-defs.nix` + `home/resources/pwa-icons/`) is the single source of truth for axios-shipped PWAs. Adding Hoppscotch here follows the exact same pattern as Google Drive, YouTube, Element, and all other defaults. This avoids duplicating the definition across user configs and keeps the icon in the canonical location.

**Alternatives considered**:
- Add to `home/desktop/pwa-apps.nix` directly: Wrong layer — `pwa-apps.nix` is the module logic; `pwa-defs.nix` is where default app definitions live.
- Self-hosted Hoppscotch: Heavyweight (Docker/database), out of scope for a development tool.

### D4: LobeHub gating — `services.ai.local.enable`

**Decision**: Install LobeHub only when `services.ai.local.enable = true` (either server or client role).

**Rationale**: LobeHub connects to Ollama. Without the local AI stack enabled, LobeHub has nothing to connect to (unless the user manually configures external providers, which they can do via extraConfig). Gating behind `local.enable` keeps the dependency chain clean.

### D5: dog vs doggo

**Decision**: Use `dog` (nixpkgs: `dog`).

**Rationale**: `dog` is available in nixpkgs and provides the needed functionality. If upstream maintenance stalls, swapping to `doggo` is a trivial single-line change. No need to preemptively choose the alternative.

### D6: libreoffice-qt variant

**Decision**: Use `libreoffice-qt` (not `libreoffice-fresh` or `libreoffice-still`).

**Rationale**: The `-qt` variant integrates with Qt theming (Material You via DMS). The desktop module already uses Qt-based applications (Dolphin, Okular, Qalculate-qt) and ships Qt6ct/Qt5ct for theme management. Qt integration provides visual consistency.

## Risks / Trade-offs

- **Closure size increase from libreoffice-qt** (~800MB) → Document opt-out pattern in APPLICATIONS.md. Users can remove via `environment.systemPackages = lib.mkForce (lib.filter ...)` or simply accept the size.

- **LobeHub AppImage Wayland compatibility** → Electron apps occasionally need extra flags for Niri. Mitigation: ship `--ozone-platform=wayland` and `--enable-wayland-ime` flags. Test on Niri before shipping.

- **LobeHub pglite crash (issue #8656)** → Marked fixed in v2.1.30+. Mitigation: pin to v2.1.30 or later; verify during implementation.

- **LobeHub fast release cadence** → Hash updates needed periodically. Mitigation: pin a stable release; update hash in flake-lock-updater cadence or as-needed.

- **dog upstream maintenance** → Active but slow. Mitigation: doggo is a drop-in replacement if needed. Single-line swap.

- **btop/mtr require no special configuration** → Low risk. Standard CLI tools from nixpkgs.

## Open Questions

None — all decisions are straightforward applications of existing patterns.
