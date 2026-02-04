# Tasks: Enhance Neovim IDE

## Phase 1: Foundation ✅ COMPLETE

- [x] **1.1** Create `pkgs/axios-nvim-preset/` derivation structure
- [x] **1.2** Create preset Lua skeleton
- [x] **1.3** Implement lazy.nvim bootstrap in preset

## Phase 2: Core Plugins ✅ COMPLETE

- [x] **2.1** Add which-key for keybind discoverability
- [x] **2.2** Add UI plugins (lualine, bufferline, indent-blankline, devicons)
- [x] **2.3** Add editor enhancement plugins (autopairs, Comment, surround, todo-comments)

## Phase 3: Navigation & Search ✅ COMPLETE

- [x] **3.1** Add telescope.nvim
- [x] **3.2** Add neo-tree.nvim
- [x] **3.3** Add terminal integration (toggleterm)

## Phase 4: LSP & Completion ✅ COMPLETE

- [x] **4.1** Implement language detection via `AXIOS_NVIM_LANGUAGES`
- [x] **4.2** Add nvim-lspconfig (migrated to Neovim 0.11 native API)
- [x] **4.3** Add language-specific LSP configs (inlined in lsp.lua)
- [x] **4.4** Add nvim-cmp completion
- [x] **4.5** Add nvim-treesitter (simplified for new API)

## Phase 5: Git Integration ✅ COMPLETE

- [x] **5.1** Add git plugins (gitsigns, lazygit, diffview)

## Phase 6: Debugging (DAP) ✅ COMPLETE

- [x] **6.1** Add DAP infrastructure
- [x] **6.2** Add language-specific debug adapters (conditional)

## Phase 7: AI Integration ⚠️ REMOVED

- [x] **7.1** ~~Add avante.nvim~~ - Removed (Claude Max doesn't provide API keys for third-party tools)

## Phase 8: Home-Manager Integration ✅ COMPLETE

- [x] **8.1** Refactor to directory module `home/terminal/neovim/`
- [x] **8.2** Update init.lua bootstrap (user-owned)
- [x] **8.3** Register package in flake

## Phase 9: Devshell Integration ✅ COMPLETE

- [x] **9.1** Update rust devshell with `AXIOS_NVIM_LANGUAGES`
- [x] **9.2** Update zig devshell
- [x] **9.3** Update qml.nix and dotnet.nix devshells

## Phase 10: Session Management ✅ COMPLETE

- [x] **10.1** Add auto-session

## Phase 11: Documentation ✅ COMPLETE

- [x] **11.1** Create `docs/neovim-ide.md` user guide
- [x] **11.2** Document keybindings, customization, troubleshooting

---

## Phase 12: Final Adjustments ✅ COMPLETE

**Decision**: Keep lazy.nvim approach (see proposal for rationale). Only minor adjustments needed.

### 12.1 Add Enable Guard

- [x] **12.1.1** Add `lib.mkIf cfg.enable` wrapper to `home/terminal/neovim/default.nix`

### 12.2 Documentation

- [x] **12.2.1** Add note to `docs/neovim-ide.md` about first-launch behavior

### 12.3 Finalize

- [x] **12.3.1** Spec delta already in `openspec/changes/enhance-neovim-ide/specs/development/spec.md`
- [x] **12.3.2** Archive this change directory

## Summary

**All phases complete** ✅
