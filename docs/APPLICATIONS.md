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

### Browsers

| Browser | Description | Role |
|---------|-------------|------|
| **Brave** | Chromium-based browser with built-in ad blocking | Default browser, Brave Nightly for development |
| **Chromium** | Open-source browser engine | PWA backend (default engine for `axios.pwa` apps) |
| **Google Chrome** | Google's Chromium variant | Compatibility testing, alternative PWA engine |

> **Note:** Browser GPU acceleration flags are computed automatically based on `axios.hardware.gpuType` and exposed via `desktop.browserArgs` for consistent hardware acceleration across all browsers and PWAs.

### File Management

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Dolphin** (KDE) | Feature-rich file manager | Superior split-pane functionality and extensive plugin ecosystem |
| **Ark** (KDE) | Archive manager | Excellent Dolphin integration and comprehensive format support |
| **Filelight** (KDE) | Disk usage analyzer | Radial visualization makes disk usage immediately intuitive |

### Productivity

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Discord** | Communication platform for voice, video, and text chat | Industry standard for community communication |
| **Materialgram** | Fast, secure messaging client | Native Qt app with encryption and cloud sync and material design - fork of Telegram Desktop |
| **Spotify** | Music streaming service | Large library, good playlists, native Linux client |
| **Ghostwriter** (KDE) | Distraction-free markdown editor | FOSS alternative to Typora with clean Qt interface |
| **LibreOffice** (Qt) | Full office suite (Writer, Calc, Impress, Draw) | Qt integration for Material You theming consistency |
| **Mousepad** (Xfce) | Simple text editor | Lightweight with syntax highlighting, no CSD |
| **1Password** | Password manager and secure digital vault |

### Media Creation & Editing

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Krita** (KDE) | Digital art studio | Professional-grade raster graphics for digital artists |
| **OBS Studio** | Screen recording and live streaming software | Industry standard for streaming and recording |

### Media Viewing & Playback

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **Gwenview** (KDE) | Full-featured image viewer | SSD-compatible, thumbnail browsing, KDE integration |
| **mpv** + **uosc** | Unified audio/video player | FFmpeg decoding, PipeWire audio, hardware acceleration, modern UI |
| **Tauon** | Music library player | SDL/FFmpeg backend, excellent FLAC support, no GStreamer |

**mpv Features:**
- **uosc**: Modern on-screen controller with menus, chapters, and streaming titles
- **thumbfast**: Thumbnail previews on the seek bar
- **mpris**: D-Bus integration for media keys and playerctl
- **Hardware acceleration**: VA-API, NVDEC, VDPAU auto-detected
- **Keyboard-driven**: Full control without mouse (Tab to show UI, right-click for menu)

> **Note:** mpv replaces separate audio (Elisa) and video (Haruna) players. It uses FFmpeg directly for decoding and PipeWire for audio output, avoiding GStreamer entirely. This eliminates boot-time race conditions and provides a lighter, more reliable multimedia stack.
>
> **Need Elisa or Haruna?** Add them to your `extraConfig.environment.systemPackages`. You'll also need to configure GStreamer manually—see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#gstreamer-configuration) for details.

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
| **Flatpak Handler** | One-click Flatpak installation from Flathub | Terminal-based transparent install flow |

### Communication & PIM

**Optional Module:** Enable with `modules.pim = true` in your host configuration.

| Application | Description | Why This App? |
|-------------|-------------|---------------|
| **axios-ai-mail** | AI-powered email client | Local LLM email classification and smart inbox |
| **vdirsyncer** | Calendar/contact sync tool | CLI tool for syncing multiple calendar and contact sources |
| **mcp-dav** | Calendar/contacts MCP server | CalDAV/CardDAV integration via axios-dav |

**Server Role (runs axios-ai-mail service):**
```nix
modules.pim = true;
# In extraConfig:
services.pim = {
  user = "your-username";
  pwa.enable = true;
  pwa.tailnetDomain = "your-tailnet.ts.net";
};
```

**Client Role (PWA only, connects to server):**
```nix
modules.pim = true;
# In extraConfig:
services.pim = {
  role = "client";
  pwa.enable = true;
  pwa.tailnetDomain = "your-tailnet.ts.net";
};
```

See [TAILSCALE_SERVICES.md](TAILSCALE_SERVICES.md) for Tailscale configuration.

### Wayland Tools

| Tool | Description | Usage |
|------|-------------|-------|
| **Fuzzel** | Application launcher | Press Super to launch apps |
| **wf-recorder** | Screen recording tool | Mod+Shift+R to record |
| **slurp** | Screen area selection | Used with wf-recorder |
| **playerctl** | Media player control | Control playback from any app |
| **pavucontrol** | PulseAudio volume control | Advanced audio settings |
| **wtype** | Wayland keyboard automation | Simulate keypresses |

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

> **Note:** `nixd` is an alternative Nix LSP with more features than `nil` (evaluation support, option completions). A future change may swap to `nixd` after testing.

### Build Tools & Compilers

Available in development shells (`nix develop .#<shell>`):

| Shell | Includes |
|-------|----------|
| **rust** | Rust toolchain (rustc, cargo, rust-analyzer) via Fenix |
| **zig** | Zig compiler (latest version) |
| **qml** | Qt6 development with QML tools |

### Database Clients

| Tool | Description |
|------|-------------|
| **pgcli** | PostgreSQL CLI with auto-completion and syntax highlighting |
| **litecli** | SQLite CLI (same UX as pgcli) |

### API Testing

| Tool | Description |
|------|-------------|
| **httpie** | Modern HTTP client with syntax-highlighted responses |
| **mitmproxy** | Interactive HTTPS proxy for API debugging |
| **k6** | Load testing tool |

### Diff & Diagnostics

| Tool | Description |
|------|-------------|
| **difftastic** | Structural diff tool (AST-aware, language-specific) |
| **btop** | Terminal system monitor (CPU, memory, disk, network) |
| **mtr** | Network diagnostic tool (traceroute + ping combined) |
| **dog** | Modern DNS client (alternative to dig) |

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

**CLI Coding Agents** (4 agents across 3 AI ecosystems):

| Tool | Provider | Description |
|------|----------|-------------|
| **claude-code** | Anthropic | CLI agent with MCP support and deep integration |
| **claude-desktop** | Anthropic | Claude desktop application |
| **claude-code-acp** | Anthropic | Claude Code Agent Communication Protocol |
| **claude-code-router** | Anthropic | Claude Code request router |
| **gemini** | Google | Multimodal CLI agent with free tier |
| **antigravity** | Google | Advanced agentic assistant for axiOS development |

**Workflow & Support Tools**:

| Tool | Description |
|------|-------------|
| **openspec** | OpenSpec SDD workflow CLI for spec-driven development |
| **spec-kit** | Spec-driven development framework (used by axiOS) |
| **claude-monitor** | Real-time AI session resource monitoring |
| **whisper-cpp** | Local speech-to-text transcription |

### Local LLM Stack (Optional)

Included when `services.ai.local.enable = true`:

| Component | Description | Purpose |
|-----------|-------------|---------|
| **Ollama** | Local LLM inference backend | Run models locally with ROCm GPU acceleration |
| **OpenCode** | Agentic CLI for coding tasks | Full file editing with MCP integration |

**Default Models** (Ollama):
- `mistral:7b` - General purpose, excellent quality/size ratio (~4.4GB)
- `nomic-embed-text` - Embeddings for RAG/semantic search (~274MB)

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
- `journal` - Read systemd journal logs
- `nix-devshell-mcp` - Nix development shell integration

**PIM Integration:**
- `axios-ai-mail` - AI-powered email access and management
- `mcp-dav` - Calendar and contacts via CalDAV/CardDAV

**AI Enhancement:**
- `sequential-thinking` - Multi-step reasoning for complex problems
- `context7` - Documentation retrieval for popular libraries

**Search (requires API keys):**
- `brave-search` - Web search via Brave API

**See:** [SECRETS_MODULE.md](SECRETS_MODULE.md) for configuring API keys

---

## Progressive Web Apps

**Module:** `desktop` (PWA support auto-enabled)

Progressive Web Apps are installed as native applications using Brave browser.

### Default PWAs

axiOS ships 30+ default PWAs (enabled via `axios.pwa.includeDefaults = true`, the default). Key defaults include:

| Category | PWAs |
|----------|------|
| **Google Workspace** | Gmail, Drive, Docs, Sheets, Slides, Calendar, Contacts, Keep, Forms, Classroom |
| **Communication** | Google Chat, Google Meet, Google Messages, Google Voice, Element |
| **Media** | YouTube, YouTube Music, Sonos |
| **AI & Productivity** | Gemini, Google AI Studio, NotebookLM, Notion, Linear |
| **Development** | Hoppscotch (API testing) |
| **Design** | Figma, Excalidraw |
| **Microsoft** | Outlook, Microsoft Teams |
| **Other** | Google Maps, Google Photos, Google News, Google Search, Flathub |

See `pkgs/pwa-apps/pwa-defs.nix` for the complete list.

### Adding Custom PWAs

Add to your home-manager configuration:

```nix
axios.pwa = {
  enable = true;
  apps = {
    chatgpt = {
      name = "ChatGPT";
      url = "https://chat.openai.com";
      icon = "chatgpt";
      categories = [ "Utility" ];
    };
  };
  iconPath = ./pwa-icons; # Directory containing chatgpt.png
};
```

PWAs appear in your application launcher like native apps and integrate with desktop notifications. Each PWA gets a `pwa-{appId}` launcher script on `$PATH`.

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
| **Tailscale** | Mesh VPN for cross-device access (PIM, Ollama, MCP Gateway) |
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
| Browsers | 3 | `desktop` |
| Desktop Applications | 30+ | `desktop` |
| Development Tools | 25+ | `development` |
| Terminal Applications | 10+ | `desktop`/`development` |
| Gaming | 8 | `gaming` |
| Virtualization | 4 | `virt` |
| AI Tools (base) | 10+ | `ai` |
| AI Tools (local LLM) | 3+ | `ai` (local) |
| PWAs (default) | 30+ | `desktop` (home-manager) |
| System Services | 10+ | `desktop` |

**Total:** 130+ applications, tools, and PWAs across all modules

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
  obsidian
  signal-desktop
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
