## 1. Browser Flags

- [x] 1.1 Add `desktop.browsers` options in `modules/desktop/browsers.nix`: `brave.enable` (default true), `braveNightly.enable`, `braveBeta.enable`, `braveOrigin.enable`, `chrome.enable` (all default false)
- [x] 1.2 Gate Brave stable installation (`programs.brave`, home-manager config) behind `desktop.browsers.brave.enable`
- [x] 1.3 Gate Brave Nightly installation (`programs.brave-nightly`) behind `desktop.browsers.braveNightly.enable`
- [x] 1.4 Gate Brave Beta installation (`programs.brave-beta`) behind `desktop.browsers.braveBeta.enable`
- [x] 1.5 Gate Brave Origin installation (`programs.brave-origin-nightly`) behind `desktop.browsers.braveOrigin.enable`
- [x] 1.6 Gate Google Chrome installation (`programs.google-chrome`) behind `desktop.browsers.chrome.enable`
- [x] 1.7 Ensure `desktop.browserArgs` continues to expose args for all browser types regardless of enable flags (PWA module depends on this)

## 2. AI Ecosystem Defaults

- [x] 2.1 Change `services.ai.claude.enable` from `default = true` to plain `mkEnableOption` (default false) in `modules/ai/default.nix`
- [x] 2.2 Change `services.ai.gemini.enable` from `default = true` to plain `mkEnableOption` (default false) in `modules/ai/default.nix`
- [x] 2.3 Move `claude-monitor` from unconditional packages to `cfg.claude.enable` conditional block
- [x] 2.4 Add `services.ai.workflow.enable` option (mkEnableOption, default false) in `modules/ai/default.nix`
- [x] 2.5 Move `spec-kit` and `openspec` from unconditional packages to `cfg.workflow.enable` conditional block
- [x] 2.6 Verify `whisper-cpp` remains the only unconditional package under `services.ai.enable`

## 3. Formatting and Validation

- [x] 3.1 Run `nix fmt .` to format all modified files
- [x] 3.2 Run `nix flake check --all-systems` to validate flake structure
