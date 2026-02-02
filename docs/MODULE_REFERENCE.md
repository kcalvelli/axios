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
- Boot configuration (systemd-boot or GRUB)
- Nix settings and garbage collection
- Core system packages (file utilities, compression tools)
- Timezone and locale management

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
**What it does:** Manages your user account and home directory setup.

**Includes:**
- User account creation
- Home Manager integration
- Shell configuration
- User environment variables

**When to use:** Always enable for home-manager support (recommended: `true`)

**Required:** You must provide a `userModulePath` with your user configuration.

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
- GPU monitoring tools (radeontop for AMD, nvidia-smi for NVIDIA)
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
- **Nautilus** - GNOME file manager
- **Idle Management** - Automatic screen power-off after 30 minutes (swayidle)
- Desktop applications (text editor, calculator, PDF viewer) - See [APPLICATIONS.md](APPLICATIONS.md)
- Fonts and icon themes
- **Google Drive sync** (setup with `setup-gdrive-sync` command)

**When to use:** For laptops and desktops with a screen (not headless servers)

**Requirements:** Needs `networking = true`

**Home Profiles:**
- `workstation`: Full desktop with productivity apps
- `laptop`: Optimized for battery life and portability

**Idle Management:**

axiOS includes automatic idle management using swayidle:
- **Default timeout**: 30 minutes of inactivity
- **Action**: Powers off monitors via `niri msg action power-off-monitors`
- **Service**: Managed by systemd user service (auto-starts with desktop)
- **Manual lock**: Super+Alt+L (DankMaterialShell lock screen)

**Customizing idle timeout:**

```nix
# In your user configuration (home-manager)
services.swayidle.timeouts = [
  {
    timeout = 600;  # 10 minutes
    command = "niri msg action power-off-monitors";
  }
  # Add additional actions:
  {
    timeout = 900;   # 15 minutes
    command = "systemctl suspend";  # Suspend system
  }
];
```

---

### pim
**What it does:** Personal Information Management with axios-ai-mail.

**Includes:**
- **axios-ai-mail** - AI-powered email client with local LLM classification
- **vdirsyncer** - CLI tool for syncing calendars and contacts

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
- **Editors:** VS Code
- **Version control:** Git, GitHub CLI
- **Compilers:** GCC, Clang, Rust, Zig toolchains
- **Build tools:** Make, CMake, Meson
- **Languages:** Python, Node.js, Go environments
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
- **Steam** with Proton for Windows games
- **GameMode** for CPU/GPU optimization
- **Gamescope** for better game compatibility
- Performance tweaks and optimizations

**When to use:** If you play games on this computer

**Requirements:** Needs `graphics = true`

**Note:** Automatically disabled on laptop profile to save resources.

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
   - **CLI Coding Agents** (3 distinct AI ecosystems):
     - **claude-code** - Anthropic's CLI agent with MCP support
     - **claude-code-acp** - Claude Code Agent Communication Protocol
     - **claude-code-router** - Claude Code request router
     - **copilot-cli** - GitHub/OpenAI CLI agent with GitHub integration
     - **gemini** - Google's multimodal CLI agent with free tier
   - **Workflow & Support Tools**:
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

  # Model management
  models = [
    "qwen3-coder:30b"        # Primary agentic coding (~4GB VRAM)
    "qwen3:14b"              # General reasoning (~10GB VRAM)
    "deepseek-coder-v2:16b"  # Multilingual coding (~11GB VRAM)
    "qwen3:4b"               # Fast completions (~3GB VRAM)
  ];

  # AMD GPU configuration
  rocmOverrideGfx = "10.3.0";  # For RX 5500/5600/5700 series

  # Optional components
  cli = true;  # OpenCode (default: true)

  # Expose Ollama API via Tailscale HTTPS (recommended)
  tailscaleServe = {
    enable = true;
    httpsPort = 8447;  # Default port
  };
};
```

**Client Role:**

Connect to a remote Ollama server (no local GPU required):

```nix
services.ai.local = {
  enable = true;
  role = "client";  # Use remote Ollama server

  # Required: Specify your Ollama server
  serverHost = "edge";           # Hostname on tailnet (e.g., "edge" for edge.taile0fb4.ts.net)
  tailnetDomain = "taile0fb4.ts.net";  # Your tailnet domain
  serverPort = 8447;             # Default port (matches server's tailscaleServe.httpsPort)

  # Optional components
  cli = true;  # OpenCode still works, connects to remote Ollama
};
```

**Benefits of Server/Client Architecture:**
- 🖥️ **Powerful desktop** runs inference with GPU acceleration
- 💻 **Lightweight laptops** get AI capabilities without GPU stack
- 🔒 **Secure** over Tailscale VPN (end-to-end encrypted)
- 📦 **Lighter footprint** on clients (no ROCm, no amdgpu kernel module)

**Features (Server Role):**
- **32K context window** for agentic tool use
- **Automatic model preloading** on service start
- **ROCm acceleration** with automatic gfx1031 override for older AMD GPUs
- **MCP server support** in OpenCode
- **LSP integration** for code intelligence

**Usage:**

```bash
# Ollama CLI (server or client)
ollama run qwen3-coder:30b "Write a function to..."

# OpenCode CLI (works with both roles)
opencode "implement feature X with tests"
```

**Remote Access:**

When `tailscaleServe.enable = true` (server role):
- Access Ollama via HTTPS: `https://[hostname].[tailscale-domain]:8447`
- Uses Tailscale certificates (automatic)
- Other machines on tailnet can connect by setting `role = "client"`

**Legacy (Deprecated):**

The `ollamaReverseProxy` option is deprecated in favor of `tailscaleServe`. If you're using it:
```nix
# Old (deprecated)
services.ai.local.ollamaReverseProxy.enable = true;

# New (recommended)
services.ai.local.tailscaleServe.enable = true;
```

---

#### MCP Servers

Model Context Protocol servers provide enhanced context to AI assistants:

**Core Servers:**
- `filesystem` - Local file system access
- `git` - Repository structure and history
- `github` - Issues, PRs, and repository data (requires token)
- `time` - Time zone operations

**NixOS Integration:**
- `mcp-nixos` - Search packages and options
- `journal` - systemd journal logs
- `nix-devshell-mcp` - Nix development shell integration

**AI Enhancement:**
- `sequential-thinking` - Multi-step reasoning
- `context7` - Documentation retrieval

**Search (requires API keys):**
- `brave-search` - Web search via Brave API
- `tavily` - Advanced research

**Configuration:** MCP servers are automatically configured for Claude Code. API keys can be stored securely using the `secrets` module.

**See also:**
- [SECRETS_MODULE.md](SECRETS_MODULE.md) for API key setup
- [APPLICATIONS.md](APPLICATIONS.md) for complete tool descriptions

---

#### Open WebUI (axios-ai-chat)

Web-based chat interface for local LLMs, available as a PWA desktop app.

**Features:**
- Multi-model chat with Ollama backend
- Conversation history and management
- System prompt customization
- Privacy-preserving (telemetry disabled by default)

**Server Role** (runs the service):
```nix
services.ai.webui = {
  enable = true;
  role = "server";

  # Expose via Tailscale HTTPS
  tailscaleServe = {
    enable = true;
    httpsPort = 8444;
  };

  # Create PWA desktop entry
  pwa = {
    enable = true;
    tailnetDomain = "your-tailnet.ts.net";
  };
};
```

**Client Role** (PWA only, no local service):
```nix
services.ai.webui = {
  enable = true;
  role = "client";
  serverHost = "edge";        # Your server's hostname
  serverPort = 8444;          # Server's HTTPS port
  pwa = {
    enable = true;
    tailnetDomain = "your-tailnet.ts.net";
  };
};
```

**Access:**
- **Local:** `http://localhost:8081` (server role)
- **Tailscale:** `https://[hostname].[tailnet]:8444`
- **PWA:** Launch "Axios AI Chat" from your app launcher

**First-time setup:** The first user to sign up becomes admin. Signup is disabled after the first user for security.

**Port allocations:** Local 8081, Tailscale 8444

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
- API keys for AI services (Brave Search, Tavily)
- Tailscale authentication keys
- SSH keys and certificates
- Database passwords

**See:** [SECRETS_MODULE.md](SECRETS_MODULE.md) for complete setup guide

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
    rebootOnPanic = 30;        # Reboot after 30 seconds
    treatOopsAsPanic = true;   # Aggressive recovery
    enableCrashDump = false;   # Save RAM
  };
};
```

**Trade-offs:**
- ✅ Automatic recovery from freezes
- ✅ System won't stay in broken state
- ❌ No manual debugging time (reboots automatically)

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
- Battery optimization (TLP)
- CPU frequency scaling
- Laptop power management
- Backlight control
- **System76 support** (if `vendor = "system76"`)

---

## Module Dependencies

Some modules require others to work properly:

| Module | Requires | Why |
|--------|----------|-----|
| `desktop` | `networking` | Desktop services need network |
| `gaming` | `graphics` | Games need GPU drivers |
| `ai` | `networking` | AI tools need internet access |

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
