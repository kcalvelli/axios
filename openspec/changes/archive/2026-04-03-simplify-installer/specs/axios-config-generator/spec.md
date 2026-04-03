## MODIFIED Requirements

### Requirement: Gum-based TUI replaces ANSI prompts
The installer SHALL use gum (charmbracelet/gum) for all user interaction, providing styled boxes, spinners, input prompts, choice selectors, and multi-select screens.

#### Scenario: Gum not available
- **WHEN** user runs the script without gum on PATH
- **THEN** installer prints an error directing the user to `nix run github:kcalvelli/axios#init`
- **AND** exits with code 1

### Requirement: Dual-mode startup
The installer SHALL present a mode selection at startup: "New configuration" or "Add host to existing config".

#### Scenario: New configuration (Mode A)
- **WHEN** user selects "New configuration"
- **THEN** installer runs the full new-config flow (hardware detection, system info, user creation, features, generation, git init + commit)
- **AND** generates files in `~/.config/nixos_config`

#### Scenario: Add host to existing config (Mode B)
- **WHEN** user selects "Add host to existing config"
- **THEN** installer prompts for git URL, clones the repo, scans existing hosts/users, collects new host info, generates host files, inserts into flake.nix, and commits

### Requirement: Flat feature multi-select
The installer SHALL present all optional features in a single `gum choose --no-limit` screen, replacing individual yes/no prompts and nested virtualization sub-options.

#### Scenario: Feature selection
- **WHEN** user reaches the features screen
- **THEN** they see: Gaming, PIM, Secrets, Virtualization - libvirt/KVM, Virtualization - Containers (Podman)
- **AND** `ENABLE_VIRT` is derived as true if either virt option is selected

### Requirement: CLI help flag
The installer SHALL support `--help` / `-h` flags that print usage information and exit with code 0.

#### Scenario: Help invocation
- **WHEN** user runs `nix run .#init -- --help`
- **THEN** installer prints usage text and exits 0

### Requirement: Auto git operations
The installer SHALL automatically initialize a git repo and create an initial commit (Mode A), or commit the new host files (Mode B).

### Requirement: Mode B user assignment
In Mode B, the installer SHALL scan existing `users/*.nix` files and allow the user to assign existing users to the new host via multi-select, with an option to create new users.

### Requirement: Mode B flake.nix auto-insertion
In Mode B, the installer SHALL find the last `mkHost` line in flake.nix and insert the new host entry after it. If the host already exists or mkHost is not found, it SHALL warn and provide manual instructions.

## UNCHANGED Requirements

- Hardware detection logic (CPU, GPU, form factor, SSD, timezone)
- Template-based file generation (same templates, same output format)
- NVIDIA kernel pre-flight check
- Secrets directory creation with README
- Generated directory structure (`hosts/`, `users/`, `flake.nix`, `README.md`, `.gitignore`)
