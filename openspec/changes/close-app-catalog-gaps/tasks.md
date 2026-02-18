## 1. LobeHub Package

- [x] 1.1 Create `pkgs/lobehub/default.nix` derivation using `appimageTools.wrapType2` fetching LobeHub v2.1.30+ AppImage
- [x] 1.2 Add `--ozone-platform=wayland` and `--enable-wayland-ime` flags via `makeWrapper`
- [x] 1.3 Ensure `.desktop` file is included with correct name, icon, and categories
- [x] 1.4 Register `lobehub` in `pkgs/default.nix` overlay

## 2. AI Module — LobeHub Integration

- [x] 2.1 Add LobeHub to `modules/ai/default.nix` inside the `services.ai.local.enable` mkIf block
- [x] 2.2 Verify LobeHub is NOT included when `services.ai.local.enable = false`

## 3. Development Module — CLI Tools

- [x] 3.1 Add `pgcli`, `litecli`, `httpie`, `difftastic` to `modules/development/default.nix` inside mkIf block
- [x] 3.2 Add `btop`, `mtr`, `dog` to `modules/development/default.nix` inside mkIf block

## 4. Desktop Module — LibreOffice & Hoppscotch PWA

- [x] 4.1 Add `libreoffice-qt` to `modules/desktop/default.nix` inside mkIf block
- [x] 4.2 Copy `~/.config/nixos_config/pwa-icons/hoppscotch.png` to `home/resources/pwa-icons/hoppscotch.png`
- [x] 4.3 Add Hoppscotch entry to `pkgs/pwa-apps/pwa-defs.nix` (category: Development)

## 5. Documentation — APPLICATIONS.md

- [x] 5.1 Update `docs/APPLICATIONS.md` — add Browsers section documenting Brave, Chromium, Chrome
- [x] 5.2 Update `docs/APPLICATIONS.md` — add all new packages (pgcli, litecli, httpie, difftastic, btop, mtr, dog, libreoffice-qt, LobeHub, Hoppscotch)
- [x] 5.3 Update `docs/APPLICATIONS.md` — correct Application Count Summary table
- [x] 5.4 Update `docs/APPLICATIONS.md` — document Tailscale as core service, note nixd as future alternative to nil

## 6. Documentation — MODULE_REFERENCE.md

- [x] 6.1 Update `docs/MODULE_REFERENCE.md` — add pgcli, litecli, httpie, difftastic, btop, mtr, dog to development module "Includes" list
- [x] 6.2 Update `docs/MODULE_REFERENCE.md` — add LobeHub to AI module Local LLM Stack list
- [x] 6.3 Update `docs/MODULE_REFERENCE.md` — add libreoffice-qt to desktop module "Includes" list

## 7. Documentation — PWA_GUIDE.md

- [x] 7.1 Update `docs/PWA_GUIDE.md` — add Hoppscotch to default PWA examples in the introduction

## 8. Formatting & Validation

- [x] 8.1 Run `nix fmt .` to format all modified Nix files
- [x] 8.2 Run `nix flake check --all-systems` to validate flake structure
