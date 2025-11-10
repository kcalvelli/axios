# axiOS Project Context

## Overview

axiOS is a **modular NixOS distribution** implemented as a Nix flake library. It provides reusable NixOS and home-manager modules for building customized NixOS systems with opinionated configurations.

**Key Philosophy**: This is a library/framework, not a personal configuration. Design decisions should avoid hardcoding personal preferences or regional defaults.

## Project Structure

```
axios/
├── flake.nix              # Main flake with inputs and outputs
├── flake.lock             # Locked dependency versions
├── modules/               # NixOS modules
│   ├── default.nix        # Module registry
│   ├── system/            # System configuration (locale, users, etc.)
│   ├── desktop/           # Desktop environment
│   ├── development/       # Development tools
│   ├── gaming/            # Gaming configuration
│   ├── graphics/          # GPU configuration
│   ├── networking/        # Network services (samba, tailscale)
│   ├── virtualisation/    # Libvirt, containers
│   └── wayland/           # Wayland compositor
├── home/                  # home-manager modules
│   ├── default.nix        # Home module registry
│   ├── ai/                # AI tools and MCP configuration
│   ├── profiles/          # User profiles (workstation, laptop)
│   ├── secrets/           # agenix secrets management
│   └── wayland/           # Wayland home configuration
├── pkgs/                  # Custom packages
├── devshells/             # Development shells (rust, zig, qml)
├── lib/                   # Library functions
└── scripts/               # Helper scripts and templates
    ├── init-config.sh     # Interactive configuration generator
    └── templates/         # Configuration templates
```

## Module Architecture

### Module Structure Pattern

**ALL modules follow this consistent pattern:**

```
modules/module-name/
├── default.nix           # Core module logic
├── aspect1.nix           # Optional: specific functionality
└── aspect2.nix           # Optional: specific functionality
```

**Example:**
```
modules/networking/
├── default.nix           # Core networking config
├── samba.nix             # Samba-specific config
└── tailscale.nix         # Tailscale-specific config
```

### Module Pattern Rules

1. **Directory-based**: Each module is a directory with `default.nix`
2. **No separate applications.nix**: Package lists stay inline within `config = lib.mkIf cfg.enable { ... }` blocks
3. **Conditional evaluation**: Packages MUST be inside mkIf blocks to avoid evaluating disabled modules
4. **Aspect files**: Additional .nix files in the module directory are imported by default.nix
5. **Helper modules exempt**: Files like `modules/users.nix` that are pure helpers don't follow this pattern

### Module Template

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.MODULE_NAME;
in
{
  options.MODULE_NAME = {
    enable = lib.mkEnableOption "Description";
    # Additional options...
  };

  config = lib.mkIf cfg.enable {
    # Configuration here

    # Packages inline (NOT in separate file)
    environment.systemPackages = with pkgs; [
      package1
      package2
    ];
  };
}
```

## Key Architectural Decisions

### 1. No Regional Defaults

**Required user configuration:**
- `axios.system.timeZone` - User MUST set their timezone (no default)
- `axios.system.locale` - Defaults to en_US.UTF-8 but configurable

**Rationale**: Library shouldn't hardcode regional preferences

### 2. Packages Inline, Not Imported

**WRONG:**
```nix
# default.nix
imports = [ ./applications.nix ];

# applications.nix (imported unconditionally)
environment.systemPackages = [ ... ];
```

**CORRECT:**
```nix
# default.nix
config = lib.mkIf cfg.enable {
  environment.systemPackages = with pkgs; [
    # packages here - only evaluated when enabled
  ];
};
```

### 3. System Reference Pattern

Use `${pkgs.stdenv.hostPlatform.system}` instead of deprecated `${system}`:

```nix
# CORRECT
inputs.something.packages.${pkgs.stdenv.hostPlatform.system}.package-name

# WRONG (deprecated)
inputs.something.packages.${system}.package-name
```

### 4. Home-Manager Integration

- Home modules mirror NixOS module structure
- Use `osConfig.services.ai.enable or false` to check system-level config
- Automatic MCP server configuration via home activation scripts

## Important Inputs

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  home-manager;
  nix-ai-tools;      # AI tools (claude-code, copilot-cli)
  dankMaterialShell; # DMS/Niri shell
  mcp-journal;       # MCP server for journal access
  agenix;            # Secrets management
  lanzaboote;        # Secure boot
  disko;             # Declarative disk partitioning
  # ... more in flake.nix
}
```

## Common Operations

### Adding a New Module

1. Create `modules/module-name/default.nix`
2. Follow the module template pattern
3. Add to `modules/default.nix` registry:
   ```nix
   flake.nixosModules = {
     module-name = ./module-name;
   };
   ```
4. Keep packages inline within `mkIf` blocks

### Working with Hosts

Host configurations are external (in downstream repos), axios provides modules:

```nix
# In a host configuration
{
  imports = [ inputs.axios.nixosModules.desktop ];

  axios.system.timeZone = "America/New_York";  # Required
  desktop.enable = true;
}
```

### DevShells

Available development shells:
- `rust` - Rust development with fenix overlay
- `zig` - Zig development with latest Zig
- `qml` - Qt/QML development

Access via: `nix develop .#rust`

### Scripts

- `nix run .#init` - Interactive configuration generator
  - Prompts for hostname, username, timezone, modules
  - Generates host configuration from templates
  - Detects system timezone automatically

## File Naming Conventions

- Module directories: lowercase, hyphenated (`module-name/`)
- NixOS modules: `modules/module-name/default.nix`
- Home modules: `home/module-name/default.nix`
- Helper scripts: `scripts/script-name.sh`
- Templates: `scripts/templates/name.template`

## Testing & CI

GitHub Actions workflows provide automated testing and validation:

### Core Validation Workflows

**Flake Check** (`.github/workflows/flake-check.yml`)
- Validates flake structure with `nix flake check --all-systems`
- Builds example configurations (minimal-flake, multi-host) with dry-run
- Triggers: push to master, PRs, manual
- Uses Cachix for build acceleration

**Code Formatting** (`.github/workflows/formatting.yml`)
- Checks Nix code formatting with `nix fmt -- --check`
- Triggers: push to master/PRs on `**.nix` files, manual
- Provides helpful fix instructions on failure

**Test Init Script** (`.github/workflows/test-init-script.yml`)
- Tests `nix run .#init` command functionality
- Triggers: push to master/PRs on `scripts/**` or `flake.nix`, manual

### Build Workflows

**Build DevShells** (`.github/workflows/build-devshells.yml`)
- Builds all development shells (rust, zig, qml, etc.)
- Lists available shells with `nix flake show`
- Triggers: push to master/PRs on `devshells/**`, `devshells.nix`, `flake.*`, manual

### Dependency Management

**Update flake.lock** (`.github/workflows/flake-lock-updater.yml`)
- Weekly automated flake.lock updates (Mondays 6 AM UTC)
- Creates PRs with validation and manual testing instructions
- Runs `nix flake check` for structure validation
- Includes comprehensive PR body with testing requirements
- Triggers: weekly cron schedule, manual

**Update flake.lock (Direct)** (`.github/workflows/flake-lock-updater-direct.yml`)
- Alternative direct-commit workflow (disabled by default)
- Triggers: manual only

### CI Infrastructure

All workflows use:
- DeterminateSystems/nix-installer-action for Nix installation
- DeterminateSystems/magic-nix-cache-action for caching
- Cachix (axios cache) for build artifact storage (where applicable)

### Manual Testing

**Important**: CI validates structure but not actual builds. Use `./scripts/test-build.sh` for full validation before merging dependency updates.

## AI Module Specifics

The `services.ai.enable` module provides:
- **Tools**: claude-code, claude-desktop, copilot-cli, mcp-chat, claude-monitor
- **Services**: Ollama (local LLM), Open WebUI (web interface)
- **MCP Servers**: journal, mcp-nixos, sequential-thinking, context7, filesystem
- **mcpo proxy**: Exposes MCP servers as OpenAPI at 127.0.0.1:8000

### MCP Configuration

- User-scoped: `~/.config/claude/mcp.json` (via home activation)
- Project-scoped: `.mcp.json` (created per-project)
- mcpo config: `~/.config/mcpo/config.json`

## Common Patterns

### Checking if AI module is enabled (in home-manager)

```nix
config = lib.mkIf (osConfig.services.ai.enable or false) {
  # home configuration
};
```

### Module imports in flake

```nix
# modules/default.nix
flake.nixosModules = {
  system = ./system;
  desktop = ./desktop;        # Directory, not .nix file
  development = ./development;
};
```

### Using nix-ai-tools packages

```nix
environment.systemPackages = [
  inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
];
```

## Notes for AI Assistants

When working on this project:
- Always follow the module structure pattern
- Keep packages inside mkIf blocks
- Use `${pkgs.stdenv.hostPlatform.system}` not `${system}`
- This is a library - avoid hardcoded personal preferences
- Check `modules/default.nix` for module registry
- Host configs are downstream - axios provides modules only
