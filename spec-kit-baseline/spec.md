# Specification

## Goal
axiOS provides a modular NixOS framework and library for building reproducible NixOS systems with modern desktop environments, development tools, and curated configurations - enabling users to maintain simple configurations while axiOS handles system complexity.

## System Overview
axiOS is a Nix flake library that provides reusable NixOS and home-manager modules for building customized NixOS systems. Rather than being an end-user distribution, it functions as a framework that downstream users import into their own flake configurations.

The project emphasizes modularity, reproducibility, and user control - providing opinionated defaults while allowing complete customization. Users maintain minimal configuration files (typically ~30-60 lines) while axiOS provides comprehensive system configuration including desktop environments, development tools, networking, security, and services.

axiOS is NOT a personal configuration repository - it's a library designed for multiple users with different needs, avoiding hardcoded personal or regional preferences.

## User Types
1. **NixOS Configuration Maintainers**: Primary users who import axiOS into their own flake configurations to build customized NixOS systems
2. **Module Developers**: Contributors who extend axiOS by adding new modules or improving existing ones
3. **Home Lab Enthusiasts**: Users who leverage self-hosted services (Immich, Caddy, Tailscale integration)
4. **Developers**: Users who benefit from pre-configured development environments and tools
5. **Desktop Users**: Users seeking a polished Wayland desktop experience with Niri and DankMaterialShell

## Core Features (Current Implementation)

### System Configuration
#### Module System
- **Purpose**: Provides reusable NixOS modules for system configuration
- **Implementation Evidence**: modules/default.nix, modules/*/default.nix
- **Confidence**: [EXPLICIT]
- **Modules Available**:
  - `system`: Locale, timezone, user management (modules/system/)
  - `desktop`: Desktop environment configuration (modules/desktop/)
  - `development`: Development tools and environments (modules/development/)
  - `hardware`: Hardware-specific configurations (modules/hardware/)
  - `crashDiagnostics`: Kernel crash diagnostics and recovery (modules/hardware/crash-diagnostics.nix)
  - `graphics`: GPU drivers (NVIDIA, AMD, Intel) with AMD GPU recovery (modules/graphics/)
  - `networking`: Samba, Tailscale integration (modules/networking/)
  - `gaming`: Gaming configuration (modules/gaming/)
  - `virt`: Virtualization support (modules/virtualisation/)
  - `ai`: AI tools integration (modules/ai/)
  - `secrets`: agenix secrets management (modules/secrets/)
  - `services`: System services (modules/services/)

#### Timezone & Locale Management
- **Purpose**: Declarative timezone and locale configuration with no regional defaults
- **Implementation Evidence**: modules/system/default.nix, .claude/project.md:95-101
- **Confidence**: [EXPLICIT]
- **Constraint**: Users MUST set `axios.system.timeZone` (no default provided)

### Desktop Environment
#### Niri Wayland Compositor
- **Purpose**: Scrollable tiling Wayland compositor with overview mode
- **Implementation Evidence**: README.md:40, flake.nix:91-94
- **Confidence**: [EXPLICIT]
- **Integration**: Full DankMaterialShell support

#### DankMaterialShell Integration
- **Purpose**: Material Design shell with custom theming and widgets
- **Implementation Evidence**: home/desktop/default.nix:18-38, flake.nix:81-84
- **Confidence**: [EXPLICIT]
- **Version**: v0.6.2 with NixOS module architecture
- **Configuration Levels**: NixOS module (system) and home-manager module (user)
- **Polkit Agent**: Built-in polkit authentication agent (replaces external mate-polkit)
- **Systemd Integration**: Enabled with auto-restart on configuration changes
- **Feature Toggles**: All features explicitly enabled by default
  - System Monitoring: Resource monitoring widgets
  - Clipboard: History management with cliphist
  - VPN: VPN status widget (ProtonVPN support)
  - Brightness Control: Screen and keyboard brightness
  - Color Picker: Color selection tool (hyprpicker)
  - Dynamic Theming: Auto-theme generation (matugen)
  - Audio Wavelength: Audio visualizer (cava)
  - Calendar Events: Calendar integration (khal)
  - System Sound: Sound effects

#### Idle Management
- **Purpose**: Automatic screen blanking and power management
- **Implementation Evidence**: runbook.md:595-636
- **Confidence**: [EXPLICIT]
- **Technology**: User-configured via DankMaterialShell settings
- **Default Configuration**: None provided by axiOS (user must configure)
- **Configuration Location**: `~/.config/DankMaterialShell/settings.json`
- **Available Settings**:
  - `acMonitorTimeout`: Minutes until monitor turns off (default: 0 = disabled)
  - `acLockTimeout`: Minutes until screen locks (default: 0 = disabled)
  - `acSuspendTimeout`: Minutes until system suspends (default: 0 = disabled)
  - Battery equivalents: `batteryMonitorTimeout`, `batteryLockTimeout`, `batterySuspendTimeout`
- **Manual Lock**: Super+Alt+L (DMS lock screen keybind)
- **Rationale**: Idle management delegated to user preference; swayidle had unreliable wake-up behavior

#### Desktop Applications
- **Purpose**: Curated set of desktop applications for productivity and media
- **Implementation Evidence**: modules/desktop/default.nix:14-50
- **Confidence**: [EXPLICIT]
- **Categories**:
  - Productivity: Obsidian, Discord, Typora, LibreOffice
  - Media Creation: Pitivi, Pinta, Inkscape
  - Media Viewing: Shotwell, Loupe, Celluloid, Amberol
  - System Utilities: Baobab, Swappy, Qalculate

#### Wallpaper & Theming
- **Purpose**: Automatic wallpaper management with blur effects
- **Implementation Evidence**: home/desktop/wallpaper.nix, home/desktop/theming.nix
- **Confidence**: [EXPLICIT]
- **Features**: Dynamic blur, theme coordination

#### Progressive Web Apps (PWA)
- **Purpose**: Extensible PWA support for custom web applications
- **Implementation Evidence**: CHANGELOG.md:49, home/desktop/pwa-apps.nix, pkgs/pwa-apps/
- **Confidence**: [EXPLICIT]

### Development Tools
#### Development Shells
- **Purpose**: Project-specific development environments with complete toolchains
- **Implementation Evidence**: devshells/rust.nix, devshells/zig.nix, devshells/qml.nix
- **Confidence**: [EXPLICIT]
- **Environments**:
  - **Rust**: Fenix toolchain with cargo, rustc, rust-analyzer (devshells/rust.nix)
  - **Zig**: Latest Zig compiler (devshells/zig.nix)
  - **QML**: Qt6 development with QML tools (devshells/qml.nix)
- **Access**: `nix develop .#<shell-name>`

#### Terminal Configuration
- **Purpose**: Comprehensive terminal experience with modern tools
- **Implementation Evidence**: home/terminal/
- **Confidence**: [EXPLICIT]
- **Components**:
  - **Ghostty**: GPU-accelerated terminal emulator (home/terminal/ghostty.nix)
  - **Fish shell**: Modern shell with completions (home/terminal/fish.nix)
  - **Starship**: Customizable prompt (home/terminal/starship.nix)
  - **Git**: Git configuration and aliases (home/terminal/git.nix)
  - **Neovim**: LazyVim configuration with LSP (home/terminal/neovim.nix)
  - **CLI Tools**: Modern replacements (bat, eza, fd, ripgrep, etc.) (home/terminal/tools.nix)

### AI & Development Assistance
#### AI Tools Integration
- **Purpose**: Comprehensive AI assistant integration for development
- **Implementation Evidence**: modules/ai/, home/ai/, flake.nix:97-103
- **Confidence**: [EXPLICIT]
- **Tools**:
  - **claude-code**: Claude CLI tool from nix-ai-tools
  - **copilot-cli**: GitHub Copilot CLI
  - **claude-monitor**: Resource monitoring for AI sessions
  - **gemini-cli**: Google Gemini CLI for development tasks

#### Local LLM Inference Stack
- **Purpose**: Self-hosted LLM inference with AMD GPU acceleration
- **Implementation Evidence**: modules/ai/default.nix:18-105, 154-201
- **Confidence**: [EXPLICIT]
- **Components**:
  - **Ollama**: Local inference backend with ROCm acceleration
    - 32K context window for agentic tool use
    - ROCm override for gfx1031 GPUs (RX 5500/5600/5700 series)
    - Automatic model preloading
    - Service port: 11434
    - Optional Caddy reverse proxy with path-based routing
      - Path-based routing on shared domain (e.g., edge.ts.net/ollama)
      - Compatible with other services using explicit handle blocks
  - **Alpaca**: Native GUI for local models (GTK/libadwaita)
    - Connects to Ollama backend
  - **OpenCode**: Agentic CLI for coding tasks
    - Full file editing and shell command execution
    - MCP server integration
    - LSP integration
    - Configured via `~/.config/opencode/opencode.json`
- **Default Models** (Ollama):
  - `qwen3-coder:30b`: Primary agentic coding (MoE, ~4GB VRAM)
  - `qwen3:14b`: General reasoning (~10GB VRAM)
  - `deepseek-coder-v2:16b`: Multilingual coding (~11GB VRAM)
  - `qwen3:4b`: Fast completions (~3GB VRAM)
- **Configuration Options**:
  - `services.ai.local.enable`: Enable local LLM stack
  - `services.ai.local.models`: List of Ollama models to preload
  - `services.ai.local.rocmOverrideGfx`: GPU architecture override (default: "10.3.0")
  - `services.ai.local.gui`: Enable Alpaca (default: true)
  - `services.ai.local.cli`: Enable OpenCode (default: true)
  - `services.ai.local.ollamaReverseProxy.enable`: Enable Caddy reverse proxy for Ollama (default: false)
  - `services.ai.local.ollamaReverseProxy.path`: Path prefix for Ollama proxy (default: "/ollama")
  - `services.ai.local.ollamaReverseProxy.domain`: Domain override for Ollama (default: null = use hostname)

#### MCP Server Configuration
- **Purpose**: Declarative Model Context Protocol server configuration
- **Implementation Evidence**: home/ai/mcp.nix, .claude/project.md:178-205
- **Confidence**: [EXPLICIT]
- **Servers Available**:
  - **git**: Git operations
  - **github**: GitHub integration (requires token)
  - **filesystem**: File system access
  - **journal**: systemd journal access (mcp-journal)
  - **mcp-nixos**: NixOS package/option search
  - **sequential-thinking**: AI reasoning enhancement
  - **context7**: Documentation retrieval
  - **time**: Time zone operations
  - **brave-search**: Web search (requires API key)
  - **tavily**: Advanced search (requires API key)
  - **nix-devshell-mcp**: Nix devshell integration
- **Configuration**: Via `programs.claude-code.mcpServers` using mcp-servers-nix library

### Networking & Services
#### Tailscale Integration
- **Purpose**: Mesh VPN with automatic configuration
- **Implementation Evidence**: modules/networking/tailscale.nix
- **Confidence**: [EXPLICIT]
- **Features**: Automatic HTTPS certificate management, domain configuration

#### Samba File Sharing
- **Purpose**: SMB/CIFS file sharing with user authentication
- **Implementation Evidence**: modules/networking/samba.nix, CHANGELOG.md (mentions samba-add-user)
- **Confidence**: [EXPLICIT]
- **Features**: User password database management

#### Caddy Web Server
- **Purpose**: Reverse proxy with automatic HTTPS via Tailscale
- **Implementation Evidence**: modules/services/caddy.nix
- **Confidence**: [EXPLICIT]
- **Features**:
  - Tailscale TLS certificate integration
  - Route registry pattern for automatic path-based routing
  - Automatic route ordering (path-specific routes before catch-all)
  - Declarative service registration via `selfHosted.caddy.routes`

#### Immich Photo Backup
- **Purpose**: Self-hosted photo and video backup solution
- **Implementation Evidence**: modules/services/immich.nix, CHANGELOG.md:13-18
- **Confidence**: [EXPLICIT]
- **Version**: Uses nixpkgs version (custom 2.3.1 override removed 2025-11-26)
- **Integration**: Caddy reverse proxy, external domain configuration

#### Google Drive Sync
- **Purpose**: Bidirectional sync for Documents and Music with Google Drive
- **Implementation Evidence**: home/desktop/gdrive-sync.nix, README.md:46
- **Confidence**: [EXPLICIT]
- **Features**: rclone-based, setup script (`setup-gdrive-sync`), bisync for safety

### Hardware & Graphics
#### Graphics Driver Support
- **Purpose**: Automatic GPU driver configuration
- **Implementation Evidence**: modules/graphics/
- **Confidence**: [EXPLICIT]
- **Supported**: NVIDIA, AMD, Intel
- **Features**: Hardware acceleration, Wayland support

#### Hardware Profiles
- **Purpose**: Optimized configurations for different hardware types
- **Implementation Evidence**: modules/hardware/desktop.nix, modules/hardware/laptop.nix
- **Confidence**: [EXPLICIT]
- **Profiles**:
  - **Desktop**: Power performance, full acceleration
  - **Laptop**: Power management, TLP, laptop-specific optimizations

### Virtualization
#### Libvirt/QEMU Support
- **Purpose**: Virtual machine management
- **Implementation Evidence**: modules/virtualisation/
- **Confidence**: [EXPLICIT]
- **Features**: KVM/QEMU, virt-manager

#### Container Support
- **Purpose**: Container runtime and management
- **Implementation Evidence**: modules/virtualisation/
- **Confidence**: [ASSUMED] Likely includes Podman/Docker support

### Security & Secrets
#### agenix Secrets Management
- **Purpose**: Encrypted secrets with age
- **Implementation Evidence**: modules/secrets/, home/secrets/, flake.nix:27-30
- **Confidence**: [EXPLICIT]
- **Use Case**: API keys (Brave, Tavily), credentials

#### Secure Boot Support
- **Purpose**: UEFI Secure Boot with Lanzaboote
- **Implementation Evidence**: flake.nix:42-48
- **Confidence**: [EXPLICIT]

### Gaming
#### Gaming Configuration
- **Purpose**: Gaming-optimized system configuration
- **Implementation Evidence**: modules/gaming/
- **Confidence**: [EXPLICIT]
- **Expected**: Steam, gamemode, performance optimizations

### Configuration Management
#### Interactive Configuration Generator
- **Purpose**: Generate axiOS configurations interactively
- **Implementation Evidence**: scripts/init-config.sh, flake.nix:141-148, README.md:19-24
- **Confidence**: [EXPLICIT]
- **Features**:
  - Hostname, username, timezone prompts
  - Module selection
  - Template-based generation
  - Automatic timezone detection
- **Access**: `nix run github:kcalvelli/axios#init`

#### Disko Integration
- **Purpose**: Declarative disk partitioning
- **Implementation Evidence**: flake.nix:50-53, README.md:54
- **Confidence**: [EXPLICIT]
- **Features**: Automated provisioning templates

### Library Functions
#### Configuration Helpers
- **Purpose**: Utility functions for building NixOS configurations
- **Implementation Evidence**: lib/, flake.nix:160-164
- **Confidence**: [EXPLICIT]
- **Access**: `inputs.axios.lib.*`

## User Journeys

### Journey 1: First-Time axiOS Setup
**Actor**: NixOS Configuration Maintainer
**Goal**: Create a new NixOS configuration using axiOS

**Steps**:
1. User runs `nix run github:kcalvelli/axios#init` in empty directory
2. Interactive generator prompts for:
   - Hostname
   - Username
   - Timezone (with auto-detection)
   - Desired modules (desktop, development, gaming, etc.)
3. Generator creates flake.nix, user.nix, disks.nix from templates
4. User customizes generated files if needed
5. User runs `sudo nixos-rebuild switch --flake .#<hostname>`
6. System is configured according to selected modules

**Success Criteria**: Functional NixOS system with selected modules enabled
**Error Scenarios**:
- Missing timezone configuration (MUST be set manually if not auto-detected)
- Module conflicts (user must resolve)

### Journey 2: Adding MCP Servers for AI Development
**Actor**: Developer using AI tools
**Goal**: Configure MCP servers for enhanced Claude Code experience

**Steps**:
1. User imports `inputs.axios.homeModules.ai` in home-manager configuration
2. User enables `osConfig.services.ai.enable = true` at system level
3. MCP servers are automatically configured in Claude Code
4. For servers requiring API keys (brave-search, tavily):
   - User creates secrets with agenix
   - axiOS automatically uses passwordCommand to load secrets
5. User runs Claude Code with full MCP server access

**Success Criteria**: Claude Code has access to all configured MCP servers
**Error Scenarios**:
- Missing API keys for search servers (fallback to env variables)
- GitHub token not configured (github MCP server unavailable)

### Journey 3: Setting Up Self-Hosted Photo Backup
**Actor**: Home Lab Enthusiast
**Goal**: Deploy Immich for photo backup with Tailscale HTTPS

**Steps**:
1. User enables `networking.tailscale` module with domain configuration
2. User enables `services.immich` module
3. User configures `services.caddy` with Immich reverse proxy
4. System automatically:
   - Obtains Tailscale TLS certificate
   - Configures Immich with external domain
   - Sets up Caddy reverse proxy
5. User accesses Immich at `https://hostname.tailscale-domain.ts.net`
6. User installs Immich mobile app and configures automatic upload

**Success Criteria**: Immich accessible via HTTPS, mobile app syncing photos
**Error Scenarios**:
- Tailscale domain not configured (externalDomain empty)
- Certificate generation fails (Tailscale not authenticated)

### Journey 4: Creating a Development Environment
**Actor**: Developer
**Goal**: Set up a Rust development environment

**Steps**:
1. User enables `development.enable` module in system configuration
2. In project directory, user runs `nix develop github:kcalvelli/axios#rust`
3. DevShell loads with:
   - Rust toolchain (cargo, rustc)
   - rust-analyzer LSP
   - Development utilities
4. User works on project with full tooling available
5. User exits shell when done (environment is ephemeral)

**Success Criteria**: Full Rust development environment available
**Error Scenarios**: None (DevShells are isolated)

## API Surface

### Flake Outputs
#### NixOS Modules
Exposed via `inputs.axios.nixosModules.<name>`:
- `system`: System configuration module
- `desktop`: Desktop environment module
- `development`: Development tools module
- `hardware`: Hardware configuration module
- `desktopHardware`: Desktop-specific hardware (auto-enabled)
- `laptopHardware`: Laptop-specific hardware (auto-enabled)
- `crashDiagnostics`: Kernel crash diagnostics and recovery
- `graphics`: Graphics drivers module (includes AMD GPU recovery)
- `networking`: Networking services module
- `users`: User management module
- `virt`: Virtualization module
- `gaming`: Gaming configuration module
- `ai`: AI tools module
- `secrets`: Secrets management module
- `services`: System services module (enables selfHosted)

Evidence: modules/default.nix:4-20

#### Home Manager Modules
Exposed via `inputs.axios.homeModules.<name>`:
- `desktop`: Desktop home configuration
- `workstation`: Workstation profile
- `laptop`: Laptop profile
- `ai`: AI tools home configuration
- `secrets`: Home-level secrets
- `browser`: Browser configuration
- `calendar`: Calendar integration

Evidence: home/default.nix:6-14

#### DevShells
Accessible via `nix develop .#<shell>`:
- `rust`: Rust development environment
- `zig`: Zig development environment
- `qml`: Qt/QML development environment

Evidence: devshells.nix, devshells/*.nix

#### Apps
Exposed via `nix run .#<app>`:
- `init`: Interactive configuration generator

Evidence: flake.nix:141-148

#### Library Functions
Exposed via `inputs.axios.lib.*`:
- Configuration helper functions
- Module composition utilities

Evidence: lib/, flake.nix:160-164

#### Custom Packages
Exposed via `inputs.axios.packages.<system>.<name>`:
- `immich`: Custom Immich 2.3.1 package
- `pwa-apps`: PWA application builder

Evidence: pkgs/

## Data Model

### Core Entities
#### Module Configuration
**Purpose**: Represents a NixOS or home-manager module configuration
**Key Fields**:
- `enable`: Boolean - Whether module is enabled
- `options`: AttrSet - Module-specific options
- `config`: AttrSet - Module configuration (guarded by mkIf)

**Source**: All modules follow this pattern (evidence: .claude/project.md:68-91)

#### User Account
**Purpose**: Represents a system user
**Key Fields**:
- `axios.user.name`: String - Username
- `axios.user.fullName`: String - Full name
- `axios.user.email`: String - Email address

**Source**: modules/users.nix, modules/system/

#### Timezone Configuration
**Purpose**: System timezone setting (REQUIRED, no default)
**Key Fields**:
- `axios.system.timeZone`: String - IANA timezone

**Source**: modules/system/, .claude/project.md:95-101

#### MCP Server Configuration
**Purpose**: Declarative MCP server definitions
**Key Fields**:
- `programs.claude-code.mcpServers`: AttrSet - Server configurations
- `command`: String - Server executable
- `args`: List - Server arguments
- `env`: AttrSet - Environment variables

**Source**: home/ai/mcp.nix

#### Secret Configuration
**Purpose**: Encrypted secret with agenix
**Key Fields**:
- `age.secrets.<name>.file`: Path - Encrypted secret file
- `age.secrets.<name>.owner`: String - Secret owner
- `age.secrets.<name>.mode`: String - File permissions

**Source**: modules/secrets/, home/secrets/

#### Caddy Route Registry
**Purpose**: Declarative reverse proxy route registration
**Key Fields**:
- `selfHosted.caddy.routes.<name>.domain`: String - Domain for this route
- `selfHosted.caddy.routes.<name>.path`: String|null - Path prefix (null = catch-all)
- `selfHosted.caddy.routes.<name>.target`: String - Upstream target URL
- `selfHosted.caddy.routes.<name>.priority`: Int - Route evaluation order (100 = path-specific, 1000 = catch-all)
- `selfHosted.caddy.routes.<name>.extraConfig`: Lines - Additional Caddy configuration

**Behavior**:
- Routes are automatically grouped by domain
- Routes are sorted by priority within each domain (lower = first)
- Path-specific routes (priority 100) are evaluated before catch-all routes (priority 1000)
- Services register routes independently without needing to know about other services

**Source**: modules/services/caddy.nix
**Evidence**: [EXPLICIT] (commit 9999853, 77ead21)

### Data Flow Patterns
- **Creation**: Users define configurations in their flake
- **Validation**: Nix evaluation validates types and structure
- **Persistence**: NixOS system rebuild applies configuration
- **Caching**: Nix store caches built artifacts, Cachix for binary caches

## Integration Points

### External Services
- **GitHub**: Repository hosting, CI/CD (GitHub Actions)
  - **Auth**: GitHub token for MCP server
  - **Failure Handling**: MCP server degrades gracefully
  - **Evidence**: .github/workflows/, home/ai/mcp.nix
- **Cachix**: Binary cache (niri.cachix.org, numtide.cachix.org)
  - **Auth**: Public keys in flake.nix
  - **Failure Handling**: Falls back to building from source
  - **Evidence**: flake.nix:112-124
- **Google Drive**: rclone-based sync
  - **Auth**: OAuth via `setup-gdrive-sync` script
  - **Failure Handling**: Manual retry, bisync prevents data loss
  - **Evidence**: home/desktop/gdrive-sync.nix
- **Tailscale**: Mesh VPN
  - **Auth**: Tailscale authentication key
  - **Failure Handling**: Service fails to start without auth
  - **Evidence**: modules/networking/tailscale.nix

## Acceptance Criteria (Current Behavior)

### Functional Criteria
- [✓] Users can generate axiOS configuration via interactive init script
- [✓] All NixOS modules can be independently imported and enabled
- [✓] Home-manager modules integrate with NixOS modules
- [✓] DevShells provide isolated development environments
- [✓] MCP servers are declaratively configured for AI tools
- [✓] Timezone must be explicitly set (no regional defaults)
- [✓] Packages are conditionally evaluated (inside mkIf blocks)
- [✓] Immich photo backup service runs with nixpkgs version
- [✓] Tailscale integration provides automatic HTTPS certificates
- [✓] Caddy reverse proxy configured for self-hosted services
- [✓] Caddy route registry automatically orders path-specific routes before catch-all
- [✓] Services register routes independently via `selfHosted.caddy.routes`
- [✓] Google Drive sync via rclone with bidirectional support

### Non-Functional Criteria
- [✓] Module evaluation is lazy (disabled modules don't evaluate)
- [✓] Build caching via Cachix reduces download times
- [✓] Code formatting enforced via CI
- [✓] Flake structure validated on every PR
- [✓] Weekly dependency updates automated

### Known Limitations
- Immich requires custom package (2.3.1) until nixpkgs updates
- Search MCP servers require API keys (brave-search, tavily)
- GitHub MCP server requires authentication token
- Google Drive sync requires manual OAuth setup
- Desktop focused primarily on Niri compositor
- System support primarily x86_64-linux

## Feature Flags
No traditional feature flags - module enable options serve this purpose:
- `desktop.enable`: Desktop environment
- `development.enable`: Development tools
- `gaming.enable`: Gaming configuration
- `services.ai.enable`: AI tools
- `networking.tailscale.enable`: Tailscale VPN
- Each module has its own enable flag

## Unknowns
- [TBD] Complete list of packages in each module
- [TBD] Specific gaming module features and packages
- [TBD] Virtualization module container runtime (Podman/Docker?)
- [TBD] Browser module capabilities
- [TBD] Calendar module integration details
- [TBD] Security module specific features
- [TBD] Full hardware module capabilities
- [TBD] Development module package list
- [TBD] Library function inventory
- [TBD] Testing strategy for module interactions
- [TBD] Performance benchmarks or budgets
- [TBD] Mobile app integration patterns beyond Immich
