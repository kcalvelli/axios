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
  - VPN: VPN status widget
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

#### Web Browser
- **Purpose**: Privacy-focused web browsing with development tools
- **Implementation Evidence**: home/browser/default.nix
- **Confidence**: [EXPLICIT]
- **Browsers**:
  - **Brave Stable**: Primary browser (default)
  - **Brave Nightly**: Bleeding-edge version for testing
- **Configuration**:
  - Shared extensions (Password managers, AI tools, Dev tools)
  - Shared command line arguments (Password store detection, GTK4)
  - Managed via Home Manager `programs.brave` and custom wrappers

#### Desktop Applications
- **Purpose**: Best-in-class application suite selected for functionality and user experience
- **Implementation Evidence**: modules/desktop/default.nix:21-93
- **Confidence**: [EXPLICIT]
- **Selection Criteria**: Applications chosen based on merit, not toolkit (GTK vs Qt)
- **Theming**: Both GTK and Qt applications receive Material You theming equally via kdeglobals and dank-colors.css
- **Categories**:
  - **File Management**: Dolphin (KDE), Ark (KDE), Filelight (KDE)
  - **Productivity**: Obsidian, Discord, Ghostwriter (KDE), LibreOffice (Qt6 backend), 1Password, Kate (KDE)
  - **Media Creation**: Kdenlive (KDE), Krita (KDE), Inkscape
  - **Media Viewing**: DigiKam (KDE), Loupe (GNOME), Haruna (KDE), Amberol (GNOME)
  - **System Utilities**: GNOME Disks, Swappy, Qalculate (Qt), Fuzzel, GNOME Software
  - **Document Viewers**: Okular (KDE - best-in-class PDF annotations)
  - **Security**: Seahorse (GNOME - password and encryption key manager)
  - **Communication**: Evolution (email client with Exchange/EWS support)
  - **PIM**: GNOME Calendar, GNOME Contacts (Evolution Data Server backend)
  - **Streaming**: OBS Studio
- **Application Choices Rationale**:
  - **KDE Apps**: Dolphin (split-pane, plugins), Kdenlive (industry standard), Krita (professional), DigiKam (asset management), Kate (LSP support), Okular (annotations), Filelight (radial visualization), Haruna (MPV frontend)
  - **GNOME Apps**: Loupe (speed, gestures), Amberol (simplicity), GNOME Disks (UX), Evolution/Calendar/Contacts (reliability over KDE-PIM's Akonadi)
  - **Qt Apps**: LibreOffice Qt6 (consistent theming), Qalculate-qt (modern port)
  - **Avoided**: KDE-PIM suite (Merkuro, KAddressBook, KMail) due to Akonadi backend reliability issues

#### GNOME Online Accounts Integration
- **Purpose**: Unified account management for email, calendar, and contacts without full GNOME desktop
- **Implementation Evidence**: modules/desktop/default.nix:84-86, 137-143
- **Confidence**: [EXPLICIT]
- **Components**:
  - **gnome-online-accounts-gtk**: Lightweight GTK UI for account configuration
  - **Evolution**: Email client with GNOME Online Accounts integration (programs.evolution.enable)
  - **GNOME Calendar**: Calendar application syncing via online accounts
  - **GNOME Contacts**: Contact management syncing via online accounts
- **Required Backend Services**:
  - **services.gnome.evolution-data-server.enable**: Provides D-Bus service `org.gnome.evolution.dataserver.Sources5` for calendar/contacts data storage
  - **services.geoclue2.enable**: Provides location services (`org.freedesktop.GeoClue2`) for weather features in calendar
- **Supported Services**: Gmail, Outlook, IMAP/SMTP, CalDAV, CardDAV
- **Architecture**: Uses D-Bus services and GNOME keyring without requiring full GNOME desktop
- **Integration**: Accounts configured once in gnome-online-accounts-gtk, automatically available to all PIM apps
- **Rationale**: Evolution Data Server is a lightweight background service that provides data backends, not the full Evolution email client

#### Wallpaper & Theming
- **Purpose**: Automatic wallpaper management with blur effects and curated wallpaper collection
- **Implementation Evidence**: home/desktop/wallpaper.nix, home/desktop/theming.nix, home/resources/wallpapers/
- **Confidence**: [EXPLICIT]
- **Features**:
  - **Dynamic Blur**: Wallpaper blur effects for Niri compositor
  - **Theme Coordination**: Material You color extraction via matugen
  - **Wallpaper Collection**: Curated wallpapers deployed to `~/Pictures/Wallpapers`
    - Enabled in user.nix via `axios.wallpapers.enable = true` (home-manager option)
    - Auto-deploys wallpapers from `home/resources/wallpapers/`
    - Auto-detects collection changes via SHA256 hash of wallpaper filenames
    - Sets random wallpaper when collection changes (controlled by `axios.wallpapers.autoUpdate`, default: true)
    - Collection updates automatically when user rebuilds after axios flake update
    - Hash tracking via `~/.cache/axios-wallpaper-collection-hash`
    - Supports PNG, JPG, JPEG formats
    - Configuration location: `home-manager.users.${username}.axios.wallpapers` in user.nix

#### Progressive Web Apps (PWA)
- **Purpose**: Extensible PWA support for custom web applications
- **Implementation Evidence**: CHANGELOG.md:49, home/desktop/pwa-apps.nix, pkgs/pwa-apps/
- **Confidence**: [EXPLICIT]

#### Flatpak & Application Installation
- **Purpose**: Provide sandboxed application installation via Flathub as the primary method for users to add applications
- **Implementation Evidence**: modules/desktop/default.nix:154-173, home/desktop/theming.nix:68-72
- **Confidence**: [EXPLICIT]
- **Components**:
  - **Flatpak Service**: Enabled system-wide (`services.flatpak.enable = true`)
  - **GNOME Software**: Graphical app store for browsing and installing Flatpaks
  - **Flathub Remote**: Automatically configured via systemd oneshot service
  - **Theme Integration**: Flatpak apps access GTK themes via `xdg.dataFile."flatpak/overrides/global"`
- **Architecture**:
  - **Automatic Setup**: `systemd.services.flatpak-add-flathub` runs after network-online
  - **Idempotent**: Uses `--if-not-exists` to prevent duplicate remote additions
  - **GNOME Software Configuration**: Environment variables set to use Flathub exclusively
- **User Experience**:
  - **Primary Installation Method**: Flathub recommended for most users (non-technical)
  - **Benefits**: Sandboxed apps, latest versions, no system rebuilds, GUI installation
  - **Alternative**: Technical users can add packages via `extraConfig.environment.systemPackages`
- **Design Philosophy**:
  - Flatpak provides better UX for desktop applications (sandboxing, updates, GUI)
  - NixOS packages reserved for system tools, CLI utilities, and reproducible builds
  - Reduces maintenance burden on axiOS (doesn't need to package every GUI app)

### Development Tools
#### Development Shells
- **Purpose**: Project-specific development environments with complete toolchains
- **Implementation Evidence**: devshells/*.nix, devshells.nix
- **Confidence**: [EXPLICIT]
- **Environments**:
  - **Rust**: Fenix stable toolchain with cargo, rustc, rust-analyzer, cargo-watch (devshells/rust.nix)
  - **Zig**: Latest Zig compiler with ZLS language server (devshells/zig.nix)
  - **QML**: Qt6 development with QML tools, CMake, Ninja for Quickshell/Qt projects (devshells/qml.nix)
  - **.NET**: .NET SDK 9, Mono runtime, Avalonia tools, ILSpy decompiler (devshells/dotnet.nix)
- **Features**:
  - Helpful commands for each environment (build, run, test, etc.)
  - Shell-specific environment variables (e.g., `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`)
  - Runtime dependencies included (libraries, development tools)
- **Access**: `nix develop .#<shell-name>` or `nix develop github:kcalvelli/axios#<shell-name>`

#### Terminal Configuration
- **Purpose**: Comprehensive terminal experience with modern tools
- **Implementation Evidence**: home/terminal/
- **Confidence**: [EXPLICIT]
- **Components**:
  - **Ghostty**: GPU-accelerated terminal emulator (home/terminal/ghostty.nix)
  - **Fish shell**: Modern shell with completions (home/terminal/fish.nix)
  - **Starship**: Customizable prompt (home/terminal/starship.nix)
  - **Git**: Git configuration and aliases (home/terminal/git.nix)
  - **CLI Tools**: Modern replacements (bat, eza, fd, ripgrep, etc.) (home/terminal/tools.nix)

### AI & Development Assistance
#### AI Tools Integration
- **Purpose**: Opinionated AI assistant integration with 3 distinct AI ecosystems
- **Implementation Evidence**: modules/ai/default.nix:109-138, home/ai/, flake.nix:97-103
- **Confidence**: [EXPLICIT]
- **CLI Coding Agents** (3 distinct AI providers):
  - **claude-code**: Anthropic's CLI agent with MCP support and deep integration
  - **copilot-cli**: GitHub/OpenAI CLI agent with GitHub ecosystem integration
  - **gemini-cli**: Google's multimodal CLI agent with free tier
- **Workflow & Support Tools**:
  - **spec-kit**: Spec-driven development framework (used by axiOS spec-kit-baseline/)
  - **backlog-md**: Project management for human-AI collaboration
  - **claude-monitor**: Resource monitoring for AI sessions
  - **whisper-cpp**: Speech-to-text tool

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
- **Implementation Evidence**: modules/graphics/default.nix
- **Confidence**: [EXPLICIT]
- **Supported GPUs**: NVIDIA, AMD, Intel
- **Options**:
  - `axios.hardware.gpuType`: GPU type ("nvidia", "amd", "intel")
  - `axios.hardware.isLaptop`: Whether this is a laptop (affects PRIME)
  - `axios.hardware.nvidiaDriver`: Nvidia driver version ("stable", "beta", "production")
  - `axios.hardware.enableGPURecovery`: AMD GPU hang recovery (AMD only)
- **Features**:
  - Hardware acceleration (VA-API, Vulkan)
  - 32-bit library support for gaming
  - GPU-specific utilities (nvtop, radeontop, intel-gpu-tools)
  - Graphics debugging (renderdoc)
  - Wayland support with proper kernel parameters
- **Nvidia-specific**:
  - Driver version selection (stable for reliability, beta for RTX 50-series/Blackwell)
  - Open kernel module by default (RTX 20+/Turing and newer)
  - Wayland modesetting support (`nvidia_drm.modeset=1`)
  - PRIME defaults to disabled on desktops (configurable for dual-GPU setups)
  - Power management disabled by default (avoids suspend/resume issues)
- **AMD-specific**:
  - AMDGPU kernel module in initrd
  - Optional GPU recovery for stability issues
- **Intel-specific**:
  - Mesa with Intel Vulkan driver
  - Intel media driver for VA-API

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

#### Boot Configuration
- **Purpose**: UEFI boot with systemd-boot and optional Secure Boot
- **Implementation Evidence**: modules/system/boot.nix, flake.nix:42-48
- **Confidence**: [EXPLICIT]
- **Requirement**: UEFI boot mode only (BIOS/MBR not supported)
- **Bootloader**: systemd-boot with EFI variable support
- **Secure Boot**: Optional Lanzaboote integration (disabled by default)

### Gaming
#### Gaming Configuration
- **Purpose**: Gaming-optimized system configuration
- **Implementation Evidence**: modules/gaming/default.nix
- **Confidence**: [EXPLICIT]
- **Features**:
  - Steam with Proton GE, protontricks, remote play
  - GameMode with CPU/GPU optimizations
  - MangoHud performance overlay
  - Gamescope compositor
  - nix-ld for binary compatibility (indie games, Unity, MonoGame)
  - VR gaming support (optional, see below)

#### VR Gaming Support
- **Purpose**: Virtual reality gaming with Steam VR and wireless VR streaming
- **Implementation Evidence**: modules/gaming/vr.nix
- **Confidence**: [EXPLICIT]
- **Options**:
  - `gaming.vr.enable`: Enable VR support with Steam hardware and OpenXR
  - `gaming.vr.wireless.enable`: Enable wireless VR streaming
  - `gaming.vr.wireless.backend`: Choose "wivrn", "alvr", or "both"
  - `gaming.vr.wireless.wivrn.*`: WiVRn-specific options (firewall, runtime, autostart)
  - `gaming.vr.overlays`: Enable VR overlay applications (wlx-overlay-s, wayvr-dashboard)
- **Features**:
  - Steam hardware support for VR controllers/headsets
  - WiVRn wireless VR with hardware encoding (CUDA for Nvidia)
  - ALVR alternative wireless VR backend
  - OpenComposite OpenXR compatibility layer
  - Wayland-native VR overlays

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
3. Generator creates configuration in ~/.config/nixos_config/:
   - flake.nix (from template)
   - user.nix (from template)
   - hosts/HOSTNAME.nix (from template)
   - hosts/HOSTNAME/hardware.nix (copied from /etc/nixos/hardware-configuration.nix)
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
- `rust`: Rust development environment (Fenix stable toolchain)
- `zig`: Zig development environment (latest Zig)
- `qml`: Qt/QML development environment (Qt6, CMake, Ninja)
- `dotnet`: .NET development environment (.NET SDK 9, Mono, Avalonia)

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
- [✓] GNOME Online Accounts provides unified account management for PIM apps
- [✓] Evolution email client integrates with GNOME Online Accounts
- [✓] GNOME Calendar and Contacts sync via GNOME Online Accounts

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
- [TBD] Virtualization module container runtime details (Podman confirmed, Docker alternative documented)
- [TBD] Calendar module integration details
- [TBD] Security module specific features
- [TBD] Full hardware module capabilities
- [TBD] Development module package list
- [TBD] Library function inventory
- [TBD] Testing strategy for module interactions
- [TBD] Performance benchmarks or budgets
- [TBD] Mobile app integration patterns beyond Immich
