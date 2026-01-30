# Tasks: Refactor PWA Browser Configuration

## Context
Currently, all PWA applications (axios-ai-mail, immich, and generic PWA apps) are hardcoded to use Brave browser. Brave requires manual configuration ("Use Google services for push messaging") in each isolated profile for push notifications to work. Switching to Chromium or Google Chrome resolves this by enabling push support out-of-the-box. Additionally, PWA definitions are duplicated across modules.

## Objective
Centralize PWA creation logic in `home/desktop/pwa-apps.nix` to support configurable browsers (`chromium` default) and unified URL handling.

## Implementation Steps

### 1. Refactor `home/desktop/pwa-apps.nix`
- [ ] Define `axios.pwa.apps` option (attrsOf submodule) to replace `extraApps`.
- [ ] Submodule structure:
    - `name` (str)
    - `url` (str)
    - `icon` (str)
    - `categories` (list of str)
    - `isolated` (bool, default `true` - new field, replaces hardcoded behavior)
    - `mimeTypes` (list of str, default `[]`)
    - `actions` (attrsOf submodule, default `{}`)
    - `description` (str, optional)
- [ ] Add `axios.pwa.browser` option (enum: `brave`, `chromium`, `google-chrome`).
- [ ] Preserve `axios.pwa.includeDefaults` (bool, default `true`) and `axios.pwa.iconPath` (path, default `null`).
    - If `includeDefaults` is true, merge default apps from `pkgs/pwa-apps/pwa-defs.nix` into `config.axios.pwa.apps`.
    - If `iconPath` is set, use it as an additional source for icon resolution.
- [ ] Implement `xdg.desktopEntries` generation logic:
    - Iterate over `config.axios.pwa.apps`.
    - Generate `Exec` command based on `browser` selection.
    - Handle `isolated` flag (add `--user-data-dir`).
    - Generate correct `StartupWMClass` based on browser type (`brave-`, `chromium-`, `chrome-`).
- [ ] Ensure `pkgs.chromium`, `pkgs.brave`, or `pkgs.google-chrome` is added to packages.

### 2. Update `modules/services/immich.nix`
- [ ] Enable `loopbackProxy` in `networking.tailscale.services."axios-immich"`.
- [ ] Remove manual `networking.hosts` hack for server role.

### 3. Refactor `home/pim/default.nix`
- [ ] Remove `xdg.desktopEntries` and `home.file` definitions.
- [ ] Configure `axios.pwa.apps.axios-mail` using the unified URL (`https://axios-mail.<tailnet>/`).

### 4. Refactor `home/immich/default.nix`
- [ ] Remove `xdg.desktopEntries` and `home.file` definitions.
- [ ] Configure `axios.pwa.apps.axios-immich` using the unified URL (`https://axios-immich.<tailnet>/`).

### 5. Update `scripts/add-pwa.sh`
- [ ] Update script to generate `axios.pwa.apps.<name>` blocks instead of `axios.pwa.extraApps.<name>`.
- [ ] Verify `mimeTypes` and `actions` are correctly populated in the new structure.

### 6. Refactor `pkgs/pwa-apps`
- [ ] Refactor package to serve primarily as an asset provider (icons).
- [ ] Remove the launcher script generation logic from the package itself (moved to `home/desktop/pwa-apps.nix`).
- [ ] Ensure `pwa-defs.nix` remains available for import by the desktop module.

### 7. Verify
- [ ] `nix flake check`
- [ ] Verify generated desktop files have correct `Exec` and `StartupWMClass`.
- [ ] Verify Immich and PIM use unified URLs.
- [ ] Verify default apps (YouTube, etc.) are still present.
