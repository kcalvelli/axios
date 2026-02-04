# Proposal: Enhance Neovim as Full-Featured IDE

## Summary

Transform the minimal neovim bootstrap into a full-featured IDE experience while preserving user customization. Users get a productive environment out of the box with LSP, treesitter, fuzzy finding, git integration, debugging, AI assistance, and more—but can override or extend any part.

## Problem Statement

The current neovim configuration (`home/terminal/neovim.nix`) provides only a lazy.nvim bootstrap with basic settings. Users must manually configure all IDE features, which:
- Creates a high barrier to entry for NixOS users wanting a capable terminal editor
- Misses the opportunity to leverage Nix's reproducibility for a consistent IDE experience
- Doesn't integrate with axiOS features like `services.ai.enable` or devshells

## Proposed Solution

### Core Approach: Preset + Override Pattern

1. **axios provides a Lua preset** installed to the nix store and added to neovim's runtime path
2. **User's init.lua imports the preset** via `require("axios")` and can override any part
3. **Devshells inject language config** via environment variables that the preset reads
4. **AI features are conditional** based on `services.ai.enable`

### Plugin Categories

| Category | Plugins | Purpose |
|----------|---------|---------|
| Core | lazy.nvim, which-key | Plugin management, discoverability |
| LSP | nvim-lspconfig, mason.nvim (optional), cmp-nvim-lsp | Language intelligence |
| Completion | nvim-cmp, LuaSnip, friendly-snippets | Autocompletion |
| Syntax | nvim-treesitter | Semantic highlighting, text objects |
| Navigation | telescope.nvim, neo-tree.nvim | Fuzzy finding, file explorer |
| Git | gitsigns.nvim, lazygit.nvim, diffview.nvim | Version control |
| Debugging | nvim-dap, nvim-dap-ui | Debug adapter protocol |
| AI | avante.nvim | Cursor-like AI coding with Claude (conditional) |
| UI | lualine.nvim, bufferline.nvim, indent-blankline | Status, tabs, visual guides |
| Editing | nvim-autopairs, Comment.nvim, nvim-surround | Quality of life |
| Terminal | toggleterm.nvim | Integrated terminal |
| Session | auto-session | Workspace persistence |

### Devshell Integration

Devshells set `AXIOS_NVIM_LANGUAGES` environment variable:
```bash
# In rust devshell
export AXIOS_NVIM_LANGUAGES="rust"

# In zig devshell
export AXIOS_NVIM_LANGUAGES="zig"
```

The neovim preset reads this and:
- Ensures the appropriate LSP is configured (servers already in PATH from devshell)
- Enables language-specific treesitter parsers
- Configures debugger adapters

### Out-of-Box Languages

Nix support is always enabled (nil LSP, nix treesitter). Other languages activate when:
1. Explicitly in `AXIOS_NVIM_LANGUAGES`, OR
2. Their LSP binary is found in PATH

## Benefits

- **Immediate productivity**: Users get a working IDE without configuration
- **Reproducible**: Same experience across machines via Nix
- **Customizable**: Override any plugin, keybind, or setting
- **Integrated**: Works with axiOS devshells and AI module
- **Discoverable**: which-key shows available keybinds

## Non-Goals

- Not replacing user's existing neovim config (only bootstraps if no init.lua exists)
- Not managing LSP binaries via Mason (Nix handles this)
- Not supporting vim (neovim only)

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Config conflicts with user's existing setup | Only create if no init.lua exists; provide migration guide |
| Plugin bloat | Lazy-load everything; measure startup time |
| Breaking user customizations on update | Semantic versioning; changelog for preset updates |
| LSP not found in devshell | Graceful degradation; show helpful message |

## Success Criteria

1. Neovim starts in <100ms with lazy-loaded plugins
2. LSP completion works for Nix files immediately after install
3. Entering a rust devshell and opening a .rs file provides full Rust IDE features
4. Users can override any default with their own lua config
5. AI features only load when `services.ai.enable = true`

---

## Phase 2: Nix-Standard Remediation

### Problem

The initial implementation (Phase 1) delivered a working IDE but violated core Nix principles:

| Issue | Violation |
|-------|-----------|
| lazy.nvim git-cloned at runtime | Non-reproducible |
| Plugins downloaded from GitHub at runtime | Non-reproducible, requires internet |
| Treesitter parsers downloaded via `:TSInstall` | Non-reproducible |
| No hash verification of downloads | No integrity guarantees |

This contradicts the proposal's stated goal of "leveraging Nix's reproducibility" and design decision D2 which rejected Mason for being "non-reproducible."

### Remediation Approach

Migrate to home-manager's native plugin management:

```nix
programs.neovim = {
  plugins = with pkgs.vimPlugins; [
    # Core
    which-key-nvim

    # LSP & Completion
    nvim-lspconfig
    nvim-cmp
    cmp-nvim-lsp
    cmp-buffer
    cmp-path
    luasnip

    # Treesitter with pre-built parsers
    (nvim-treesitter.withPlugins (p: [
      p.nix p.lua p.rust p.zig p.go p.python
      p.typescript p.javascript p.json p.yaml p.markdown
      p.bash p.c p.cpp
    ]))
    nvim-treesitter-context

    # Navigation
    telescope-nvim
    telescope-fzf-native-nvim
    neo-tree-nvim

    # Git
    gitsigns-nvim
    lazygit-nvim
    diffview-nvim

    # UI
    lualine-nvim
    bufferline-nvim
    indent-blankline-nvim
    nvim-web-devicons

    # Editor
    nvim-autopairs
    comment-nvim
    nvim-surround
    flash-nvim
    todo-comments-nvim

    # Terminal
    toggleterm-nvim

    # Session
    auto-session
  ];

  extraLuaConfig = ''
    require("axios").setup({})
  '';
};
```

### Benefits of Remediation

1. **Reproducible**: Same plugins across all machines via nix flake.lock
2. **Offline**: Works without internet after initial build
3. **Deterministic**: Hash-verified plugins from nixpkgs
4. **Fast startup**: Plugins pre-installed, no download checks
5. **Consistent with axiOS**: Follows same patterns as other modules

### Migration Strategy

1. Keep `axios-nvim-preset` for Lua configuration (keymaps, options, plugin setup)
2. Move plugin installation from lazy.nvim to `programs.neovim.plugins`
3. lazy.nvim removed - plugins managed entirely by Nix
4. Treesitter parsers provided by Nix via `withPlugins`, no runtime downloads
5. User customization via `extraLuaConfig` or managed init.lua

### Updated Success Criteria (Phase 2)

1. All plugins installed via Nix, zero runtime downloads
2. Works fully offline after `nixos-rebuild`
3. Neovim starts in <100ms
4. LSP, treesitter, and all features work identically to Phase 1
5. Users can still customize via their init.lua

## Related Specs

- `openspec/specs/development/spec.md` - Development environment spec (to be extended)
- `openspec/specs/ai/spec.md` - AI module integration
