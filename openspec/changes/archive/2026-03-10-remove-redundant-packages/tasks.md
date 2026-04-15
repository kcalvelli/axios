## 1. Development Module Cleanup

- [x] 1.1 Remove neovim, starship, fish, eza, fzf, gh from `environment.systemPackages` in `modules/development/default.nix` (lines 24, 37-42, 58)
- [x] 1.2 Remove mtr from `modules/development/default.nix` (line 54) — provided by networking module's `programs.mtr.enable`
- [x] 1.3 Remove btop from `modules/development/default.nix` (line 53) — moving to system module

## 2. System Module Cleanup

- [x] 2.1 Replace gtop with btop in `modules/system/default.nix` (line 62)
- [x] 2.2 Move cachix from `modules/system/nix.nix` (unconditional) into the `environment.systemPackages` block in `modules/system/default.nix` (inside existing `mkIf config.cairn.system.enable`)
- [x] 2.3 Remove the `environment.systemPackages` block from `modules/system/nix.nix`

## 3. AI Module Deduplication

- [x] 3.1 Create a shared `lib.mkIf (cfg.enable && cfg.local.enable)` block in `modules/ai/default.nix` containing python3 and uv
- [x] 3.2 Remove python3 and uv from the server role block (lines 252-253)
- [x] 3.3 Remove python3 and uv from the client role block (lines 289-290)

## 4. Validation

- [x] 4.1 Run `nix fmt .` to format all modified files
- [x] 4.2 Run `nix flake check --all-systems` to verify no evaluation errors
