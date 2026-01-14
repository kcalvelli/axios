# Development Environment

## Purpose
Provides a comprehensive development environment with modern tools, optimized system tuning, and extensible developer shells.

## Components

### System Tuning
- **File Watchers**: `fs.inotify.max_user_watches` increased to 524,288 to support large IDE projects and hot-reloading tools (CRA, Vite, cargo-watch).
- **Implementation**: `modules/development/default.nix`

### Core Tooling
- **Editors**: Visual Studio Code (with material theme integration), Vim.
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
- **Implementation**: `devshells/`

## Requirements
- **Nix Flakes**: The entire development environment relies on Nix flakes for reproducibility.
- **Interactive Shell**: The development module automatically switches the interactive bash shell to Fish.
