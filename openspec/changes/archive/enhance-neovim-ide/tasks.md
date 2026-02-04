# Tasks: Enhance Neovim IDE

## Phase 1: Foundation

- [ ] **1.1** Create `pkgs/axios-nvim-preset/` derivation structure
  - Create `default.nix` that builds lua preset
  - Verify it builds with `nix build .#axios-nvim-preset`

- [ ] **1.2** Create preset Lua skeleton
  - `lua/axios/init.lua` - main entry with `setup(opts)`
  - `lua/axios/config/options.lua` - vim options (number, tabs, etc.)
  - `lua/axios/config/keymaps.lua` - leader key bindings skeleton
  - `lua/axios/config/autocmds.lua` - autocommands

- [ ] **1.3** Implement lazy.nvim bootstrap in preset
  - Move bootstrap logic from `home/terminal/neovim.nix` to lua preset
  - Add lazy.nvim to preset's plugin specs
  - Verify neovim starts and lazy.nvim loads

## Phase 2: Core Plugins

- [ ] **2.1** Add which-key for keybind discoverability
  - Create `lua/axios/plugins/which-key.lua`
  - Configure group prefixes (f=find, g=git, l=lsp, etc.)

- [ ] **2.2** Add UI plugins
  - `lua/axios/plugins/ui.lua` with:
    - lualine.nvim (status line)
    - bufferline.nvim (buffer tabs)
    - indent-blankline.nvim (indent guides)
    - nvim-web-devicons (icons)
  - Use DMS colorscheme integration

- [ ] **2.3** Add editor enhancement plugins
  - `lua/axios/plugins/editor.lua` with:
    - nvim-autopairs
    - Comment.nvim
    - nvim-surround
    - todo-comments.nvim

## Phase 3: Navigation & Search

- [ ] **3.1** Add telescope.nvim
  - `lua/axios/plugins/telescope.lua`
  - Keymaps: `<leader>ff` files, `<leader>fg` grep, `<leader>fb` buffers, etc.
  - Include fzf-native for performance
  - Lazy-load on keymap

- [ ] **3.2** Add neo-tree.nvim
  - `lua/axios/plugins/explorer.lua`
  - Keymap: `<leader>e` toggle
  - Configure git status, file icons

- [ ] **3.3** Add terminal integration
  - `lua/axios/plugins/terminal.lua` with toggleterm.nvim
  - Keymaps: `<leader>tt` toggle, `<C-\>` quick terminal
  - lazygit integration

## Phase 4: LSP & Completion

- [ ] **4.1** Implement language detection
  - `lua/axios/languages/init.lua`
  - Read `AXIOS_NVIM_LANGUAGES` env var
  - Fallback: detect LSP binaries in PATH
  - Always enable: nix, lua

- [ ] **4.2** Add nvim-lspconfig
  - `lua/axios/plugins/lsp.lua`
  - Configure on_attach with keymaps (`gd`, `gr`, `K`, etc.)
  - Configure capabilities for completion

- [ ] **4.3** Add language-specific LSP configs
  - `lua/axios/languages/nix.lua` - nil_ls
  - `lua/axios/languages/lua.lua` - lua_ls
  - `lua/axios/languages/rust.lua` - rust-analyzer
  - `lua/axios/languages/zig.lua` - zls
  - `lua/axios/languages/python.lua` - pyright
  - `lua/axios/languages/typescript.lua` - ts_ls
  - `lua/axios/languages/go.lua` - gopls

- [ ] **4.4** Add nvim-cmp completion
  - `lua/axios/plugins/completion.lua`
  - Sources: lsp, buffer, path, luasnip
  - Add LuaSnip + friendly-snippets
  - Tab/S-Tab navigation

- [ ] **4.5** Add nvim-treesitter
  - `lua/axios/plugins/treesitter.lua`
  - Auto-install parsers for detected languages
  - Enable highlight, indent, incremental selection

## Phase 5: Git Integration

- [ ] **5.1** Add git plugins
  - `lua/axios/plugins/git.lua` with:
    - gitsigns.nvim (signs, blame, hunks)
    - lazygit.nvim (terminal UI)
    - diffview.nvim (diff viewer)
  - Keymaps: `<leader>g*` prefix

## Phase 6: Debugging (DAP)

- [ ] **6.1** Add DAP infrastructure
  - `lua/axios/plugins/debug.lua` with:
    - nvim-dap
    - nvim-dap-ui
    - nvim-dap-virtual-text
  - Keymaps: `<leader>d*` prefix

- [ ] **6.2** Add language-specific debug adapters
  - Rust/C++: codelldb (via devshell)
  - Python: debugpy (via devshell)
  - Go: delve (via devshell)
  - Configure adapters conditionally

## Phase 7: AI Integration

- [ ] **7.1** Add avante.nvim (conditional)
  - `lua/axios/plugins/ai.lua`
  - Check `AXIOS_AI_ENABLED` env var
  - Configure Claude as default provider
  - Support `auth_type` option: "api", "pro", "max"
  - Keymaps: `<leader>a*` prefix
  - Lazy-load on keymap

- [ ] **7.2** Implement auth_type configuration
  - "api" mode: Use ANTHROPIC_API_KEY env var
  - "pro"/"max" mode: Configure avante for Claude subscription
  - Pass user's ai.claude.auth_type to avante setup

## Phase 8: Home-Manager Integration

- [ ] **8.1** Refactor `home/terminal/neovim.nix`
  - Convert to directory module `home/terminal/neovim/`
  - Add `default.nix` with:
    - `programs.neovim.enable`
    - `extraPackages` for base LSPs (nil, lua_ls)
    - Add preset to runtimepath
  - Set `AXIOS_AI_ENABLED` based on `osConfig.services.ai.enable`

- [ ] **8.2** Update init.lua bootstrap
  - Generate improved template with `require("axios").setup({})`
  - Include commented examples for customization
  - Only generate if no init.lua exists

- [ ] **8.3** Register package in flake
  - Add `axios-nvim-preset` to `flake.nix` packages
  - Verify builds with `nix build .#axios-nvim-preset`

## Phase 9: Devshell Integration

- [ ] **9.1** Update rust devshell
  - Add `AXIOS_NVIM_LANGUAGES = "rust,toml"`
  - Ensure rust-analyzer in packages (already via toolchain)
  - Add codelldb for debugging

- [ ] **9.2** Update zig devshell
  - Add `AXIOS_NVIM_LANGUAGES = "zig"`
  - Ensure zls in packages (already present)

- [ ] **9.3** Update other devshells
  - qml.nix: Add `AXIOS_NVIM_LANGUAGES = "cpp,qml"`
  - dotnet.nix: Add `AXIOS_NVIM_LANGUAGES = "cs"`

- [ ] **9.4** Create template for new devshells
  - Document pattern for adding neovim integration
  - Update devshell documentation

## Phase 10: Session Management

- [ ] **10.1** Add auto-session
  - `lua/axios/plugins/session.lua`
  - Auto-save/restore sessions per directory
  - Telescope integration for session picker

## Phase 11: Testing & Documentation

- [ ] **11.1** Startup time validation
  - Measure with `nvim --startuptime /tmp/startup.log`
  - Target: <100ms
  - Profile and optimize if needed

- [ ] **11.2** Test scenarios
  - Fresh install: verify init.lua generated, plugins load
  - Rust devshell: verify rust-analyzer attaches
  - AI disabled: verify no AI plugins load
  - User override: verify custom config takes precedence

- [ ] **11.3** Update development spec
  - Merge spec delta into `openspec/specs/development/spec.md`
  - Document keybinds, plugin list, customization

- [ ] **11.4** Update CLAUDE.md
  - Add neovim section with keybind reference
  - Document devshell integration

## Parallelizable Work

The following can be done in parallel:
- **Phase 2, 3**: Core plugins and navigation (independent)
- **Phase 4.3**: Individual language configs (independent of each other)
- **Phase 9.1-9.3**: Devshell updates (independent of each other)

## Dependencies

```
Phase 1 (Foundation)
    │
    ├── Phase 2 (Core Plugins)
    │   └── Phase 3 (Navigation)
    │
    ├── Phase 4 (LSP/Completion) ─── requires Phase 2 (which-key for keymaps)
    │   └── Phase 6 (DAP) ─── requires Phase 4 (language detection)
    │
    ├── Phase 5 (Git) ─── requires Phase 2 (which-key)
    │
    └── Phase 7 (AI) ─── requires Phase 4 (completion integration)

Phase 8 (Home-Manager) ─── requires Phase 1-7 complete
    │
    └── Phase 9 (Devshells) ─── requires Phase 8

Phase 10 (Session) ─── can start after Phase 3

Phase 11 (Testing) ─── requires all above
```
