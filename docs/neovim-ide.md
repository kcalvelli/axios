# axiOS Neovim IDE Guide

axiOS provides a full-featured neovim IDE experience out of the box. This guide covers what's included and how to use it effectively.

## What's Included

### Core Features

| Category | Plugins | Purpose |
|----------|---------|---------|
| Plugin Manager | lazy.nvim | Lazy-loading plugin management |
| Discoverability | which-key | Press `<Space>` and wait to see available keybinds |
| File Explorer | neo-tree | Sidebar file browser |
| Fuzzy Finder | telescope | Find files, grep, buffers, and more |
| Terminal | toggleterm | Integrated terminal + lazygit |
| Session | auto-session | Auto-save/restore your workspace |

### Code Intelligence

| Category | Plugins | Purpose |
|----------|---------|---------|
| LSP | nvim-lspconfig | Language server integration |
| Completion | nvim-cmp | Intelligent autocompletion |
| Snippets | LuaSnip + friendly-snippets | Code snippets |
| Syntax | nvim-treesitter | Semantic highlighting |
| Formatting | conform.nvim | Auto-format on save |
| Linting | nvim-lint | Code linting |

### Git Integration

| Category | Plugins | Purpose |
|----------|---------|---------|
| Signs | gitsigns | Git status in sign column |
| Diff | diffview | Side-by-side diff viewer |
| UI | neogit | Magit-like git interface |
| Terminal | lazygit (via toggleterm) | Full git TUI |

### Editor Enhancements

| Category | Plugins | Purpose |
|----------|---------|---------|
| Statusline | lualine | Status bar with git, diagnostics |
| Bufferline | bufferline | Tab-like buffer bar |
| Indentation | indent-blankline | Visual indent guides |
| Pairs | nvim-autopairs | Auto-close brackets |
| Comments | Comment.nvim | `gc` to toggle comments |
| Surround | nvim-surround | Change surrounding quotes/brackets |
| Motion | flash.nvim | Quick jump anywhere |
| Diagnostics | trouble.nvim | Pretty diagnostics list |

## Quick Start

### Opening a Project

```bash
cd ~/Projects/my-repo
nvim
```

The session plugin will restore your previous workspace if you've opened this directory before.

### Basic Navigation

| Key | Action |
|-----|--------|
| `<Space>e` | Toggle file explorer |
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep (search in files) |
| `<Space>fb` | List open buffers |
| `<Space><Space>` | Quick buffer switch |

### File Explorer (neo-tree)

With the explorer open (`<Space>e`):

| Key | Action |
|-----|--------|
| `<Enter>` | Open file/toggle directory |
| `a` | Create new file |
| `d` | Delete |
| `r` | Rename |
| `c` | Copy |
| `m` | Move |
| `y` | Copy path |
| `q` | Close explorer |

### Editing

| Key | Action |
|-----|--------|
| `gcc` | Toggle comment on line |
| `gc` (visual) | Toggle comment on selection |
| `s` | Flash jump (type chars to jump to) |
| `cs"'` | Change surrounding `"` to `'` |
| `ds"` | Delete surrounding `"` |
| `ys{motion}"` | Add `"` around motion |

## Code Intelligence

### Completion

Completion triggers automatically as you type. You can also:

| Key | Action |
|-----|--------|
| `<C-Space>` | Trigger completion manually |
| `<Tab>` | Select next item / expand snippet |
| `<S-Tab>` | Select previous item |
| `<Enter>` | Confirm selection |
| `<C-e>` | Close completion |
| `<C-b>` / `<C-f>` | Scroll docs |

### LSP Features

When a language server is active (check with `:LspInfo`):

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Hover documentation |
| `<C-k>` (insert) | Signature help |
| `<Space>lr` | Rename symbol |
| `<Space>la` | Code action |
| `<Space>lf` | Format buffer |
| `[d` / `]d` | Previous/next diagnostic |
| `<Space>cd` | Line diagnostics |

### Treesitter Text Objects

Select and navigate by code structure:

| Key | Action |
|-----|--------|
| `af` / `if` | Around/inside function |
| `ac` / `ic` | Around/inside class |
| `aa` / `ia` | Around/inside argument |
| `]f` / `[f` | Next/previous function |
| `]c` / `[c` | Next/previous class |

### Snippets

Type a snippet prefix and press `<Tab>` to expand. Examples:

- `fn` → function template
- `if` → if statement
- `for` → for loop

Use `<Tab>` / `<S-Tab>` to jump between snippet placeholders.

## Git Workflow

### Quick Git Status

| Key | Action |
|-----|--------|
| `<Space>gg` | Open lazygit (full TUI) |
| `<Space>gn` | Open neogit |
| `<Space>gs` | Telescope git status |

### Gitsigns (in-buffer)

| Key | Action |
|-----|--------|
| `]h` / `[h` | Next/previous hunk |
| `<Space>ghs` | Stage hunk |
| `<Space>ghr` | Reset hunk |
| `<Space>ghp` | Preview hunk |
| `<Space>ghb` | Blame line |

### Diffview

| Key | Action |
|-----|--------|
| `<Space>gd` | Open diff view |
| `<Space>gD` | Diff against last commit |
| `<Space>gh` | File history |
| `<Space>gH` | Branch history |

## Terminal

| Key | Action |
|-----|--------|
| `<C-\>` | Toggle terminal |
| `<Space>tt` | Terminal (horizontal) |
| `<Space>tv` | Terminal (vertical) |
| `<Space>tf` | Terminal (floating) |
| `<Esc>` | Exit terminal mode (return to normal) |

In terminal mode, use `<C-h/j/k/l>` to navigate to other windows.

## Window & Buffer Management

### Windows

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Navigate windows |
| `<Space>ws` | Horizontal split |
| `<Space>wv` | Vertical split |
| `<Space>wd` | Close window |
| `<C-Up/Down/Left/Right>` | Resize window |

### Buffers

| Key | Action |
|-----|--------|
| `<S-h>` / `<S-l>` | Previous/next buffer |
| `[b` / `]b` | Previous/next buffer (alternate) |
| `<Space>bd` | Close buffer |
| `<Space>bo` | Close other buffers |
| `<Space>bp` | Pin buffer |

## Search & Replace

### Telescope Search

| Key | Action |
|-----|--------|
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep |
| `<Space>fc` | Grep word under cursor |
| `<Space>fr` | Recent files |
| `<Space>f/` | Fuzzy search in buffer |
| `<Space>ft` | Find TODOs |

### Spectre (Project-wide Replace)

| Key | Action |
|-----|--------|
| `<Space>sr` | Open Spectre |

In Spectre:
- Enter search pattern and replacement
- Preview changes
- Apply selectively or all at once

## Diagnostics & Trouble

| Key | Action |
|-----|--------|
| `<Space>xx` | All diagnostics |
| `<Space>xX` | Buffer diagnostics |
| `<Space>xt` | TODOs |
| `<Space>cs` | Document symbols |

## Sessions

Sessions are saved automatically per directory.

| Key | Action |
|-----|--------|
| `<Space>ss` | Save session |
| `<Space>sr` | Restore session |
| `<Space>sd` | Delete session |
| `<Space>sf` | Search sessions |

## DevShell Integration

When you enter an axiOS devshell, neovim automatically configures for that language:

```bash
# Enter rust devshell
nix develop .#rust

# Neovim now has rust-analyzer LSP active
nvim src/main.rs
```

Available devshells:
- `rust` → rust-analyzer, codelldb debugger
- `zig` → zls
- `qml` → clangd
- `dotnet` → omnisharp

## Customization

Your config lives at `~/.config/nvim/init.lua`:

```lua
require("axios").setup({
  -- Change colorscheme
  colorscheme = "tokyonight",

  -- Disable specific plugins
  plugins = {
    disabled = { "neo-tree.nvim" },
  },

  -- Override LSP settings
  lsp = {
    servers = {
      nil_ls = {
        settings = {
          ["nil"] = {
            formatting = { command = { "nixfmt" } },
          },
        },
      },
    },
  },
})

-- Add your own config below
vim.opt.colorcolumn = "80"
```

### Adding Plugins

Add plugins after the axios setup:

```lua
require("axios").setup({})

-- Add your own plugins
require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin" },
  -- more plugins...
}, { defaults = { lazy = true } })

vim.cmd.colorscheme("catppuccin")
```

## Troubleshooting

### LSP Not Working

1. Check if LSP is attached: `:LspInfo`
2. Check if binary is in PATH: `:!which nil` (for Nix)
3. For devshell languages, make sure you're in the devshell

### Slow Startup

Check startup time:
```bash
nvim --startuptime /tmp/startup.log
nvim /tmp/startup.log
```

### Plugin Issues

Open lazy.nvim: `:Lazy`
- `U` - Update plugins
- `S` - Sync (install missing, remove unused)
- `X` - Clean unused
- `p` - Profile startup

### Reset Everything

```bash
rm -rf ~/.local/share/nvim  # Plugin data
rm -rf ~/.local/state/nvim  # State
rm ~/.config/nvim/init.lua  # Config (will regenerate on rebuild)
```

## Keybind Reference Card

### Leader Key: `<Space>`

| Prefix | Category |
|--------|----------|
| `<Space>f` | Find (telescope) |
| `<Space>g` | Git |
| `<Space>l` | LSP |
| `<Space>d` | Debug |
| `<Space>b` | Buffer |
| `<Space>w` | Window |
| `<Space>t` | Terminal |
| `<Space>s` | Session/Search |
| `<Space>x` | Diagnostics |
| `<Space>c` | Code |
| `<Space>q` | Quit |

Press `<Space>` and wait for which-key popup to see all options.
