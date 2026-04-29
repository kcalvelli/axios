## Why

Cairn installs three browsers and two full AI ecosystems by default. Most users want one browser and are locked into a single AI vendor. The current defaults force unnecessary packages on every desktop and AI-enabled host, increasing closure size and evaluation time for things people don't use.

## What Changes

- Add individual browser enable flags under `desktop.browsers`:
  - `brave.enable` (default `true`) — Brave stable, the cairn default browser
  - `braveNightly.enable` (default `false`) — Brave Nightly channel
  - `braveBeta.enable` (default `false`) — Brave Beta channel
  - `braveOrigin.enable` (default `false`) — Brave Origin (new experimental channel)
  - `chrome.enable` (default `false`) — Google Chrome
  Users get one good browser out of the box and opt into extras if they want them. All Brave preview channels come from the `brave-browser-previews` flake input. Chromium remains an implicit dependency of the PWA module only — not a standalone browser install.
- **BREAKING**: Change `services.ai.claude.enable` default from `true` to `false`. Users must explicitly enable Claude tooling.
- **BREAKING**: Change `services.ai.gemini.enable` default from `true` to `false`. Users must explicitly enable Gemini tooling.
- Move `claude-monitor` under `services.ai.claude.enable` (it's a Claude-specific monitoring tool).
- Move `spec-kit` and `openspec` under a new `services.ai.workflow.enable` flag (default `false`). These are opinionated dev workflow tools, not core AI infrastructure.
- `whisper-cpp` stays unconditional under `services.ai.enable` — it's a generic speech-to-text tool with no vendor lock-in.

## Capabilities

### New Capabilities

_None — no new capabilities introduced._

### Modified Capabilities

- `desktop`: Browser installation becomes opt-in via individual enable flags instead of unconditional.
- `ai`: Claude and Gemini ecosystems become opt-in. Workflow tools (`spec-kit`, `openspec`) get their own flag. `claude-monitor` moves under Claude flag.

## Impact

- **Downstream configs**: Any host with `modules.desktop = true` that expects Chrome or Brave Nightly will need to add explicit browser enable flags. Brave stable remains the default. Any host with `modules.ai = true` that expects Claude or Gemini tools will need to add `services.ai.claude.enable = true` or `services.ai.gemini.enable = true`.
- **Init script**: `scripts/init-config.sh` and templates may need updating to prompt for browser and AI ecosystem choices.
- **Documentation**: `docs/MODULE_REFERENCE.md` and `docs/APPLICATIONS.md` will need updates reflecting the new flags.
- **No runtime impact**: Pure additive option changes — existing functionality is preserved, just not default-on.
