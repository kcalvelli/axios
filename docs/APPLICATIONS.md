# Application Catalog

This document provides a comprehensive list of all applications included in axiOS, organized by category and module.

**Quick Navigation:**
- [Desktop Applications](#desktop-applications)
- [Development Tools](#development-tools)
- [Terminal Applications](#terminal-applications)
- [Gaming (Optional)](#gaming-optional)
- [Virtualization (Optional)](#virtualization-optional)
- [AI Tools (Optional)](#ai-tools-optional)
- [Progressive Web Apps](#progressive-web-apps)

---

## Desktop Applications

**Module:** `desktop` (must be enabled)

**Selection Philosophy:** Applications chosen for functionality and user experience, not desktop environment affiliation. Both GTK and Qt applications receive Material You theming equally via kdeglobals and dank-colors.css integration.

### File Management

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Dolphin** (KDE) | Feature-rich file manager | Superior split-pane functionality and extensive plugin ecosystem |
| **Ark** (KDE) | Archive manager | Excellent Dolphin integration and comprehensive format support |
| **Filelight** (KDE) | Disk usage analyzer | Radial visualization makes disk usage immediately intuitive |

### Productivity

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Obsidian** | Note-taking and knowledge management with markdown support | Best-in-class knowledge base with local-first philosophy |
| **Discord** | Communication platform for voice, video, and text chat | Industry standard for community communication |
| **Ghostwriter** (KDE) | Distraction-free markdown editor | FOSS alternative to Typora with clean Qt interface |
| **LibreOffice** (Qt6 backend) | Full office suite (Writer, Calc, Impress, Draw) | Qt6 backend ensures consistent theming with desktop |
| **Kate** (KDE) | Advanced text editor | Developer-tier features (LSP, minimap, plugins) in a fast editor |
| **1Password** | Password manager and secure digital vault 

### Media Creation & Editing

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Kdenlive** (KDE) | Professional video editor | Industry-standard open-source video editor with stability |
| **Krita** (KDE) | Digital art studio | Professional-grade raster graphics for digital artists |
| **Inkscape** | Professional vector graphics editor | Best open-source vector editor, cross-platform standard |
| **OBS Studio** | Screen recording and live streaming software | Industry standard for streaming and recording |

### Media Viewing & Playback

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **DigiKam** (KDE) | Professional photo manager | Asset management far beyond basic organization |
| **Loupe** (GNOME) | Fast and lightweight image viewer | Superior speed and touchpad gestures, clean UI |
| **Haruna** (KDE) | Video player (MPV frontend) | Excellent MPV frontend with built-in youtube-dl support |
| **Amberol** (GNOME) | Minimalist music player | Focuses purely on music playback with great UI |

### System Utilities

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Okular** (KDE) | PDF and document viewer | Best-in-class annotations and format support |
| **Seahorse** (GNOME) | Password and encryption key manager | Integrates with GNOME Keyring backend for credential management |
| **GNOME Disks** | Disk management and partitioning tool | Cleaner UX for quick ISO writing and benchmarking |
| **Swappy** | Screenshot annotation and editing tool | Fits tiling WM workflow (grim → slurp → edit) |
| **Qalculate!** (Qt) | Advanced calculator with unit conversion | Modern Qt port with better theming than GTK version |
| **CoreCtrl** | Hardware control and monitoring (GPU/CPU) | Essential for GPU overclocking and fan control |
| **KDE Connect** | Sync and control your phone from desktop | Best Linux-phone integration available |
| **LocalSend** | Local network file sharing (AirDrop alternative) | Cross-platform local file sharing without cloud |
| **GNOME Software** | Software center for Flatpak apps | Better Flatpak handling in non-Plasma environments |

### Communication & PIM

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Evolution** | Email client with Exchange/EWS support | Industry standard for Exchange stability, avoids Akonadi |
| **GNOME Calendar** | Calendar application | Simpler and more reliable than Merkuro (no Akonadi backend) |
| **GNOME Contacts** | Contact management | More reliable than KAddressBook (no Akonadi backend) |
| **GNOME Online Accounts** | Unified account management | One-time configuration for Gmail, Outlook, CalDAV, CardDAV |

**Note on KDE-PIM:** KDE's PIM suite (Merkuro, KAddressBook, KMail/Kontact) requires the Akonadi backend which has known reliability issues. Evolution and GNOME PIM apps provide better stability for email, calendar, and contacts.

### Wayland Tools

| Tool | Description | Usage |
|------|-------------|-------|
| **Fuzzel** | Application launcher | Press Super to launch apps |
| **wf-recorder** | Screen recording tool | Mod+Shift+R to record |
| **slurp** | Screen area selection | Used with wf-recorder |
| **playerctl** | Media player control | Control playback from any app |
| **pavucontrol** | PulseAudio volume control | Advanced audio settings |
| **wtype** | Wayland keyboard automation | Simulate keypresses |
| **wayvnc** | VNC server for Wayland | Remote desktop access |

---

## Development Tools

**Module:** `development` (must be enabled)

### Editors & IDEs

| Application | Description | Features |
|-------------|-------------|----------|
| **Visual Studio Code** | Feature-rich code editor | Extensions, IntelliSense, debugging |
| **Vim** | Classic modal text editor | Lightweight, ubiquitous |

### Version Control

| Tool | Description |
|------|-------------|
| **Git** | Distributed version control system |
| **GitHub CLI (gh)** | GitHub operations from terminal |

### Nix Development

| Tool | Description |
|------|-------------|
| **devenv** | Fast, declarative development environments |
| **nil** | Nix language server for IDE integration |
| **direnv** | Automatic environment switching per directory |
| **lorri** | Nix environment builder with caching |

### Build Tools & Compilers

Available in development shells (`nix develop .#<shell>`):

| Shell | Includes |
|-------|----------|
| **rust** | Rust toolchain (rustc, cargo, rust-analyzer) via Fenix |
| **zig** | Zig compiler (latest version) |
| **qml** | Qt6 development with QML tools |

### Utilities

| Tool | Description |
|------|-------------|
| **jq** | JSON processor and query tool |
| **bun** | Fast JavaScript runtime and bundler |

---

## Terminal Applications

**Module:** `desktop` or `development` (included in both)

### Shell & Prompt

| Application | Description |
|-------------|-------------|
| **Fish Shell** | User-friendly shell with autosuggestions |
| **Starship** | Fast, customizable shell prompt |
| **Ghostty** | GPU-accelerated terminal emulator |

### Modern CLI Tools

| Tool | Replaces | Description |
|------|----------|-------------|
| **eza** | ls | Modern ls replacement with icons and git integration |
| **bat** | cat | Syntax-highlighted cat with paging |
| **fd** | find | Fast and user-friendly find alternative |
| **ripgrep** | grep | Fast recursive search tool |
| **fzf** | - | Fuzzy finder for files and commands |
| **zoxide** | cd | Smart directory jumper (learns your habits) |

### Git & GitHub

| Tool | Description |
|------|-------------|
| **Git** | Version control with configured aliases |
| **GitHub CLI** | Manage repositories, issues, and PRs |

---

## Gaming (Optional)

**Module:** `gaming` (must be enabled)

### Gaming Platforms

| Application | Description |
|-------------|-------------|
| **Steam** | Game distribution platform with Proton for Windows games |
| **Proton-GE** | Community-enhanced Proton for better game compatibility |
| **protontricks** | Manage Proton prefixes and Wine settings |

### Gaming Tools

| Tool | Description |
|------|-------------|
| **GameMode** | CPU/GPU optimization for gaming sessions |
| **Gamescope** | Micro-compositor for better game compatibility |
| **MangoHud** | Performance overlay (FPS, CPU, GPU stats) |
| **protonup-ng** | Manage Proton-GE installations |

### Games

| Game | Description |
|------|-------------|
| **SuperTuxKart** | Fun open-source racing game |

---

## Virtualization (Optional)

**Module:** `virt` (must be enabled)

### Virtual Machines

| Application | Description |
|-------------|-------------|
| **libvirt/QEMU** | Full virtualization backend |
| **virt-manager** | GUI for managing virtual machines |
| **virt-viewer** | Lightweight VM display client |

### Containers

| Application | Description |
|-------------|-------------|
| **Podman** | Docker-compatible container runtime (rootless) |
| **Podman Desktop** | GUI for managing containers |

---

## AI Tools (Optional)

**Module:** `ai` (must be enabled)

### Base AI Tools

Included when `services.ai.enable = true`:

**CLI Coding Agents** (3 distinct AI ecosystems):

| Tool | Provider | Description |
|------|----------|-------------|
| **claude-code** | Anthropic | CLI agent with MCP support and deep integration |
| **copilot-cli** | GitHub/OpenAI | CLI agent with GitHub ecosystem integration |
| **gemini-cli** | Google | Multimodal CLI agent with free tier |

**Workflow & Support Tools**:

| Tool | Description |
|------|-------------|
| **spec-kit** | Spec-driven development framework (used by axiOS) |
| **backlog-md** | Project management for human-AI collaboration |
| **claude-monitor** | Real-time AI session resource monitoring |
| **whisper-cpp** | Local speech-to-text transcription |

### Local LLM Stack (Optional)

Included when `services.ai.local.enable = true`:

| Component | Description | Purpose |
|-----------|-------------|---------|
| **Ollama** | Local LLM inference backend | Run models locally with ROCm GPU acceleration |
| **Alpaca** | Native GUI for local models | GTK/libadwaita visual interface |
| **OpenCode** | Agentic CLI for coding tasks | Full file editing with MCP integration |

**Default Models** (Ollama):
- `qwen3-coder:30b` - Primary agentic coding (MoE architecture, ~4GB VRAM)
- `qwen3:14b` - General reasoning (~10GB VRAM)
- `deepseek-coder-v2:16b` - Multilingual coding (~11GB VRAM)
- `qwen3:4b` - Fast completions (~3GB VRAM)

**Features:**
- 32K context window for agentic tool use
- ROCm acceleration for AMD GPUs (automatic override for gfx1031)
- Automatic model preloading on service start
- Optional Caddy reverse proxy for remote HTTPS access
- MCP server support in OpenCode (user-configured)

**Requirements:**
- AMD GPU recommended (8GB+ VRAM for larger models)
- 16GB+ system RAM recommended
- Configure via `services.ai.local.*` options

### MCP Servers

Model Context Protocol servers for enhanced AI context:

**Core Servers:**
- `filesystem` - Access local files and directories
- `git` - Understand repository structure and history
- `github` - Read issues, PRs, and repository data
- `time` - Time zone operations and conversions

**NixOS Integration:**
- `mcp-nixos` - Search NixOS packages and options
- `journal` - Read systemd journal logs
- `nix-devshell-mcp` - Nix development shell integration

**AI Enhancement:**
- `sequential-thinking` - Multi-step reasoning for complex problems
- `context7` - Documentation retrieval for popular libraries

**Search (requires API keys):**
- `brave-search` - Web search via Brave API
- `tavily` - Advanced web search and research

**See:** [SECRETS_MODULE.md](SECRETS_MODULE.md) for configuring API keys

---

## Progressive Web Apps

**Module:** `desktop` (PWA support auto-enabled)

Progressive Web Apps are installed as native applications using Brave browser.

### Default PWAs

Configured via `axios.pwa` in home-manager:

| PWA | URL | Description |
|-----|-----|-------------|
| *(User configurable)* | - | Add your own PWAs in user configuration |

### Adding Custom PWAs

Add to your home-manager configuration:

```nix
axios.pwa.apps = {
  chatgpt = {
    url = "https://chat.openai.com";
    icon = ./icons/chatgpt.png;
  };
  notion = {
    url = "https://www.notion.so";
    icon = ./icons/notion.png;
  };
};
```

PWAs appear in your application launcher like native apps and integrate with desktop notifications.

---

## Theming & Appearance

**Module:** `desktop` (included automatically)

### GTK Themes

| Theme | Type |
|-------|------|
| **Colloid** | GTK theme (light/dark) |
| **Adwaita GTK3** | GNOME 3 theme |

### Icon Themes

| Theme | Description |
|-------|-------------|
| **Colloid Icons** | Modern icon set matching Colloid theme |
| **Papirus Icons** | Popular icon theme with many variants |
| **Adwaita Icons** | GNOME default icon theme |

### Fonts

Provided by DankMaterialShell greeter:
- Noto Sans (system UI)
- Noto Color Emoji (emoji support)
- JetBrains Mono (monospace/terminal)

### Dynamic Theming

Provided by DankMaterialShell:
- **matugen** - Automatic Material Design theme generation from wallpaper
- **hyprpicker** - Color picker tool for theme customization

---

## Services & Background Tools

**Module:** `desktop` (running automatically)

### System Services

| Service | Purpose |
|---------|---------|
| **DankMaterialShell** | Material Design shell and widgets |
| **GNOME Keyring** | Credential storage and SSH key management |
| **accounts-daemon** | User account information service |
| **GVfs** | Virtual filesystem for network shares |
| **udisks2** | Disk management daemon |
| **system76-scheduler** | Process priority optimization |
| **fwupd** | Firmware update service |
| **upower** | Battery and power management |

### Desktop Features (DankMaterialShell)

- System resource monitoring widgets
- Clipboard history with cliphist
- VPN status widget
- Screen and keyboard brightness controls
- Color picker tool
- Audio visualizer (cava)
- Calendar integration (khal)
- System sound effects
- Built-in polkit authentication agent

---

## Application Count Summary

| Category | Count | Module |
|----------|-------|--------|
| Desktop Applications | 30+ | `desktop` |
| Development Tools | 15+ | `development` |
| Terminal Applications | 10+ | `desktop`/`development` |
| Gaming | 8 | `gaming` |
| Virtualization | 4 | `virt` |
| AI Tools (base) | 5 | `ai` |
| AI Tools (local LLM) | 3+ | `ai` (local) |
| System Services | 10+ | `desktop` |

**Total:** 80+ applications and tools across all modules

---

## Finding Applications

### From Terminal
```bash
# Search for installed packages
nix search nixpkgs <app-name>

# List all installed packages
nix-env -q
```

### From Desktop
- Press **Super** to open Fuzzel launcher
- Start typing application name
- Icons show all installed GUI applications

### Application Categories

Applications are organized by:
- **Productivity** - Office, notes, communication
- **Media** - Photo, video, audio editing and playback
- **Development** - Code editors, version control, build tools
- **System** - Utilities, settings, monitoring
- **Gaming** - Games and gaming platforms
- **Network** - Browsers, VPN, file sharing

---

## Adding More Applications

### System-wide Packages

Add to your host configuration:

```nix
extraConfig = {
  environment.systemPackages = with pkgs; [
    firefox
    gimp
    # ... more packages
  ];
};
```

### User Packages

Add to your user module:

```nix
home.packages = with pkgs; [
  telegram-desktop
  spotify
  # ... more packages
];
```

### Finding Packages

Search available packages:
```bash
# Search nixpkgs
nix search nixpkgs <keyword>

# Browse online
# https://search.nixos.org/packages
```

---

## Next Steps

- **Install axiOS**: [INSTALLATION.md](INSTALLATION.md)
- **Module configuration**: [MODULE_REFERENCE.md](MODULE_REFERENCE.md)
- **Customize desktop**: [THEMING.md](THEMING.md)
- **Configure secrets**: [SECRETS_MODULE.md](SECRETS_MODULE.md)

---

**Questions?**

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues or create an issue on [GitHub](https://github.com/kcalvelli/axios/issues).
