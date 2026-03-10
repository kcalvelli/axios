## Why

Several modules install the same packages that are already provided by home-manager `programs.*` declarations or by other modules, resulting in redundant Nix store entries and a larger system closure. Additionally, some packages are installed unconditionally (outside `mkIf` blocks), violating the framework's conditional evaluation pattern.

## What Changes

- **Remove duplicate CLI tools from `modules/development/default.nix`**: eza, fzf, gh, fish, starship, and neovim are already configured via home-manager `programs.*` (which provides the binary plus shell integration, aliases, and config management). The system-level installs are pure redundancy.
- **Remove duplicate neovim from `modules/development/default.nix`**: home-manager's `programs.neovim` in `home/terminal/neovim/` provides a fully configured neovim with LSPs and plugins.
- **Remove gtop from `modules/system/default.nix`**: btop (in development module) is a strict superset. Move btop to the system module so it's available without development enabled, then drop gtop.
- **Remove mtr from `modules/development/default.nix`**: The networking module already enables `programs.mtr.enable = true`, which provides the binary with proper capabilities (suid/setcap).
- **Deduplicate python3+uv in `modules/ai/default.nix`**: Both server and client role blocks install these identically. Lift to the base `local.enable` config block.
- **Wrap cachix in mkIf in `modules/system/nix.nix`**: Currently installed unconditionally. The cache substituters work without the CLI; the CLI is only needed for manual cache management.

## Capabilities

### New Capabilities

_None — this is a cleanup/removal change._

### Modified Capabilities

- `development`: Removing redundant system packages that home-manager already provides.
- `system`: Replacing gtop with btop; making cachix conditional.

## Impact

- **modules/development/default.nix**: Remove 7 packages (neovim, starship, fish, bat, eza, fzf, gh) and 1 duplicate (mtr)
- **modules/system/default.nix**: Remove gtop, add btop
- **modules/system/nix.nix**: Wrap cachix in conditional
- **modules/ai/default.nix**: Refactor python3+uv into shared block
- No API/option changes — purely internal cleanup
- Downstream systems see smaller closures with identical functionality
