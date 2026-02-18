# Module Reference

This guide explains every module axiOS provides, what it does, and when to use it.

**Quick Navigation:**
- [Core Modules](#core-modules) - Essential system configuration
- [Desktop & Applications](#desktop--applications) - Your daily workspace
- [Development Tools](#development-tools) - Programming environments
- [Optional Features](#optional-features) - Gaming, AI, and more
- [Self-Hosted Services](#self-hosted-services) - Run your own cloud
- [Hardware Modules](#hardware-modules) - Automatic hardware support

---

## How Modules Work

Each module in axiOS is like a feature toggle. When you enable a module, you get:
- All necessary packages pre-installed
- Everything configured and working together
- Sensible defaults you can customize

**Example:**
```nix
modules = {
  desktop = true;   # ✅ Installs Niri compositor, terminal, file manager
  gaming = false;   # ❌ Skips Steam, GameMode, gaming tools
};
```

---

## Core Modules

### system
**What it does:** Essential system configuration that every NixOS system needs.

**Includes:**
- Boot configuration with Plymouth branded splash screen
- Nix settings and garbage collection
- Core system packages (file utilities, compression tools, monitoring)
- Timezone and locale management (`axios.system.locale`, defaults to en_US.UTF-8)
- systemd-oomd for out-of-memory management
- PipeWire audio stack
- CUPS printing support
- Bluetooth support

**When to use:** Always enable this module (recommended: `true`)

**Configuration:**
```nix
modules.system = true;

extraConfig = {
  # REQUIRED: Set your timezone
  axios.system.timeZone = "America/New_York";

  # Optional: Override locale (defaults to en_US.UTF-8)
  axios.system.locale = "en_GB.UTF-8";
};
```

**Why is timezone required?**

axiOS is a library framework designed for users worldwide. Unlike personal configurations, we don't assume your location or preferences. Requiring explicit timezone configuration ensures your system matches your actual location rather than a hardcoded default that might be wrong.

This "library philosophy" applies throughout axiOS - no regional defaults, no hardcoded personal preferences. Your configuration expresses your choices explicitly.

---

### users
**What it does:** Multi-user account management and home directory setup.

**Includes:**
- User account creation via `axios.users.users.<name>` submodule
- Automatic group assignment based on enabled modules
- Home Manager integration with per-user profiles
- Git configuration from user's fullName and email

**When to use:** Always enable for home-manager support (recommended: `true`)

**Configuration:** Define users in `users/<name>.nix` files and reference them with `users = [ "alice" ]` in host config. See [USER_MODULE.md](USER_MODULE.md) for details.

---

### networking
**What it does:** Network connectivity, DNS, and firewall configuration.

**Includes:**
- NetworkManager for WiFi and wired connections
- Avahi/mDNS for local network discovery
- Firewall with sensible defaults
- VPN support (WireGuard, OpenVPN)

**When to use:** Almost always (recommended: `true`)

**Note:** Required if you enable `desktop` or `ai` modules.

---

### graphics
**What it does:** GPU drivers and hardware acceleration.

**Includes:**
- Automatic driver selection (AMD, NVIDIA, or Intel)
- OpenGL and Vulkan support
- Hardware video acceleration
- GPU monitoring tools (radeontop for AMD, nvtop for NVIDIA)
- **AMD GPU recovery** enabled (auto-reset on hang)

**When to use:** Enable if you have a desktop environment or play games

**Auto-configured:** Drivers chosen based on your `hardware.gpu` setting

```nix
hardware.gpu = "amd";  # Automatically loads AMD drivers + GPU recovery
```

---

## Desktop & Applications

### desktop
**What it does:** Complete desktop environment with modern Wayland compositor.

**Includes:**
- **[Niri](https://github.com/YaLTeR/niri)** - Scrollable tiling Wayland compositor
- **DankMaterialShell** - Material Design shell with custom theming and widgets
- **Ghostty** - Modern GPU-accelerated terminal
- **Dolphin** - KDE file manager (split-pane, plugin ecosystem)
- **LibreOffice** (Qt) - Full office suite with Material You theming
- Desktop applications (text editor, calculator, PDF viewer) - See [APPLICATIONS.md](APPLICATIONS.md)
- Fonts and icon themes

**When to use:** For laptops and desktops with a screen (not headless servers)

**Requirements:** Needs `networking = true`

**Home Profiles:**
- `workstation`: Full desktop with Logitech Solaar autostart
- `laptop`: Same desktop without Logitech autostart (mobile use)

---

### pim
**What it does:** Personal Information Management with axios-ai-mail.

**Includes:**
- **axios-ai-mail** - AI-powered email client with local LLM classification
- **vdirsyncer** - CLI tool for syncing calendars and contacts
- **mcp-dav** - Calendar and contacts access via CalDAV/CardDAV (from axios-dav)

**When to use:** If you need email with AI-powered smart inbox features

**Server/Client Architecture:**

Supports **server/client roles** for distributed deployment across your tailnet.

**Server Role** (runs axios-ai-mail service):
```nix
modules.pim = true;

extraConfig = {
  services.pim = {
    user = "your-username";
    pwa.enable = true;
    pwa.tailnetDomain = "your-tailnet.ts.net";
  };
};
```

**Client Role** (PWA only, connects to server):
```nix
modules.pim = true;

extraConfig = {
  services.pim = {
    role = "client";
    pwa.enable = true;
    pwa.tailnetDomain = "your-tailnet.ts.net";
  };
};
```

**Access:** Via PWA at `https://axios-mail.<tailnet>.ts.net`

See [TAILSCALE_SERVICES.md](TAILSCALE_SERVICES.md) for Tailscale Services setup.

---

## Development Tools

### development
**What it does:** Programming tools and development environments.

**Includes:**
- **Editors:** VS Code, Neovim (with axios IDE preset)
- **Version control:** Git, GitHub CLI
- **Compilers:** GCC, Clang, Rust, Zig toolchains
- **Build tools:** Make, CMake, Meson
- **Languages:** Python, Node.js, Go environments
- **Database clients:** pgcli (PostgreSQL), litecli (SQLite)
- **API testing:** httpie, mitmproxy, k6
- **Diff & diagnostics:** difftastic (structural diff), btop (system monitor), mtr (network), dog (DNS)
- **DevShells:** Project-specific toolchains via `nix develop`

**When to use:** For software developers and programmers

**DevShells Available:**
```bash
nix develop github:kcalvelli/axios#rust   # Rust environment
nix develop github:kcalvelli/axios#zig    # Zig environment
nix develop github:kcalvelli/axios#qml    # Qt/QML environment
```

---

## Optional Features

### gaming
**What it does:** Gaming platform and optimization tools.

**Includes:**
- **Steam** with Proton and Proton-GE for Windows games
- **GameMode** for CPU/GPU optimization
- **Gamescope** session support
- **mangohud** performance overlay
- **prismlauncher** (Minecraft launcher)
- **superTuxKart** racing game
- **nix-ld** for native Linux game binary compatibility
- **VR support** (optional, via `vr.nix`)

**When to use:** If you play games on this computer

**Requirements:** Needs `graphics = true`

**Note:** Gaming is not auto-disabled on laptops. Set `modules.gaming = false` in laptop host configs if you don't need it.

---

### virt
**What it does:** Virtual machines and container support.

**Includes:**
- **libvirt/QEMU** for full virtual machines
- **Podman** for containers
- **virt-manager** GUI for VM management
- USB passthrough and hardware virtualization

**When to use:** For running VMs or testing other operating systems

**Configuration:**
```nix
modules.virt = true;

virt = {
  libvirt.enable = true;      # Enable VMs
  containers.enable = true;   # Enable Podman containers
};
```

---

### ai
**What it does:** AI-powered development assistants with optional local LLM inference.

**Two-Tier Architecture:**

1. **Base AI Tools** (always included when `services.ai.enable = true`):
   - **CLI Coding Agents** (4 agents across 3 AI ecosystems):
     - **claude-code** - Anthropic's CLI agent with MCP support
     - **claude-code-acp** - Claude Code Agent Communication Protocol
     - **claude-code-router** - Claude Code request router
     - **gemini** - Google's multimodal CLI agent with free tier
     - **antigravity** - Advanced agentic assistant for axiOS development
   - **Workflow & Support Tools**:
     - **openspec** - OpenSpec SDD workflow CLI for spec-driven development
     - **spec-kit** - Spec-driven development framework
     - **claude-monitor** - Real-time AI session resource monitoring
     - **whisper-cpp** - Local speech-to-text transcription

2. **Local LLM Stack** (optional via `services.ai.local.enable = true`):
   - **Ollama** - Local inference backend with ROCm GPU acceleration
   - **OpenCode** - Agentic CLI for coding tasks with full file editing

**When to use:**
- **Base tools:** For cloud-based AI assistance (requires API keys/subscriptions)
- **Local LLM:** For private, offline AI inference with your own hardware

**Requirements:**
- Needs `networking = true` for base tools
- AMD GPU recommended for local LLM (8GB+ VRAM for larger models)
- 16GB+ system RAM recommended for local models

---

#### Local LLM Configuration

The local LLM stack supports **server/client roles** for distributed inference across your tailnet.

**Server Role (default):**

Run Ollama locally with GPU acceleration:

```nix
services.ai.local = {
  enable = true;
  role = "server";  # Default - runs Ollama locally with GPU

  # Model management (defaults: mistral:7b + nomic-embed-text)
  models = [
    "mistral:7b"             # General purpose (~4.4GB)
    "nomic-embed-text"       # Embeddings for RAG (~274MB)
  ];

  # AMD GPU configuration
  rocmOverrideGfx = "10.3.0";  # For RX 5500/5600/5700 series

  # GPU memory management
  keepAlive = "1m";  # Unload models after 1 minute of inactivity

  # Optional components
  cli = true;  # OpenCode (default: true)
};
```

**Client Role:**

Connect to a remote Ollama server (no local GPU required):

```nix
services.ai.local = {
  enable = true;
  role = "client";  # Use remote Ollama server

  # Required: Specify your tailnet domain
  tailnetDomain = "taile0fb4.ts.net";

  # Optional components
  cli = true;  # OpenCode still works, connects to remote Ollama
};
```

The server registers as `axios-ollama.<tailnet>.ts.net` via Tailscale Services. Clients automatically use this DNS name via the `OLLAMA_HOST` environment variable.

**Features (Server Role):**
- **32K context window** for agentic tool use
- **Automatic model preloading** on service start
- **ROCm acceleration** with automatic gfx override for older AMD GPUs
- **Tailscale Services** registration for secure remote access

**Usage:**

```bash
# Ollama CLI (server or client)
ollama run mistral:7b "Write a function to..."

# OpenCode CLI (works with both roles)
opencode "implement feature X with tests"
```

---

#### MCP Servers

Model Context Protocol servers provide enhanced context to AI assistants:

**Core Servers:**
- `filesystem` - Local file system access
- `git` - Repository structure and history
- `github` - Issues, PRs, and repository data (requires token)
- `time` - Time zone operations
- `journal` - systemd journal logs
- `nix-devshell-mcp` - Nix development shell integration

**PIM Integration:**
- `axios-ai-mail` - AI-powered email access and management
- `mcp-dav` - Calendar and contacts via CalDAV/CardDAV

**AI Enhancement:**
- `sequential-thinking` - Multi-step reasoning
- `context7` - Documentation retrieval

**Search (requires API keys):**
- `brave-search` - Web search via Brave API

**Configuration:** MCP servers are automatically configured for Claude Code. API keys can be stored securely using the `secrets` module.

**See also:**
- [SECRETS_MODULE.md](SECRETS_MODULE.md) for API key setup
- [APPLICATIONS.md](APPLICATIONS.md) for complete tool descriptions

---

### secrets
**What it does:** Encrypted secrets management using age encryption.

**Includes:**
- **agenix** for encrypting sensitive data
- Automatic decryption at boot time
- Secure storage in `/run/secrets/` (tmpfs, cleared on reboot)
- File permissions and access control

**When to use:** When you have API keys, passwords, or other sensitive data

**Common uses:**
- API keys for AI services (Brave Search)
- Tailscale authentication keys
- SSH keys and certificates
- Database passwords

**See:** [SECRETS_MODULE.md](SECRETS_MODULE.md) for complete setup guide

---

### syncthing
**What it does:** Peer-to-peer XDG directory synchronization across axiOS hosts via Tailscale.

**Includes:**
- **Syncthing** daemon with declarative folder and device configuration
- Tailscale-only transport (no external discovery, relays, or NAT traversal)
- XDG-aware folders (declare `documents`, `music`, `pictures`, etc. instead of raw paths)
- MagicDNS device addressing (devices referenced by Tailscale machine name)

**When to use:** To keep Documents, Music, Pictures, and other XDG directories in sync across multiple axiOS machines

**Requirements:** Needs `networking = true` (for Tailscale). `networking.tailscale.domain` must be set.

**Configuration:**

```nix
modules.syncthing = true;

extraConfig = {
  axios.syncthing = {
    user = "alice";  # User whose XDG dirs are synced

    # Declare peer devices (attr name = Tailscale machine name)
    devices = {
      laptop.id  = "AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG-HHHHHHH";
      server.id  = "IIIIIII-JJJJJJJ-KKKKKKK-LLLLLLL-MMMMMMM-NNNNNNN-OOOOOOO-PPPPPPP";
    };

    # Declare which XDG dirs to sync and with which devices
    folders = {
      documents.devices = [ "laptop" "server" ];
      music.devices     = [ "laptop" ];
      pictures.devices  = [ "laptop" ];
    };
  };
};
```

**Getting Device IDs (one-time bootstrap):**

```bash
# 1. Enable the module and rebuild (device IDs can be placeholders initially)
# 2. After rebuild, get the device ID:
syncthing cli show system | grep myID

# 3. Add real device IDs to all host configs and rebuild again
```

**Supported XDG folders:** `documents`, `music`, `pictures`, `videos`, `downloads`, `templates`, `desktop`, `publicshare`

**Selective sync:** Each host independently declares which folders it participates in. A server might sync only `documents`, while a workstation syncs everything.

**Device name override:** If the device attr name doesn't match the Tailscale machine name:

```nix
devices.phone = {
  id = "QQQQQQQ-...";
  tailscaleName = "google-pixel-10";  # Override MagicDNS name
};
```

**Custom addresses (escape hatch):** For non-Tailscale devices:

```nix
devices.external = {
  id = "RRRRRRR-...";
  addresses = [ "tcp://192.168.1.100:22000" ];
};
```

**Conflict handling:** Syncthing creates `.sync-conflict-*` files by default. Optionally configure per-folder ignore patterns:

```nix
folders.documents = {
  devices = [ "laptop" ];
  ignorePatterns = [ "*.tmp" ".DS_Store" ];
};
```

---

### services
**What it does:** Enables self-hosted services on your system.

**When to use:** Run your own cloud services instead of relying on third parties

**Enables:** The `axios.immich` configuration section (see below)

---

## Self-Hosted Services

### axios.immich (Immich Photo Backup)

When you enable `modules.services = true`, you can configure Immich.

**What it is:** Self-hosted photo and video management (Google Photos alternative)

**Features:**
- Automatic photo backup from mobile devices
- AI-powered face detection and object recognition
- Timeline organization and search
- Sharing and albums
- Mobile apps for iOS and Android
- **GPU acceleration** for faster ML processing

**Server/Client Architecture:**

Supports **server/client roles** for distributed deployment across your tailnet.

**Server Role** (runs Immich service):
```nix
modules.services = true;

# In hostConfig (outside extraConfig):
axios = {
  immich = {
    enable = true;
    enableGpuAcceleration = true;  # Use GPU for ML (faster)
    gpuType = "amd";               # Match your GPU type
    pwa = {
      enable = true;
      tailnetDomain = "your-tailnet.ts.net";
    };
  };
};
```

**Client Role** (PWA only, connects to server):
```nix
modules.services = true;

extraConfig = {
  axios.immich = {
    enable = true;
    role = "client";
    pwa = {
      enable = true;
      tailnetDomain = "your-tailnet.ts.net";
    };
  };
};
```

**Access:** Via PWA at `https://axios-immich.<tailnet>.ts.net`

**Requirements:**
- Tailscale for secure remote access
- GPU recommended for ML features (optional, server only)
- Storage space for photos/videos (server only)

**Mobile Setup:** Install Immich mobile app, point it to your Tailscale Services URL

See [TAILSCALE_SERVICES.md](TAILSCALE_SERVICES.md) for Tailscale Services setup.

---

## Hardware Modules

These modules are automatically enabled based on your hardware configuration. You don't enable them directly.

### crashDiagnostics
**What it does:** Helps recover from system freezes and crashes.

**Features:**
- Automatic reboot on kernel panic (no more manual power cycles!)
- Treats kernel errors as fatal (prevents zombie systems)
- Optional crash dumps for debugging (uses RAM, disabled by default)
- Better freeze diagnostics

**When it's useful:**
- Desktop systems prone to occasional freezes
- Systems with unstable hardware
- Debugging kernel issues

**Configuration:**
```nix
extraConfig = {
  hardware.crashDiagnostics = {
    enable = true;
    rebootOnPanic = 30;            # Reboot after 30 seconds
    treatOopsAsPanic = true;       # Aggressive recovery
    enableCrashDump = false;       # Save RAM
    enableHardwareWatchdog = false; # Hardware watchdog timer
    runtimeWatchdogSec = null;     # systemd watchdog (e.g., "30s")
  };
};
```

**Trade-offs:**
- Automatic recovery from freezes
- System won't stay in broken state
- No manual debugging time (reboots automatically)

---

### desktopHardware
**Auto-enabled when:** `formFactor = "desktop"`

**Includes:**
- Desktop-specific power settings (no aggressive power saving)
- PCIe optimizations
- Multi-monitor support
- **MSI motherboard sensors** (if `vendor = "msi"`)

---

### laptopHardware
**Auto-enabled when:** `formFactor = "laptop"`

**Includes:**
- CPU frequency governor (default: powersave for battery life)
- Power management
- SSD TRIM
- Laptop-specific kernel modules
- **System76 support** (if `vendor = "system76"`)

---

## Module Dependencies

Some modules require others to work properly:

| Module | Requires | Why |
|--------|----------|-----|
| `desktop` | `networking` | Desktop services need network |
| `gaming` | `graphics` | Games need GPU drivers |
| `ai` | `networking` | AI tools need internet access |
| `syncthing` | `networking` | Syncthing uses Tailscale for transport |

axiOS automatically checks these and will show a clear error if dependencies are missing.

---

## Choosing Your Modules

### Minimal Desktop (Lightweight)
```nix
modules = {
  system = true;
  desktop = true;
  networking = true;
  users = true;
  graphics = true;
  # Everything else = false
};
```

### Developer Workstation (Full Featured)
```nix
modules = {
  system = true;
  desktop = true;
  development = true;
  networking = true;
  users = true;
  graphics = true;
  pim = true;            # Email, calendar, contacts
  virt = true;           # VMs for testing
  ai = true;             # AI coding assistants
  secrets = true;        # Secure API keys
  # gaming/services = optional
};
```

### Self-Hosted Server (Headless)
```nix
modules = {
  system = true;
  networking = true;
  users = true;
  services = true;       # Immich, Caddy
  secrets = true;        # Tailscale keys
  desktop = false;       # No GUI needed
};
```

---

## Configuration Options

All options can be set in `extraConfig` within your host configuration.

### System Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `axios.system.timeZone` | string | *required* | IANA timezone (e.g., "America/New_York") |
| `axios.system.locale` | string | `"en_US.UTF-8"` | System locale |
| `axios.system.bluetooth.powerOnBoot` | bool | `true` | Auto-power Bluetooth at boot |
| `axios.system.performance.swappiness` | int | `10` | VM swappiness (0-100) |
| `axios.system.performance.zramPercent` | int | `25` | Percentage of RAM for zram swap |
| `axios.system.performance.enableNetworkOptimizations` | bool | `true` | BBR congestion control + optimized buffers |

### Hardware Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hardware.desktop.cpuGovernor` | string | `"powersave"` | CPU frequency governor for desktops |
| `hardware.desktop.enableLogitechSupport` | bool | `false` | Logitech Unifying receiver support |
| `hardware.laptop.cpuGovernor` | string | `"powersave"` | CPU frequency governor for laptops |
| `axios.hardware.enableGPURecovery` | bool | `true` (AMD) | Auto GPU hang recovery (AMD only) |
| `axios.hardware.nvidiaDriver` | enum | `"stable"` | Nvidia driver: "stable", "beta", "production" |

### Boot Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `boot.lanzaboote.enableSecureBoot` | bool | `false` | Enable Lanzaboote secure boot |

### AI Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `services.ai.enable` | bool | via module flag | Enable AI tools |
| `services.ai.mcp.enable` | bool | `true` | Enable MCP servers (when AI is enabled) |
| `services.ai.claude.enable` | bool | `true` | Enable Claude Code |
| `services.ai.gemini.enable` | bool | `true` | Enable Gemini CLI |
| `services.ai.local.enable` | bool | `false` | Enable local LLM stack (Ollama) |
| `services.ai.local.role` | enum | `"server"` | "server" or "client" |
| `services.ai.local.models` | list | `["mistral:7b" "nomic-embed-text"]` | Models to preload |
| `services.ai.local.cli` | bool | `true` | Enable OpenCode agentic CLI |
| `services.ai.local.keepAlive` | string | `"1m"` | Model unload timeout |

---

## Next Steps

- **Basic setup:** [INSTALLATION.md](INSTALLATION.md)
- **API reference:** [LIBRARY_USAGE.md](LIBRARY_USAGE.md)
- **Secrets setup:** [SECRETS_MODULE.md](SECRETS_MODULE.md)
- **Common issues:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Questions?

- Not sure which modules you need? Start with `system`, `desktop`, `networking`, `users`, `graphics`
- Want everything? Enable all modules and customize later
- Have specific hardware? Set `vendor` to enable hardware-specific optimizations
- Running into issues? Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
