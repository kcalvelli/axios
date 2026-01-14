# axiOS Project Context

## 📋 OpenSpec SDD Workflow

**IMPORTANT**: This project follows a **Spec-Driven Development (SDD)** workflow using **OpenSpec**. All work must be planned as a delta before implementation.

### Source of Truth Documentation

**Primary Reference**: The `openspec/` directory contains the authoritative state of the project:

- **[project.md](../openspec/project.md)** - Project goals, tech stack, and the Constitution (rules).
- **[AGENTS.md](../openspec/AGENTS.md)** - Specific instructions for AI agents.
- **[specs/](../openspec/specs/)** - Modular specifications for all system features.
- **[glossary.md](../openspec/glossary.md)** - Domain terminology and NixOS concepts.
- **[discovery/](../openspec/discovery/)** - Historical discovery reports and tracked unknowns.

### Workflow for Changes (The Delta Process)

**1. Discovery & Planning:**
- Read `openspec/specs/` to understand the current state.
- Create a new directory in `openspec/changes/[change-name]/`.
- Stage updated spec files and a `tasks.md` implementation plan.

**2. Implementation:**
- Execute the tasks defined in `tasks.md`.
- Ensure all code complies with the Constitution in `openspec/project.md`.

**3. Finalization:**
- Merge the delta specs into the main `openspec/specs/` directory.
- Move the change directory to `openspec/changes/archive/`.

### Quick Reference for AI Assistants

When asked to work on axiOS:
- **Core Rules & Goals** → `openspec/project.md`
- **Your Workflow** → `openspec/AGENTS.md`
- **Feature Specs** → `openspec/specs/[feature]/spec.md`
- **Terminology** → `openspec/glossary.md`

## Overview

axiOS is a **modular NixOS distribution** implemented as a Nix flake library. It provides reusable NixOS and home-manager modules for building customized NixOS systems with opinionated configurations.

**Key Philosophy**: This is a library/framework, not a personal configuration. Design decisions should avoid hardcoding personal preferences or regional defaults.

**For complete architecture details**, see [openspec/specs/](../openspec/specs/)

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
│   ├── pim/               # Personal Information Management (email, calendar, contacts)
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

### Module Import Pattern (lib/default.nix)

**CRITICAL**: When adding a new module, you MUST update TWO locations:

1. **Register in modules/default.nix** (flake output):
   ```nix
   flake.nixosModules = {
     myNewModule = ./my-new-module;
   };
   ```

2. **Import in lib/default.nix** (buildModules function):

Modules fall into THREE categories:

**Category 1: Core Modules (Always Imported)**
- Modules that provide options but don't require a `modules.X` flag
- Users configure them directly in `extraConfig`
- Add to `coreModules` list in lib/default.nix

```nix
coreModules = with self.nixosModules; [
  crashDiagnostics  # Always available for extraConfig.hardware.crashDiagnostics
  hardware          # Parent hardware module
  myNewModule       # Add here if always-available
];
```

**Category 2: Flagged Modules (Conditional on modules.X)**
- Modules controlled by `modules.X = true/false` in host config
- Add to `flaggedModules` list in lib/default.nix

```nix
flaggedModules = with self.nixosModules;
  lib.optional (hostCfg.modules.system or true) system
  ++ lib.optional (hostCfg.modules.myNewModule or false) myNewModule;  # Add here
```

**Category 3: Conditional Hardware Modules**
- Modules imported based on hardware.vendor or formFactor
- Add to `conditionalHwModules` with appropriate condition

```nix
conditionalHwModules = with self.nixosModules;
  lib.optional (hostCfg.hardware.vendor or null == "myvendor") myVendorModule;
```

**Decision Guide:**
- **Core**: Module provides optional configuration (like crashDiagnostics) → Add to `coreModules`
- **Flagged**: Module is a major feature users explicitly enable → Add to `flaggedModules`
- **Conditional**: Module auto-enables based on hardware detection → Add to `conditionalHwModules`

**Example: Adding a new "monitoring" module**
```nix
# 1. Create modules/monitoring/default.nix
# 2. Register in modules/default.nix:
flake.nixosModules.monitoring = ./monitoring;

# 3. Import in lib/default.nix (flaggedModules):
++ lib.optional (hostCfg.modules.monitoring or false) monitoring
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
- Declarative MCP server configuration via `programs.claude-code.mcpServers`

## Important Inputs

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  home-manager;
  mcp-servers-nix;   # MCP server configuration library and packages
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

### Formatting Code

**IMPORTANT for AI Tools**: Always use explicit directory targets when formatting to avoid ambiguity.

**Format all files:**
```bash
nix fmt .              # Explicit current directory (RECOMMENDED)
# OR
./scripts/fmt.sh       # Helper script wrapper
```

**Check formatting (CI/validation):**
```bash
nix fmt -- --fail-on-change .   # Explicit current directory
# OR
./scripts/fmt.sh --check
```

**NEVER use:**
```bash
nix fmt               # NO ARGUMENT - may be ambiguous for AI tools
```

**Technical Details:**
- Formatter: nixfmt-rfc-style via treefmt-nix
- Configuration: flake.nix:149-152
- CI validation: .github/workflows/formatting.yml
- The `.` argument ensures the command targets the current directory tree explicitly

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
- **Tools**: claude-code, gemini-cli, claude-monitor, mcp-cli, and other AI assistants
- **MCP Servers** (optional): Enable with `services.ai.mcp.enable = true` (default: true)
- **Dynamic Discovery**: mcp-cli for just-in-time tool discovery (99% token reduction)
- **Architecture**: Uses `mcp-servers-nix` library for declarative MCP server configuration

### MCP Configuration

**Enable/Disable**: MCP servers are enabled by default when `services.ai.enable = true`. To disable:
```nix
{
  services.ai.enable = true;
  services.ai.mcp.enable = false;  # Disable MCP servers
}
```

**Architecture**:
- **Declarative**: MCP servers configured in `home/ai/mcp.nix`
- **Library-based**: Uses `inputs.mcp-servers-nix.lib.evalModule` to generate tool-specific configs
- **Multi-tool ready**: Can generate configs for Claude Code
- **Pre-packaged servers**: MCP servers from `mcp-servers-nix` overlay (no runtime downloads)
- **Security**: Supports `passwordCommand` for secrets (e.g., GitHub token via `gh auth token`)

### MCP Server Categories

**All MCP server requirements are documented in `home/ai/mcp.nix`**

1. **Core Tools** (no setup required): git, github†, filesystem, time, journal, nix-devshell-mcp, ultimate64‡
2. **AI Enhancement** (no setup required): sequential-thinking, context7
3. **Search** (requires API key): brave-search

**†** github requires `gh auth login` first
**‡** ultimate64 requires Ultimate64 hardware on local network

### Configuring API Key for Brave Search

The brave-search MCP server requires a Brave Search API key. Configure it in your downstream config using agenix:

**1. Create encrypted secret file** (in your config repo, e.g., `~/.config/nixos_config`):
```bash
# Create secrets directory
mkdir -p secrets

# Encrypt your API key (requires your SSH key in age.identityPaths)
echo "your-brave-api-key" | agenix -e secrets/brave-api-key.age
```

**2. Configure secret in your home-manager config**:
```nix
{
  # Enable secrets
  secrets.enable = true;

  # Register API key secret
  age.secrets.brave-api-key = {
    file = ./secrets/brave-api-key.age;
  };
}
```

axios will automatically use `passwordCommand` to securely load this secret. If the secret isn't configured, it falls back to the environment variable `$BRAVE_API_KEY`.

### Dynamic Tool Discovery with mcp-cli

**What is mcp-cli?**

mcp-cli is a lightweight command-line interface for the Model Context Protocol that enables **dynamic tool discovery** for AI agents. It solves a critical problem: traditional MCP integration loads all tool definitions upfront into the agent's context window, consuming massive token allocations.

**Token Reduction:**
- Traditional MCP: ~47,000 tokens for 6 servers with 60 tools
- With mcp-cli: ~400 tokens (99% reduction!)

**How it works:**

Instead of loading all tool schemas at once, AI agents can use mcp-cli to discover tools on-demand:

```bash
# List all available MCP servers
mcp-cli

# Search for specific tools
mcp-cli grep "search"

# Get tool schema
mcp-cli github/search

# Execute tool with arguments
mcp-cli github/search '{"query": "axios", "path": "README.md"}'

# Use stdin for complex JSON
echo '{"query": "test"}' | mcp-cli server/tool -
```

**Integration:**

mcp-cli is **automatically enabled** when `services.ai.enable = true`. axios automatically generates:
- `~/.mcp.json` - Claude Code native MCP configuration
- `~/.config/mcp/mcp_servers.json` - mcp-cli configuration (same server definitions)
- `~/.config/ai/prompts/axios.md` - Comprehensive system prompt (auto-injected into Claude Code)

Both MCP config files use the same declarative server configuration from `home/ai/mcp.nix`.

**Zero Configuration Required:**
- After system rebuild, the axios prompt is automatically injected into `~/.claude.json`
- Just restart Claude Code to pick up the new system prompt
- No manual setup or configuration needed!

**axiOS System Prompt for AI Agents:**

axios provides a comprehensive system prompt at `~/.config/ai/prompts/axios.md` that teaches AI agents about all axiOS features:

- **mcp-cli usage** - Dynamic MCP tool discovery commands and workflow
- **Available MCP servers** - List of configured servers and their purposes
- **NixOS-specific guidance** - How to work with Nix configurations
- **Custom user instructions** - Section at bottom for users to append their own

**Claude Code: AUTOMATIC INTEGRATION**

The axios prompt is **automatically injected** into `~/.claude.json` when you rebuild your system. No manual setup required!

**How it works:**
- During `home-manager switch`, an activation script checks `~/.claude.json`
- If the axios prompt isn't present, it's automatically appended to `customInstructions`
- If you already have custom instructions, axios adds its prompt after a separator (`---`)
- Restart Claude Code after rebuild to pick up the new prompt

**View the prompt:**
```bash
cat ~/.config/ai/prompts/axios.md
```

**Gemini CLI:**
Use the `--system-instruction` flag:
```bash
gemini-cli --system-instruction ~/.config/ai/prompts/axios.md

# Or create an alias
alias gemini='gemini-cli --system-instruction ~/.config/ai/prompts/axios.md'
```

**Adding Your Own Custom Instructions:**

**Method 1: Edit axios prompt directly** (recommended)
```bash
# Edit the axios prompt to add your custom instructions
$EDITOR ~/.config/ai/prompts/axios.md
# Add your instructions under "## Custom User Instructions" section at the bottom
# Next rebuild will inject the updated prompt into ~/.claude.json
```

**Method 2: Edit ~/.claude.json directly**
```bash
# Manually edit Claude Code config (bypasses auto-injection)
$EDITOR ~/.claude.json
# Add your custom instructions to the "customInstructions" field
# Note: axios activation script won't modify if axios prompt is already present
```

**Method 3: Merge prompts for other AI agents**
```bash
# Create a combined prompt file for Gemini CLI or other tools
cat ~/.config/ai/prompts/axios.md > ~/my-ai-prompt.md
echo "" >> ~/my-ai-prompt.md
cat ~/my-custom-instructions.md >> ~/my-ai-prompt.md
```

**Usage in AI Agents:**

Once enabled, AI agents can invoke mcp-cli via the Bash tool for just-in-time tool discovery:
1. Agent searches for relevant tools: `mcp-cli grep "file"`
2. Agent inspects tool schema: `mcp-cli filesystem/read_file`
3. Agent executes with proper arguments: `mcp-cli filesystem/read_file '{"path": "/tmp/test.txt"}'`

This approach dramatically reduces context window usage and enables using many more MCP servers simultaneously.

**Benefits:**
- ✅ 99% reduction in context token usage
- ✅ Lower API costs (fewer tokens per request)
- ✅ Support for 20+ MCP servers without hitting limits
- ✅ No configuration needed - works automatically with existing MCP setup
- ✅ Complements (not replaces) native Claude Code MCP integration

**References:**
- Package: `pkgs/mcp-cli/default.nix`
- Configuration: `home/ai/mcp.nix:230-268`
- **System Prompts:**
  - `home/ai/prompts/axios-system-prompt.md` → `~/.config/ai/prompts/axios.md` (comprehensive, auto-injected)
  - `home/ai/prompts/mcp-cli-system-prompt.md` → `~/.config/ai/prompts/mcp-cli.md` (mcp-cli only)
- Auto-injection: `home/ai/mcp.nix:242-268` (home.activation.injectAxiosPrompt)
- Upstream: https://github.com/philschmid/mcp-cli

## Common Patterns

### Checking if AI module is enabled (in home-manager)

```nix
# Check if AI tools are enabled
config = lib.mkIf (osConfig.services.ai.enable or false) {
  # home configuration for AI tools
};

# Check if MCP servers are enabled
config = lib.mkIf (osConfig.services.ai.mcp.enable or false) {
  # home configuration for MCP servers
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

### Using AI tools from nixpkgs

```nix
environment.systemPackages = with pkgs; [
  claude-code
  claude-code-acp
  claude-code-router
  gemini-cli-bin
  spec-kit
  opencode  # For local LLM integration
];
```

## Notes for AI Assistants

### ⛔ CRITICAL: OpenSpec Consultation REQUIRED ⛔

**ABSOLUTE REQUIREMENT - NO EXCEPTIONS:**

**BEFORE taking ANY action in this repository, you MUST:**
1. **STOP** - Do not proceed without consulting `openspec/`.
2. **READ** `openspec/project.md` and `openspec/AGENTS.md`.
3. **PLAN** your change as a delta in `openspec/changes/`.

**If you did not read OpenSpec documentation before this action, STOP NOW and read it first.**

### OpenSpec Workflow (MANDATORY)

1. **Discovery**: Read relevant specs in `openspec/specs/`.
2. **Delta**: Create `openspec/changes/[name]/` with updated specs and `tasks.md`.
3. **Execute**: Implement the code as defined in your tasks.

**Non-Negotiable Rules** (from [project.md](../openspec/project.md)):
- Always follow the module structure pattern (directory-based with default.nix)
- Keep packages inside mkIf blocks (conditional evaluation)
- Use `${pkgs.stdenv.hostPlatform.system}` not `${system}`
- This is a library - avoid hardcoded personal preferences
- NO regional defaults - users MUST set timezone explicitly
- Check `modules/default.nix` for module registry

**When uncertain**: Check `unknowns.md` - if your question is listed, acknowledge the gap and propose a solution for human review.

### Documentation Maintenance

**If you modify code, you MUST update specs via the delta process:**
- New features → Update/Create files in `openspec/specs/`.
- Change patterns → Update `openspec/project.md` if constitutional.
- Resolve unknowns → Update documents in `openspec/discovery/`.

### Confidence Markers

Use these when updating baseline docs:
- `[EXPLICIT]` - Found directly in code/documentation
- `[INFERRED]` - Derived from code patterns with high confidence
- `[ASSUMED]` - Best guess based on standard conventions
- `[TBD]` - Insufficient evidence, requires human input

### Quick Reference Card

This document provides **quick reference** for common operations. For comprehensive information:

| Need | Quick Reference Below | Detailed Documentation |
|------|----------------------|------------------------|
| Core Rules | - | project.md |
| Workflows | ✓ Workflow for Changes | AGENTS.md |
| Module structure | ✓ Module Pattern Rules | project.md (ADR-001) |
| Feature Specs | - | specs/ |
| Testing/CI | ✓ Testing & CI | specs/ops/spec.md |
| Terminology | - | glossary.md |

---

## Quick Reference (Supplement to Baseline Docs)

The sections below provide quick access to common patterns. **For comprehensive details, always refer to openspec/ documents.**
