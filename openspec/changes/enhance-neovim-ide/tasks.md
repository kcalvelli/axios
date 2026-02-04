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

## Phase 12: Nix-Standard Remediation 🔴 PENDING

**Problem**: Current implementation downloads plugins at runtime (lazy.nvim, treesitter parsers), violating Nix reproducibility principles.

### 12.1 Migrate Plugin Installation to Nix

- [ ] **12.1.1** Remove lazy.nvim bootstrap from Lua preset
  - Delete `bootstrap_lazy()` function from `lua/axios/init.lua`
  - Remove lazy.nvim setup call

- [ ] **12.1.2** Add plugins via `programs.neovim.plugins`
  ```nix
  plugins = with pkgs.vimPlugins; [
    which-key-nvim
    nvim-lspconfig
    nvim-cmp cmp-nvim-lsp cmp-buffer cmp-path
    luasnip friendly-snippets
    telescope-nvim telescope-fzf-native-nvim
    neo-tree-nvim
    gitsigns-nvim lazygit-nvim diffview-nvim
    lualine-nvim bufferline-nvim indent-blankline-nvim
    nvim-web-devicons
    nvim-autopairs comment-nvim nvim-surround
    flash-nvim todo-comments-nvim
    toggleterm-nvim
    auto-session
  ];
  ```

- [ ] **12.1.3** Use Nix-provided treesitter parsers
  ```nix
  (nvim-treesitter.withPlugins (p: [
    p.nix p.lua p.rust p.zig p.go p.python
    p.typescript p.javascript p.json p.yaml
    p.markdown p.bash p.c p.cpp p.toml
  ]))
  ```

### 12.2 Refactor Lua Preset

- [ ] **12.2.1** Convert plugin specs to configuration-only
  - Remove lazy.nvim spec format (`{ "author/plugin", opts = {} }`)
  - Keep only setup/configuration calls
  - Plugins already loaded by Nix, just need configuration

- [ ] **12.2.2** Update `init.lua` to configure pre-installed plugins
  ```lua
  -- Plugins loaded by Nix, just configure them
  require("which-key").setup({})
  require("telescope").setup({})
  -- etc.
  ```

- [ ] **12.2.3** Remove treesitter auto-install logic
  - Parsers provided by Nix via `withPlugins`
  - Just call `vim.treesitter.start()` for highlighting

### 12.3 Update Home-Manager Module

- [ ] **12.3.1** Add conditional plugin lists based on `AXIOS_NVIM_LANGUAGES`
  - Base plugins always included
  - Language-specific plugins added when language detected

- [ ] **12.3.2** Add `lib.mkIf cfg.enable` wrapper
  ```nix
  options.axios.neovim.enable = lib.mkEnableOption "neovim IDE";
  config = lib.mkIf cfg.enable { ... };
  ```

- [ ] **12.3.3** Remove activation script for init.lua bootstrap
  - Use `programs.neovim.extraLuaConfig` for managed config
  - Or document migration path for existing users

### 12.4 Validation

- [ ] **12.4.1** Test offline installation
  - Disconnect from internet
  - Run `nixos-rebuild switch`
  - Verify neovim works fully

- [ ] **12.4.2** Verify reproducibility
  - Build on two machines
  - Compare plugin versions/hashes

- [ ] **12.4.3** Startup time benchmark
  - `nvim --startuptime /tmp/startup.log`
  - Target: <100ms (should be faster without download checks)

- [ ] **12.4.4** Feature parity check
  - LSP works for Nix, Lua
  - Treesitter highlighting works
  - Telescope, neo-tree, git integration work
  - All keybindings functional

### 12.5 Documentation Update

- [ ] **12.5.1** Update `docs/neovim-ide.md`
  - Remove references to lazy.nvim plugin management
  - Document how to add user plugins (if supported)
  - Update troubleshooting section

- [ ] **12.5.2** Update spec delta
  - Reflect Nix-native plugin management

## Phase 12 Dependencies

```
Phase 12.1 (Migrate Plugins to Nix)
    │
    └── Phase 12.2 (Refactor Lua Preset)
            │
            └── Phase 12.3 (Update Home-Manager)
                    │
                    └── Phase 12.4 (Validation)
                            │
                            └── Phase 12.5 (Documentation)
```

## Summary

**Phase 1-11**: Initial implementation complete (functional but non-Nix-standard)
**Phase 12**: Remediation to align with axios design principles (pending)
