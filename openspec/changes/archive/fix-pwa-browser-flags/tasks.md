# Tasks: Fix PWA Browser Hardware Acceleration Flags

## Phase 1: Expose browser args from NixOS module

- [x] **1.1** In `modules/desktop/browsers.nix`, add a `desktop.browserArgs`
      read-only option (attrsOf listOf str) under `options`.
- [x] **1.2** Set `config.desktop.browserArgs` to map `brave`, `chromium`, and
      `google-chrome` to their computed arg lists.
- [x] **1.3** Add `programs.chromium.commandLineArgs = chromeArgs` in the
      home-manager sharedModules block (Chromium was missing entirely).

## Phase 2: Consume browser args in PWA launcher

- [x] **2.1** In `home/desktop/pwa-apps.nix`, add `osConfig` to the module
      function arguments.
- [x] **2.2** Read `osConfig.desktop.browserArgs` with a safe fallback
      (`or {}`).
- [x] **2.3** Update `makeLauncher` to prepend the browser-specific args to
      both the isolated and non-isolated exec lines.
- [x] **2.4** Update the desktop entry `actions` exec lines (line ~237) to
      also include the browser args.

## Phase 3: Validate & format

- [x] **3.1** Run `nix fmt .` to ensure formatting compliance.
- [x] **3.2** Run `nix flake check --all-systems` (dry-run) to verify no
      evaluation errors.

## Phase 4: Spec update & finalize

- [x] **4.1** Update `openspec/specs/desktop/spec.md` — add a requirement
      for PWA launchers to inherit browser hardware acceleration flags.
- [x] **4.2** Merge delta specs into main specs directory.
- [x] **4.3** Archive this change to `openspec/changes/archive/`.
