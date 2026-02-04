# Development Environment

## Purpose
Provides a comprehensive development environment with modern tools, optimized system tuning, extensible developer shells, and a full-featured neovim IDE.

## Components

### System Tuning
- **File Watchers**: `fs.inotify.max_user_watches` increased to 524,288 to support large IDE projects and hot-reloading tools (CRA, Vite, cargo-watch).
- **Implementation**: `modules/development/default.nix`

### Core Tooling
- **Editors**: Neovim (with axios IDE preset), Visual Studio Code (with material theme integration).
- **Languages/Runtimes**: Node.js, Bun (for theme updates), Python3, UV.
- **Shell**: Fish (interactive default), Starship prompt, Bat, Eza, Jq, Fzf.
- **Version Control**: Git, GitHub CLI (`gh`).
- **Implementation**: `modules/development/default.nix`, `home/terminal/`

### Workflow Automation
- **Direnv/Lorri**: Automatic environment loading based on directory.
- **VSCode Server**: Support for remote development.
- **Implementation**: `modules/development/default.nix`

### Developer Shells (DevShells)
- **Profiles**: Pre-configured shells for Rust, Zig, QML, etc.
- **Access**: `nix develop .#profile-name`.
- **Neovim Integration**: Devshells set `AXIOS_NVIM_LANGUAGES` to auto-configure IDE features.
- **Implementation**: `devshells/`

## ADDED Requirements

### Requirement: Neovim IDE Preset

axiOS SHALL provide a comprehensive neovim IDE preset that delivers a productive development environment out of the box while allowing full user customization.

#### Scenario: Fresh installation with no existing neovim config
- **Given** the user has no `~/.config/nvim/init.lua`
- **When** home-manager activates
- **Then** an init.lua is generated that loads the axios preset via `require("axios").setup({})`
- **And** the user can edit this file to customize their experience

#### Scenario: Existing neovim configuration
- **Given** the user has an existing `~/.config/nvim/init.lua`
- **When** home-manager activates
- **Then** the existing init.lua MUST be preserved unchanged
- **And** the user can opt-in by adding `require("axios").setup({})` to their config

#### Scenario: User customizes preset
- **Given** the user has the axios preset loaded
- **When** they pass options to `require("axios").setup({ colorscheme = "tokyonight" })`
- **Then** the preset MUST respect their overrides
- **And** defaults are used for unspecified options

### Requirement: LSP Auto-Configuration

The neovim preset SHALL automatically configure LSP based on language detection.

#### Scenario: Nix files (always enabled)
- **Given** the user opens a `.nix` file
- **When** the buffer is loaded
- **Then** nil_ls LSP MUST attach automatically
- **And** completion, diagnostics, and go-to-definition work

#### Scenario: Devshell language detection
- **Given** the user enters a rust devshell (`nix develop .#rust`)
- **And** `AXIOS_NVIM_LANGUAGES` is set to `"rust,toml"`
- **When** they open a `.rs` file in neovim
- **Then** rust-analyzer LSP MUST attach (using the binary from devshell PATH)
- **And** Rust-specific treesitter highlighting MUST be enabled

#### Scenario: LSP binary not found
- **Given** the user opens a `.rs` file outside a devshell
- **And** rust-analyzer is not in PATH
- **When** the buffer is loaded
- **Then** no LSP SHALL attach
- **And** a non-intrusive message SHOULD indicate rust-analyzer is not available
- **And** syntax highlighting via treesitter still works

### Requirement: AI-Powered Coding (Conditional)

AI coding features SHALL be enabled only when the system AI module is active, using avante.nvim for a Cursor-like experience.

#### Scenario: AI module enabled
- **Given** the system has `services.ai.enable = true`
- **And** `AXIOS_AI_ENABLED=1` is set in the environment
- **When** the user starts neovim
- **Then** avante.nvim MUST be available via `<leader>a` keymaps
- **And** Claude SHALL be the default AI provider

#### Scenario: AI module disabled
- **Given** the system has `services.ai.enable = false`
- **And** `AXIOS_AI_ENABLED` is not set
- **When** the user starts neovim
- **Then** avante.nvim SHALL NOT be loaded
- **And** `<leader>a` keymaps MUST NOT be registered

#### Scenario: Claude auth_type configuration
- **Given** the user configures `ai.claude.auth_type = "max"` in setup
- **When** avante.nvim initializes
- **Then** it MUST use the Claude Max subscription authentication
- **And** benefit from higher rate limits

### Requirement: Plugin Lazy-Loading

All plugins SHALL be lazy-loaded to ensure fast startup.

#### Scenario: Startup time
- **Given** a fresh neovim installation with the axios preset
- **When** neovim starts with no file argument
- **Then** startup MUST complete in under 100ms
- **And** only essential UI plugins are loaded

#### Scenario: Plugin loading on demand
- **Given** the user has not used telescope
- **When** they press `<leader>ff` (find files)
- **Then** telescope.nvim MUST load on first use
- **And** the file picker opens

### Requirement: Discoverable Keybindings

All keybindings SHALL be documented via which-key and follow mnemonic patterns.

#### Scenario: Keybind discovery
- **Given** the user is in normal mode
- **When** they press `<leader>` and wait
- **Then** which-key popup MUST appear showing available prefixes
- **And** each prefix MUST be labeled (f=Find, g=Git, l=LSP, etc.)

#### Scenario: Keybind prefix groups
- **Given** the which-key popup is visible
- **When** the user presses `g` (git prefix)
- **Then** all git-related keybinds MUST be shown
- **And** each MUST have a description

### Requirement: Devshell Neovim Integration

Devshells SHALL configure neovim for their tech stack automatically.

#### Scenario: Rust devshell
- **Given** the user enters the rust devshell
- **When** neovim is started
- **Then** rust-analyzer LSP MUST be auto-configured
- **And** codelldb debugger MUST be available for DAP
- **And** Rust treesitter parser MUST be active

#### Scenario: Zig devshell
- **Given** the user enters the zig devshell
- **When** neovim is started
- **Then** zls LSP MUST be auto-configured
- **And** Zig treesitter parser MUST be active

## Baseline Requirements (unchanged)
- **Nix Flakes**: The entire development environment relies on Nix flakes for reproducibility.
- **Interactive Shell**: The development module automatically switches the interactive bash shell to Fish.

## Keybind Reference

| Keybind | Action | Plugin |
|---------|--------|--------|
| `<leader>ff` | Find files | telescope |
| `<leader>fg` | Live grep | telescope |
| `<leader>fb` | Buffers | telescope |
| `<leader>fh` | Help tags | telescope |
| `<leader>e` | Toggle file explorer | neo-tree |
| `<leader>gg` | Open lazygit | lazygit.nvim |
| `<leader>gd` | Diff view | diffview |
| `<leader>gb` | Git blame line | gitsigns |
| `<leader>lf` | Format buffer | LSP |
| `<leader>lr` | Rename symbol | LSP |
| `<leader>la` | Code action | LSP |
| `<leader>ld` | Diagnostics | telescope |
| `<leader>db` | Toggle breakpoint | DAP |
| `<leader>dc` | Continue | DAP |
| `<leader>ds` | Step over | DAP |
| `<leader>di` | Step into | DAP |
| `<leader>dr` | Open REPL | DAP |
| `<leader>aa` | Toggle Avante panel | avante |
| `<leader>ae` | Edit with AI | avante |
| `<leader>ar` | Refresh Avante | avante |
| `<leader>af` | Focus Avante | avante |
| `<leader>tt` | Toggle terminal | toggleterm |
| `gd` | Go to definition | LSP |
| `gr` | Go to references | LSP |
| `K` | Hover documentation | LSP |
| `[d` / `]d` | Previous/next diagnostic | LSP |
