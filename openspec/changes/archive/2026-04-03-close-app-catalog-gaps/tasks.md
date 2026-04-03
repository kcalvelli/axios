## 1. Development Module — CLI Tools

- [x] 1.1 Add `pgcli`, `litecli`, `httpie`, `difftastic` to `modules/development/default.nix` inside mkIf block
- [x] 1.2 Add `btop`, `mtr`, `dog` to `modules/development/default.nix` inside mkIf block

## 2. Desktop Module — LibreOffice & Hoppscotch PWA

- [x] 2.1 Add `libreoffice-qt` to `modules/desktop/default.nix` inside mkIf block
- [x] 2.2 Copy `~/.config/nixos_config/pwa-icons/hoppscotch.png` to `home/resources/pwa-icons/hoppscotch.png`
- [x] 2.3 Add Hoppscotch entry to `pkgs/pwa-apps/pwa-defs.nix` (category: Development)

## 3. Documentation — APPLICATIONS.md

- [x] 3.1 Update `docs/APPLICATIONS.md` — add Browsers section documenting Brave, Chromium, Chrome
- [x] 3.2 Update `docs/APPLICATIONS.md` — add all new packages (pgcli, litecli, httpie, difftastic, btop, mtr, dog, libreoffice-qt, Hoppscotch)
- [x] 3.3 Update `docs/APPLICATIONS.md` — correct Application Count Summary table
- [x] 3.4 Update `docs/APPLICATIONS.md` — document Tailscale as core service, note nixd as future alternative to nil

## 4. Documentation — MODULE_REFERENCE.md

- [x] 4.1 Update `docs/MODULE_REFERENCE.md` — add pgcli, litecli, httpie, difftastic, btop, mtr, dog to development module "Includes" list
- [x] 4.2 Update `docs/MODULE_REFERENCE.md` — add libreoffice-qt to desktop module "Includes" list

## 5. Documentation — PWA_GUIDE.md

- [x] 5.1 Update `docs/PWA_GUIDE.md` — add Hoppscotch to default PWA examples in the introduction

## 6. Formatting & Validation

- [x] 6.1 Run `nix fmt .` to format all modified Nix files
- [x] 6.2 Run `nix flake check --all-systems` to validate flake structure
