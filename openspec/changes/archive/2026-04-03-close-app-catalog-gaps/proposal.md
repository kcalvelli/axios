## Why

axiOS targets AI-enabled software engineers and power users, but an audit of the application catalog reveals functional gaps that force users into `extraConfig` on day one. Three browsers are installed but undocumented, essential development CLI tools (database clients, API testing, structural diffs) are missing, and the Hoppscotch PWA exists locally but isn't part of the distribution. Closing these gaps delivers a complete working environment out of the box.

## What Changes

- **Desktop module**: Add `libreoffice-qt` for office productivity; add Hoppscotch as a default PWA via the existing `axios.pwa.apps` system
- **Development module**: Add `pgcli`, `litecli`, `httpie`, and `difftastic` as standard development CLI tools
- **Desktop/Development modules**: Add `btop`, `mtr`, and `dog` as modern system/network diagnostic CLI tools
- **Documentation**: Update `APPLICATIONS.md` to document browsers (Brave, Chromium, Chrome), correct category counts, and catalog all new additions

## Capabilities

### New Capabilities
*(none)*

### Modified Capabilities
- `desktop`: Add libreoffice-qt to curated application set; add Hoppscotch as default PWA; document existing browser installs in catalog
- `development`: Add pgcli, litecli, httpie, difftastic, btop, mtr, dog to standard CLI tooling

## Impact

- **Modules affected**: `modules/desktop/default.nix`, `modules/development/default.nix`
- **PWA config**: New Hoppscotch entry in `axios.pwa.apps` defaults
- **Closure size**: `libreoffice-qt` adds ~800MB to desktop closure; document opt-out via `environment.systemPackages` override
- **Documentation**: `docs/APPLICATIONS.md` updated with corrected counts and new entries
- **Dependencies**: No new flake inputs; all packages from nixpkgs

## Out of Scope

- **LobeHub / local LLM chat UI**: Investigated and rejected. LobeHub v2 requires a full server deployment (PostgreSQL 17 + S3 storage), and the target persona already has comprehensive CLI-based LLM access (ollama CLI, opencode, claude-code, gemini, avante.nvim). A GUI chat UI doesn't fill a meaningful gap for AI-enabled software engineers.
