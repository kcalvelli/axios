# Technical Plan

## Architecture Overview

### System Type
[EXPLICIT] **Nix Flake Library** - Modular framework architecture providing reusable components (evidence: README.md:13, flake.nix:2)

### Component Architecture
```
[User Flake Configuration]
         ↓
    [axiOS Library]
    ├── [NixOS Modules] ←→ [Home Modules]
    ├── [DevShells]
    ├── [Custom Packages]
    └── [Library Functions]
         ↓
   [NixOS System]
```

**Components**:
- **User Flake Configuration**: Downstream user's flake.nix that imports axiOS (external)
- **NixOS Modules**: System-level configuration modules (modules/)
- **Home Modules**: User environment configuration via home-manager (home/)
- **DevShells**: Development environment definitions (devshells/)
- **Custom Packages**: Specialized packages (pkgs/)
- **Library Functions**: Helper utilities (lib/)

### Deployment Model
- **Process Model**: Declarative configuration applied via NixOS rebuild
- **Scaling Strategy**: N/A (library project - users deploy on their own systems)
- **High Availability**: N/A (single-user desktop/workstation focused)

## Module Breakdown

### Module Registration Pattern

**CRITICAL**: All new modules must be registered in TWO locations:

1. **modules/default.nix** - Declares the module as a flake output
2. **lib/default.nix (buildModules)** - Imports the module into user configurations

#### Module Categories

Modules are imported using one of three patterns:

**Core Modules (Always Imported)**
- Location: `coreModules` list in lib/default.nix
- Purpose: Provide optional configuration without requiring `modules.X` flag
- Examples: crashDiagnostics, hardware
- User access: Configure via `extraConfig.hardware.crashDiagnostics.*`

**Flagged Modules (Conditional on modules.X)**
- Location: `flaggedModules` list in lib/default.nix
- Purpose: Major features users explicitly enable
- Examples: desktop, development, gaming, ai, secrets, services
- User access: Enable via `modules.desktop = true`

**Conditional Hardware Modules**
- Location: `conditionalHwModules` list in lib/default.nix
- Purpose: Auto-enable based on hardware.vendor or formFactor
- Examples: desktopHardware (when vendor="msi"), laptopHardware (when vendor="system76")
- User access: Automatic based on hardware config

#### Adding a New Module Checklist

1. Create module directory: `modules/my-module/default.nix`
2. Follow module template pattern with `enable` option and `mkIf` blocks
3. Register in `modules/default.nix`:
   ```nix
   flake.nixosModules.myModule = ./my-module;
   ```
4. Import in `lib/default.nix` in appropriate category:
   - Core: Add to `coreModules` if always-available
   - Flagged: Add to `flaggedModules` with `lib.optional` and flag check
   - Conditional: Add to `conditionalHwModules` with hardware condition

### NixOS Modules

#### modules/system/
- **Path**: `modules/system/`
- **Purpose**: Core system configuration - locale, timezone, users
- **Language**: Nix
- **Dependencies**:
  - Internal: modules/users.nix
  - External: nixpkgs
- **Exposed Interface**: `inputs.axios.nixosModules.system`
- **Entry Points**: default.nix
- **Key Options**:
  - `axios.system.timeZone` (REQUIRED, no default)
  - `axios.system.locale` (default: en_US.UTF-8)

#### modules/desktop/
- **Path**: `modules/desktop/`
- **Purpose**: Desktop environment with Niri, DMS, and applications
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: nixpkgs, niri, dankMaterialShell, quickshell, dsearch
- **Exposed Interface**: `inputs.axios.nixosModules.desktop`
- **Entry Points**: default.nix
- **Key Options**: `desktop.enable`
- **Packages**: 40+ desktop applications (productivity, media, utilities)
- **Evidence**: modules/desktop/default.nix

#### modules/development/
- **Path**: `modules/development/`
- **Purpose**: Development tools and language runtimes
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External**: nixpkgs
- **Exposed Interface**: `inputs.axios.nixosModules.development`
- **Entry Points**: default.nix
- **Key Options**: `development.enable`

#### modules/graphics/
- **Path**: `modules/graphics/`
- **Purpose**: GPU driver configuration (NVIDIA, AMD, Intel)
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: nixpkgs, nixos-hardware (assumed)
- **Exposed Interface**: `inputs.axios.nixosModules.graphics`
- **Entry Points**: default.nix

#### modules/networking/
- **Path**: `modules/networking/`
- **Purpose**: Network services configuration
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: nixpkgs
- **Exposed Interface**: `inputs.axios.nixosModules.networking`
- **Entry Points**: default.nix, samba.nix, tailscale.nix
- **Aspect Files**:
  - samba.nix: SMB/CIFS file sharing
  - tailscale.nix: Mesh VPN with HTTPS certificates

#### modules/hardware/
- **Path**: `modules/hardware/`
- **Purpose**: Hardware-specific optimizations
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: nixpkgs, nixos-hardware
- **Exposed Interface**:
  - `inputs.axios.nixosModules.hardware`
  - `inputs.axios.nixosModules.desktopHardware`
  - `inputs.axios.nixosModules.laptopHardware`
- **Entry Points**: default.nix, desktop.nix, laptop.nix

#### modules/gaming/
- **Path**: `modules/gaming/`
- **Purpose**: Gaming configuration and optimizations
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: nixpkgs
- **Exposed Interface**: `inputs.axios.nixosModules.gaming`
- **Entry Points**: default.nix

#### modules/virtualisation/
- **Path**: `modules/virtualisation/`
- **Purpose**: VM and container support
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: nixpkgs
- **Exposed Interface**: `inputs.axios.nixosModules.virt`
- **Entry Points**: default.nix

#### modules/ai/
- **Path**: `modules/ai/`
- **Purpose**: AI tools system integration and local LLM inference
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: nix-ai-tools, mcp-journal, nix-devshell-mcp, nixpkgs (ollama, lmstudio, llama-cpp)
- **Exposed Interface**: `inputs.axios.nixosModules.ai`
- **Entry Points**: default.nix
- **Key Options**:
  - `services.ai.enable`: Enable AI tools (claude-code, copilot-cli, etc.)
  - `services.ai.local.enable`: Enable local LLM stack (Ollama, llama-cpp, LM Studio, OpenCode)
  - `services.ai.local.models`: Ollama models to preload
  - `services.ai.local.rocmOverrideGfx`: GPU architecture override for ROCm
  - `services.ai.local.gui`: Enable LM Studio GUI
  - `services.ai.local.cli`: Enable OpenCode CLI
  - `services.ai.local.ollamaReverseProxy.enable`: Enable Caddy reverse proxy for Ollama
  - `services.ai.local.ollamaReverseProxy.path`: Path prefix for Ollama (default: "/ollama")
  - `services.ai.local.ollamaReverseProxy.domain`: Domain override for Ollama
  - `services.ai.local.llamaServer.enable`: Enable llama-cpp server (default: true)
  - `services.ai.local.llamaServer.model`: Path to GGUF model file
  - `services.ai.local.llamaServer.port`: Server port (default: 8081)
  - `services.ai.local.llamaServer.contextSize`: Context window size (default: 4096)
  - `services.ai.local.llamaServer.gpuLayers`: GPU offload layers (default: -1 = all)
  - `services.ai.local.llamaServer.reverseProxy.enable`: Enable Caddy reverse proxy
  - `services.ai.local.llamaServer.reverseProxy.path`: Path prefix (default: "/llama")
  - `services.ai.local.llamaServer.reverseProxy.domain`: Domain override
- **Architecture**:
  - **Two-tier config**: Base AI tools always enabled, local LLM optional via mkMerge
  - **ROCm Integration**: Ollama and llama-cpp configured with AMD GPU acceleration
    - Ollama: `acceleration = "rocm"` for AMD GPU support
    - llama-cpp: `-ngl -1` for full GPU layer offloading
    - `rocmOverrideGfx = "10.3.0"` for gfx1031 GPUs (applies to both)
    - `amdgpu` kernel module loaded at boot
  - **Dual Inference Backends**:
    - **Ollama** (port 11434): Model management, 32K context via `OLLAMA_NUM_CTX`
    - **llama-cpp** (port 8081): Direct GGUF loading, fine-grained control
  - **AMD Optimizations**:
    - Full GPU offload: `-ngl -1` (all layers to GPU)
    - NUMA optimization: `--numa numactl` for multi-die CPUs
    - 4096 token default context (configurable)
  - **Model Management**:
    - Ollama: `loadModels` option preloads models on service start
    - llama-cpp: User-specified GGUF file path (optional, service won't start if null)
      - Model download utility: `nix run .#download-llama-models` (scripts/download-llama-models.sh)
      - Interactive menu with curated model recommendations
      - Downloads GGUF files from HuggingFace
      - Supports general purpose, coding, small/fast, and large/powerful categories
  - **Reverse Proxy Support** (both Ollama and llama-cpp):
    - Uses Caddy route registry pattern via `selfHosted.caddy.routes.<name>`
    - **llama-server route**: Registers as `selfHosted.caddy.routes.llama`
      - Priority: 100 (path-specific, evaluated before catch-all)
      - Path: `${reverseProxy.path}/*` (default: "/llama/*")
      - Target: `http://127.0.0.1:${port}` (default: 8081)
      - Automatic `--api-prefix` configuration when enabled
    - **Ollama route**: Registers as `selfHosted.caddy.routes.ollama`
      - Priority: 100 (path-specific, evaluated before catch-all)
      - Path: `${ollamaReverseProxy.path}/*` (default: "/ollama/*")
      - Target: `http://127.0.0.1:11434`
    - **Auto-ordering**: Routes automatically ordered before catch-all services (Immich)
    - Requires `selfHosted.enable = true`
    - Implementation: modules/ai/default.nix:315-350
  - **MCP Support**: LM Studio and OpenCode support MCP servers (user-configured)
    - LM Studio: `~/.config/lmstudio/mcp.json`
    - OpenCode: `~/.config/opencode/opencode.json`
  - **Runtime Dependencies**: nodejs, python3, uv for MCP server execution

#### modules/secrets/
- **Path**: `modules/secrets/`
- **Purpose**: agenix secrets management integration
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: agenix
- **Exposed Interface**: `inputs.axios.nixosModules.secrets`
- **Entry Points**: default.nix

#### modules/services/
- **Path**: `modules/services/`
- **Purpose**: System services (web server, photo backup)
- **Language**: Nix
- **Dependencies**:
  - Internal: pkgs.immich (custom package)
  - External: nixpkgs
- **Exposed Interface**: `inputs.axios.nixosModules.services`
- **Entry Points**: default.nix, caddy.nix, immich.nix
- **Services**:
  - **Caddy**: Reverse proxy with Tailscale HTTPS
    - **Route Registry Pattern**: Services register routes via `selfHosted.caddy.routes.<name>`
    - **Auto-Ordering**: Routes grouped by domain, sorted by priority (lower = first)
    - **Decoupling**: Services don't need to know about other services' paths
    - **Implementation**: caddy.nix:92-145 (route ordering logic)
  - **Immich**: Photo backup (nixpkgs version)
    - **Route Registration**: Registers as catch-all (priority 1000)
    - **Integration**: Uses route registry instead of hardcoded path exclusions

#### modules/users.nix
- **Path**: `modules/users.nix`
- **Purpose**: User account management helper
- **Language**: Nix
- **Dependencies**: None
- **Exposed Interface**: `inputs.axios.nixosModules.users`
- **Note**: Helper module, doesn't follow standard directory pattern

### Home Manager Modules

#### home/desktop/
- **Path**: `home/desktop/`
- **Purpose**: Desktop user environment configuration
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: home-manager, dankMaterialShell
- **Exposed Interface**: `inputs.axios.homeModules.desktop`
- **Entry Points**: default.nix
- **Aspect Files**:
  - niri.nix: Niri compositor configuration
  - wallpaper.nix: Wallpaper management with blur
  - theming.nix: Theme coordination
  - pwa-apps.nix: Progressive web apps
  - gdrive-sync.nix: Google Drive rclone sync

#### home/profiles/
- **Path**: `home/profiles/`
- **Purpose**: Pre-configured user profile compositions
- **Language**: Nix
- **Dependencies**:
  - Internal: Other home modules
  - External: home-manager
- **Exposed Interface**:
  - `inputs.axios.homeModules.workstation`
  - `inputs.axios.homeModules.laptop`
- **Entry Points**: base.nix, workstation.nix, laptop.nix
- **Pattern**: base.nix provides common config, specific profiles extend it

#### home/ai/
- **Path**: `home/ai/`
- **Purpose**: AI tools home-level configuration
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: mcp-servers-nix, home-manager
- **Exposed Interface**: `inputs.axios.homeModules.ai`
- **Entry Points**: default.nix, mcp.nix
- **Key Feature**: Declarative MCP server configuration via `programs.claude-code.mcpServers`

#### home/terminal/
- **Path**: `home/terminal/`
- **Purpose**: Terminal environment configuration
- **Language**: Nix
- **Dependencies**:
  - Internal: None
  - External: home-manager, ghostty, lazyvim
- **Exposed Interface**: Imported by home/profiles/base.nix
- **Entry Points**: default.nix
- **Aspect Files**:
  - fish.nix: Fish shell configuration
  - git.nix: Git settings and aliases
  - neovim.nix: LazyVim configuration
  - ghostty.nix: Terminal emulator settings
  - starship.nix: Prompt configuration
  - tools.nix: CLI utility tools

#### home/browser/
- **Path**: `home/browser/`
- **Purpose**: Browser configuration
- **Language**: Nix
- **Dependencies**: home-manager
- **Exposed Interface**: `inputs.axios.homeModules.browser`
- **Entry Points**: default.nix

#### home/calendar/
- **Path**: `home/calendar/`
- **Purpose**: Calendar integration
- **Language**: Nix
- **Dependencies**: home-manager
- **Exposed Interface**: `inputs.axios.homeModules.calendar`
- **Entry Points**: default.nix

#### home/secrets/
- **Path**: `home/secrets/`
- **Purpose**: Home-level secrets management
- **Language**: Nix
- **Dependencies**: agenix, home-manager
- **Exposed Interface**: `inputs.axios.homeModules.secrets`
- **Entry Points**: default.nix

#### home/security/
- **Path**: `home/security/`
- **Purpose**: Security tools for user environment
- **Language**: Nix
- **Dependencies**: home-manager
- **Exposed Interface**: Not explicitly listed in home/default.nix
- **Entry Points**: default.nix

### Module Dependency Graph
```
[User Flake]
    ↓
[System Modules] ← (no inter-dependencies, independently importable)
    ↓
[Home Modules] ← (may check osConfig for system module state)
    ↓
[NixOS System Build]
```

**Dependency Issues**: None - modules are designed to be independently importable

## Data Architecture

### Storage Systems

#### Nix Store
- **Technology**: Nix store (/nix/store)
- **Purpose**: Immutable package and configuration storage
- **Schema Summary**: Content-addressable store with cryptographic hashes
- **Connection**: Read-only access to store
- **Evidence**: Core Nix functionality

#### User Data (Desktop Module)
- **Location**: User home directory
- **Purpose**: User documents, media, configuration files
- **Evidence**: home/desktop/gdrive-sync.nix (Documents, Music folders)
- **Sync Configuration**: Bidirectional sync with `maxDelete = "100"` (integer count limit for safety)

#### Immich Database (Services Module)
- **Technology**: PostgreSQL (assumed, typical for Immich)
- **Purpose**: Photo metadata and user data
- **Evidence**: modules/services/immich.nix
- **Note**: [TBD] Database configuration details

### Data Model Summary

#### Primary Entities
1. **NixOS Configuration**: Declarative system state
2. **Home Manager Configuration**: User environment state
3. **Module Options**: Configuration parameters
4. **Secrets**: Encrypted sensitive data (agenix)
5. **MCP Server Config**: AI tool integration settings
6. **User Account**: System user definition
7. **Immich Assets**: Photo and video files
8. **Google Drive Sync State**: rclone bisync metadata

#### Relationships
- **User** has-one **Home Configuration**
- **System** has-many **Modules** (enabled modules)
- **Module** has-many **Options**
- **User** has-many **Secrets**
- **AI Module** has-many **MCP Servers**

### State Management

#### Application State
- **Where**: Nix evaluation (build time), /etc/nixos (runtime config symlinks)
- **Lifecycle**: Build-time evaluation, applied on nixos-rebuild
- **Persistence**: Nix store (immutable), /etc/nixos/configuration.nix symlinks

#### Session Management
- **Storage**: N/A (not a web application)
- **Duration**: N/A

### Data Migration

#### Migration Tool
- **System**: NixOS configuration generations
- **Migration Files**: N/A (Nix expressions, not traditional migrations)
- **Version**: Current system generation number

#### Migration History
- **Total Migrations**: N/A
- **Rollback**: `nixos-rebuild switch --rollback` to previous generation

## Build & Deployment

### Build Process

#### Build Tools
- **Primary**: Nix flakes
- **Build Scripts**: None (Nix evaluation handles builds)
- **Build Stages**:
  1. Flake evaluation
  2. Dependency resolution
  3. Package builds (or cache downloads)
  4. System configuration assembly

#### Build Outputs
- **Artifacts**: NixOS system closure (all packages and configuration)
- **Artifact Repository**: Cachix (niri.cachix.org, numtide.cachix.org)

### Continuous Integration

#### CI Platform
- **System**: GitHub Actions (evidence: .github/workflows/)
- **Workflows**:
  1. flake-check.yml: Flake validation
  2. formatting.yml: Code style check
  3. test-init-script.yml: Init script validation
  4. build-devshells.yml: DevShell builds
  5. flake-lock-updater.yml: Weekly dependency updates
  6. flake-lock-updater-direct.yml: Alternative updater (disabled)

#### Pipeline Stages
1. **Validation Stage**: `nix flake check --all-systems` - Trigger: push, PRs
2. **Formatting Stage**: `nix fmt -- --check` - Trigger: .nix file changes
3. **Build Stage**: DevShell and example builds - Trigger: relevant path changes
4. **Dependency Stage**: `nix flake update` - Trigger: weekly cron (Mondays 6 AM UTC)

### Deployment

#### Deployment Method
- **Strategy**: N/A (library project - users deploy themselves)
- **User Deployment**: `sudo nixos-rebuild switch --flake .#<hostname>`

#### Environments
- **Development**: User's local machine
- **Production**: User's local machine (NixOS is production)

#### Infrastructure-as-Code
- **Tools**: NixOS (entire system is IaC)
- **Resources Managed**: System configuration, packages, services
- **Evidence**: All .nix files

### Runtime Configuration

#### Environment Variables
[Listed by module, extracted from code analysis]

**Required**: [TBD] Module-specific analysis needed

**Optional**: [TBD] Module-specific analysis needed

#### Configuration Files
- `flake.nix`: User's flake configuration
- `flake.lock`: Locked dependency versions
- `configuration.nix`: Traditional NixOS config (if using)
- `/etc/nixos/configuration.nix`: System configuration symlink

#### Secrets Management
[EXPLICIT] agenix - Age-encrypted secrets
- Secrets encrypted with SSH/age keys
- Decrypted at activation time
- Stored in /run/secrets/
- Evidence: modules/secrets/, home/secrets/, flake.nix:27-30

## Operational Considerations

### Observability

#### Logging
- **Framework**: systemd journal (system-level)
- **Log Levels**: Standard systemd levels (debug, info, notice, warning, err, crit, alert, emerg)
- **Structured Logging**: journald structured fields
- **Log Aggregation**: Local only (systemd journal)
- **Evidence**: mcp-journal MCP server provides journal access

#### Metrics
- **System**: None explicitly configured
- **Application Metrics**: [TBD]

#### Tracing
- **System**: None explicitly configured

#### Health Checks
- **Endpoints**: Immich service (health check via Caddy reverse proxy)
- **Dependencies Checked**: [TBD]

### Error Handling & Resilience

#### Error Handling Patterns
- **Strategy**: Nix evaluation errors fail fast (build-time)
- **Runtime Errors**: systemd service management
- **User-Facing Errors**: NixOS error messages

#### Retry Logic
[INFERRED] systemd service restart policies:
- **Services**: Configurable via systemd options

#### Circuit Breakers
- **Protected Operations**: None explicitly configured

#### Graceful Degradation
- **MCP Servers**: Degrade gracefully if API keys missing
- **External Services**: Services fail to start if dependencies unavailable

### Performance Considerations

#### Caching Strategy
- **Application-Level**: Nix store caches built packages
- **Binary Caching**: Cachix (niri.cachix.org, numtide.cachix.org)
- **Evidence**: flake.nix:112-124

#### Rate Limiting
- **Endpoints**: None (not a web service)

#### Database Optimization
- **Indexing**: [TBD] Immich database specifics
- **Connection Pooling**: [TBD] Immich configuration
- **Query Patterns**: N/A (Nix evaluation is deterministic)

#### Asset Optimization
- **Bundling**: N/A (desktop application)
- **Minification**: N/A
- **CDN**: Cachix binary cache

### Maintenance & Operations

#### Background Jobs
- **Scheduler**: systemd timers
- **Jobs Defined**: [TBD] Module-specific timers

#### Database Maintenance
- **Backups**: [TBD] User responsibility
- **Vacuum/Optimize**: [TBD] Immich maintenance

#### Dependency Updates
- **Automation**: flake-lock-updater.yml (weekly, Mondays 6 AM UTC)
- **Update Strategy**: Automated PR with validation, manual approval

## Extension Points & Customization

### Plugin Architecture
- **Plugin Interface**: NixOS module system
- **Discovery**: User imports modules in their flake
- **Examples**: All modules are "plugins" in this sense

### Configuration Injection
- **Feature Flags**: Module enable options (`<module>.enable`)
- **Runtime Configuration**: NixOS options system

### Webhooks
- **Outbound Webhooks**: None
- **Inbound Webhooks**: None

### API Extensibility
- **Versioning Strategy**: Calendar versioning (YYYY.MM.DD)
- **Backward Compatibility**: [ASSUMED] Breaking changes noted in CHANGELOG

## Dependencies

### Critical External Dependencies
1. **nixpkgs** (unstable): Base package collection - [CRITICAL]
2. **home-manager** (master): User environment management - [CRITICAL]
3. **niri**: Wayland compositor - [HIGH] (desktop module)
4. **dankMaterialShell**: Shell environment - [HIGH] (desktop module)
5. **ghostty**: Terminal emulator - [MEDIUM] (terminal)
6. **agenix**: Secrets management - [MEDIUM] (secrets module)
7. **lanzaboote**: Secure boot - [MEDIUM] (optional)
8. **disko**: Disk partitioning - [MEDIUM] (optional)
9. **nix-ai-tools**: AI CLI tools - [MEDIUM] (ai module)
10. **mcp-servers-nix**: MCP configuration - [MEDIUM] (ai module)
11. **lazyvim**: Neovim config - [MEDIUM] (terminal)
12. **flake-parts**: Flake organization - [HIGH] (build system)
13. **devshell**: Development environments - [LOW] (devshells only)
14. **fenix**: Rust toolchain - [LOW] (rust devshell)
15. **zig-overlay**: Zig toolchain - [LOW] (zig devshell)

### Dependency Management
- **Lock Files**: flake.lock (Nix flake lock file)
- **Update Policy**: Weekly automated updates via CI
- **Security Scanning**: None explicitly configured

### Internal Service Dependencies
N/A (library project, not microservices)

## Security Patterns

### Authentication
[INFERRED] N/A for library itself - user systems handle authentication
- **Immich**: Built-in authentication
- **Tailscale**: OAuth via Tailscale account
- **Google Drive**: OAuth via rclone

### Authorization
[INFERRED] UNIX permissions and systemd service isolation
- **Implementation**: systemd DynamicUser, file permissions

### Input Validation
- **Validation Library**: Nix type system
- **Validation Points**: Build-time type checking

### Security Headers
- **Configured Headers**: [TBD] Caddy default security headers
- **Evidence**: modules/services/caddy.nix

## Risk Assessment

### Critical Path Components
1. **nixpkgs**: Entire system depends on it
2. **Nix flake evaluation**: Build system foundation
3. **Module option system**: Configuration interface

### Single Points of Failure
- **GitHub**: Source repository and CI/CD
- **Cachix**: Binary cache (fallback: build from source)
- **Tailscale**: HTTPS certificates for self-hosted services

### Technical Debt Indicators
- Custom Immich package (temporary until nixpkgs updates)
- [TBD] TODO/FIXME analysis not performed
- [TBD] Deprecated API usage

### Scalability Concerns
- N/A (desktop-focused, not a service)

## Unknowns
- [TBD] Complete devshell package inventories
- [TBD] Immich database configuration details
- [TBD] Complete list of systemd services per module
- [TBD] Secrets rotation procedures
- [TBD] Disaster recovery procedures
- [TBD] Full gaming module package list
- [TBD] Virtualization module specifics (Podman? Docker?)
- [TBD] Security module capabilities
- [TBD] Browser module Firefox/Chrome configuration details
- [TBD] Performance benchmarks or metrics
