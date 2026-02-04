# Design: Neovim IDE Architecture

## Overview

This document describes the technical architecture for the neovim IDE enhancement.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         User's ~/.config/nvim/                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ init.lua (user-owned, generated once)                            │   │
│  │   • Sets leader key                                              │   │
│  │   • require("axios").setup({ ... })  -- load preset with opts    │   │
│  │   • User's custom plugins/config below                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              Nix Store: axios-nvim-preset (Lua module)                  │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ lua/axios/init.lua                                               │   │
│  │   • setup(opts) - merges user opts with defaults                 │   │
│  │   • Reads AXIOS_NVIM_LANGUAGES env var                           │   │
│  │   • Reads AXIOS_AI_ENABLED env var                               │   │
│  │   • Bootstraps lazy.nvim if needed                               │   │
│  │   • Loads plugin specs                                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ lua/axios/plugins/*.lua                                          │   │
│  │   • lsp.lua - LSP configuration                                  │   │
│  │   • completion.lua - nvim-cmp setup                              │   │
│  │   • treesitter.lua - syntax highlighting                         │   │
│  │   • telescope.lua - fuzzy finder                                 │   │
│  │   • git.lua - gitsigns, lazygit                                  │   │
│  │   • ai.lua - avante.nvim (conditional on AXIOS_AI_ENABLED)        │   │
│  │   • ui.lua - lualine, bufferline, etc.                           │   │
│  │   • editor.lua - autopairs, comments, surround                   │   │
│  │   • debug.lua - DAP configuration                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ lua/axios/languages/*.lua                                        │   │
│  │   • nix.lua - nil_ls config (always loaded)                      │   │
│  │   • rust.lua - rust-analyzer config                              │   │
│  │   • zig.lua - zls config                                         │   │
│  │   • python.lua - pyright/ruff config                             │   │
│  │   • typescript.lua - ts_ls config                                │   │
│  │   • go.lua - gopls config                                        │   │
│  │   • lua.lua - lua_ls config                                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Environment (from devshell or system)                │
│  AXIOS_NVIM_LANGUAGES="rust,toml"   # Set by devshell                  │
│  AXIOS_AI_ENABLED="1"               # Set by home-manager if ai.enable │
│  PATH includes: rust-analyzer, nil, etc.                                │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. axios-nvim-preset Package

A derivation that builds the Lua preset module:

```nix
# pkgs/axios-nvim-preset/default.nix
{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "axios-nvim-preset";
  version = "1.0.0";

  src = ./lua;

  installPhase = ''
    mkdir -p $out/lua
    cp -r . $out/lua/axios
  '';
}
```

### 2. Neovim Wrapper

Home-manager configures neovim to include the preset in its runtime path:

```nix
# home/terminal/neovim.nix
programs.neovim = {
  enable = true;
  extraPackages = with pkgs; [
    # LSPs always available
    nil  # Nix
    lua-language-server
  ];

  # Add preset to runtime path
  extraLuaConfig = ''
    vim.opt.rtp:prepend("${pkgs.axios-nvim-preset}")
  '';
};

# Set AI env var based on system config
home.sessionVariables = lib.mkIf (osConfig.services.ai.enable or false) {
  AXIOS_AI_ENABLED = "1";
};
```

### 3. Devshell Integration

Each devshell exports language configuration:

```nix
# devshells/rust.nix
mkShell {
  env = [
    { name = "AXIOS_NVIM_LANGUAGES"; value = "rust,toml"; }
  ];
  packages = [ toolchain ];  # includes rust-analyzer
}
```

### 4. User Init.lua Template

Generated on first run:

```lua
-- ~/.config/nvim/init.lua (generated by axios, user-owned)

-- Leader key (MUST be set before loading plugins)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load axios preset with optional overrides
require("axios").setup({
  -- Override any defaults here
  -- colorscheme = "tokyonight",
  -- plugins = {
  --   disabled = { "neo-tree.nvim" },  -- disable specific plugins
  -- },
  -- lsp = {
  --   servers = {
  --     nil_ls = { settings = { ... } },  -- override LSP settings
  --   },
  -- },
  -- ai = {
  --   claude = {
  --     auth_type = "max",  -- "api", "pro", or "max" (default: "api")
  --   },
  -- },
})

-- Your custom configuration below
-- Add plugins to lazy.nvim:
-- require("lazy").setup({
--   { "your/plugin" },
-- }, { defaults = { lazy = true } })
```

## Key Design Decisions

### D1: Preset in Nix Store vs User-Managed Lua

**Decision**: Preset lives in Nix store, loaded via runtimepath.

**Rationale**:
- Reproducible across machines
- Updates via `nix flake update` like other axiOS components
- User can still override anything via their init.lua
- No conflicts with user's lua/ directory

**Trade-off**: Users can't edit the preset directly (must override).

### D2: Environment Variables for Language Detection

**Decision**: Use `AXIOS_NVIM_LANGUAGES` env var set by devshells.

**Alternatives Considered**:
1. **Mason.nvim auto-install**: Rejected - duplicates Nix's job, non-reproducible
2. **Scan PATH for binaries**: Could work as fallback, but explicit is clearer
3. **Per-devshell neovim config file**: Too complex, hard to merge

**Rationale**:
- Explicit and predictable
- Devshells already set environment
- Easy to debug (`echo $AXIOS_NVIM_LANGUAGES`)
- Graceful fallback: if LSP not in PATH, show message

### D3: AI Plugins Conditional on services.ai.enable

**Decision**: Set `AXIOS_AI_ENABLED=1` when AI module is active.

**Rationale**:
- Respects user's system configuration
- Avoids loading unused plugins
- Consistent with axiOS philosophy (modules are conditional)

### D4: Lazy-Loading Strategy

**Decision**: All plugins lazy-load except core UI.

**Loading triggers**:
- LSP: on `LspAttach` or filetype
- Treesitter: on `BufRead`
- Telescope: on keymap `<leader>f*`
- Git: on `BufRead` for gitsigns, keymap for lazygit
- DAP: on keymap `<leader>d*`
- AI: on `InsertEnter` for copilot, keymap for codecompanion

**Target**: <100ms startup time measured via `nvim --startuptime`.

### D5: AI Integration via Avante.nvim

**Decision**: Use avante.nvim with Claude as the default provider.

**Rationale**:
- Cursor-like experience (side panel, inline diffs, chat)
- Native Claude support with multiple auth types
- Single plugin vs multiple (copilot + codecompanion)
- Active development and community

**Configuration Options**:
```lua
require("axios").setup({
  ai = {
    provider = "claude",  -- "claude", "openai", "gemini", "ollama"
    claude = {
      auth_type = "api",  -- "api" (default), "pro", or "max"
      -- "api" = Anthropic API with ANTHROPIC_API_KEY
      -- "pro" = Claude Pro subscription ($20/mo)
      -- "max" = Claude Max subscription ($100/mo, higher limits)
    },
  },
})
```

**Auth Type Behavior**:
| auth_type | API Key Source | Rate Limits |
|-----------|---------------|-------------|
| `"api"` | `ANTHROPIC_API_KEY` env var | Pay-per-token |
| `"pro"` | Claude Pro session | Standard |
| `"max"` | Claude Max session | Higher limits |

### D6: Keybind Philosophy

**Decision**: Use which-key with mnemonic prefixes.

| Prefix | Category |
|--------|----------|
| `<leader>f` | Find (telescope) |
| `<leader>g` | Git |
| `<leader>l` | LSP |
| `<leader>d` | Debug |
| `<leader>a` | AI |
| `<leader>e` | Explorer |
| `<leader>t` | Terminal |
| `<leader>b` | Buffers |

**Rationale**: Discoverable via which-key popup, consistent mnemonics.

## Language Support Matrix

| Language | LSP | DAP | Treesitter | Formatter | Source |
|----------|-----|-----|------------|-----------|--------|
| Nix | nil_ls | - | nix | nixfmt | Always |
| Lua | lua_ls | - | lua | stylua | Always |
| Rust | rust-analyzer | codelldb | rust | rustfmt | Devshell |
| Zig | zls | - | zig | zig fmt | Devshell |
| Go | gopls | delve | go | gofmt | Devshell |
| Python | pyright | debugpy | python | ruff | Devshell |
| TypeScript | ts_ls | - | typescript | prettier | Devshell |
| C/C++ | clangd | codelldb | c, cpp | clang-format | Devshell |

## File Structure

```
home/terminal/neovim/
├── default.nix           # Module entry point
├── wrapper.nix           # Neovim package wrapper
└── preset/               # Lua preset source
    └── lua/
        └── axios/
            ├── init.lua
            ├── config/
            │   ├── options.lua
            │   ├── keymaps.lua
            │   └── autocmds.lua
            ├── plugins/
            │   ├── init.lua       # Plugin specs aggregator
            │   ├── lsp.lua
            │   ├── completion.lua
            │   ├── treesitter.lua
            │   ├── telescope.lua
            │   ├── git.lua
            │   ├── ai.lua
            │   ├── ui.lua
            │   ├── editor.lua
            │   ├── debug.lua
            │   └── terminal.lua
            └── languages/
                ├── init.lua       # Language detection
                ├── nix.lua
                ├── rust.lua
                ├── zig.lua
                └── ...

devshells/
├── rust.nix              # + AXIOS_NVIM_LANGUAGES
├── zig.nix               # + AXIOS_NVIM_LANGUAGES
└── ...
```

## Migration Path

For users with existing neovim configs:

1. **No action needed**: axios only generates init.lua if none exists
2. **Opt-in**: Users can add `require("axios").setup({})` to their config
3. **Gradual adoption**: Users can enable specific modules:
   ```lua
   require("axios.plugins.lsp").setup({})
   require("axios.plugins.telescope").setup({})
   ```
