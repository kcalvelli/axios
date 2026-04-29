## Context

Cairn's desktop module unconditionally installs Brave Stable, Brave Nightly, and Chrome when `desktop.enable = true`. The AI module defaults both `services.ai.claude.enable` and `services.ai.gemini.enable` to `true`, and installs `claude-monitor`, `spec-kit`, and `openspec` unconditionally. Most users want one browser and one AI ecosystem.

The PWA system (`cairn.pwa`) is already properly gated — it defaults to Chromium as its backend and only installs the browser packages it actually needs. This change does not touch PWA plumbing.

## Goals / Non-Goals

**Goals:**
- Make browser installation opt-in per channel, with Brave stable as the only default
- Make AI ecosystem selection explicit (Claude, Gemini both default false)
- Move workflow tools (`spec-kit`, `openspec`) and Claude-specific tools (`claude-monitor`) behind appropriate flags
- Reduce default closure size for desktop and AI-enabled hosts

**Non-Goals:**
- Changing the PWA browser backend system (already well-designed)
- Changing the local LLM stack (`services.ai.local`)
- Changing MCP server configuration
- Modifying the normie profile's relationship with AI modules
- Adding browser-level configuration options beyond enable flags (extensions, args already exist)

## Decisions

### 1. Browser flags live under `desktop.browsers`

New options namespace: `desktop.browsers.{brave,braveNightly,braveBeta,braveOrigin,chrome}.enable`.

Brave stable defaults to `true` — a desktop without a browser is useless, and Brave is the cairn default. All others default to `false`.

**Alternative considered**: Single `desktop.browser` enum — rejected because users legitimately run multiple browsers (e.g., Brave daily + Chrome for debugging).

**Alternative considered**: All browsers default `false` — rejected because a fresh cairn install with `desktop.enable = true` should have a working browser out of the box.

### 2. Chromium is not a `desktop.browsers` flag

Chromium is the default PWA backend. It gets installed by the PWA module when needed, not by the browser module. Adding a standalone `desktop.browsers.chromium.enable` would create confusion about whether it controls the PWA backend. It doesn't — `cairn.pwa.browser` does.

### 3. Browser args exposure stays unified

`desktop.browserArgs` continues to expose GPU-aware flags for all browser types (brave, chromium, google-chrome) regardless of which browsers are enabled. The PWA module needs args for its configured backend even if that browser isn't a "standalone" install.

### 4. Claude and Gemini default to false

Both `services.ai.claude.enable` and `services.ai.gemini.enable` flip from `default = true` to plain `mkEnableOption` (default false). This is a breaking change — downstream configs that relied on the implicit default will need explicit enable lines.

**Alternative considered**: Keep defaults at `true` — rejected because it defeats the purpose. Users who want both ecosystems can enable both explicitly.

### 5. Workflow tools get their own flag

New option: `services.ai.workflow.enable` (default `false`). Controls `spec-kit` and `openspec`. These are opinionated dev workflow tools — most AI users don't use spec-driven development.

### 6. claude-monitor moves under Claude flag

`claude-monitor` is Claude-specific (monitors Claude Code sessions). It belongs under `services.ai.claude.enable`, not as an unconditional install.

### 7. whisper-cpp stays unconditional

`whisper-cpp` is vendor-neutral speech-to-text. It stays as the only unconditional package under `services.ai.enable`.

## Risks / Trade-offs

- **Breaking downstream configs** → Mitigation: Clear error messages from NixOS evaluation when expected packages are missing. Document migration in CHANGELOG.
- **Init script needs updating** → The init script and templates should prompt for browser and AI ecosystem choices. This is additive work but not blocking.
- **Brave preview channels share a single flake input** → The `brave-browser-previews` NixOS module is already imported unconditionally via `inputs.brave-browser-previews.nixosModules.default`. The individual `programs.brave-{nightly,beta,origin-nightly}.enable` flags from that module are only set when the corresponding `desktop.browsers` flag is true. No new imports needed.
