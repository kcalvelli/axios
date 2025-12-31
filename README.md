# axiOS

<p align="center">
<img src="docs/logo.png" alt="axiOS Logo" width="400">
</p>

<p align="center">
<em>A modular <a href="https://nixos.org">NixOS</a> framework and library for building reproducible systems with <a href="https://github.com/nix-community/home-manager">Home Manager</a>, modern desktop environments, and curated development tools.</em>
</p>

<p align="center">
<img src="docs/screenshots/hero-vscode-maximized.png" alt="axiOS Focused Workspace">
</p>

<p align="center">
<em>Maximized windows, no borders, no distractions — designed for focused work</em>
</p>

## What is axiOS?

axiOS is a **NixOS framework and library** that you import into your own flake to build NixOS configurations. Think of it as a curated collection of modules, packages, and home-manager configs that work together.

You maintain just a few simple files (~30 lines), and axios provides everything else: desktop environment, development tools, system configuration, and more.

## Quick Start

**Prerequisites:** NixOS installed in UEFI mode (BIOS/MBR not supported)

### Use the Interactive Generator (Recommended) ⭐

```bash
mkdir ~/my-nixos-config && cd ~/my-nixos-config
nix run --refresh --extra-experimental-features "nix-command flakes" github:kcalvelli/axios#init
```

> **Note:** The `--refresh` flag ensures you get the latest version. Without it, Nix may use a cached version.

The generator creates a complete configuration tailored to your system in minutes.

### Manual Configuration

For manual setup, you'll create just 3 files:
- `flake.nix` - Import axios and configure your system (~30 lines)
- `user.nix` - Your user account settings (~15 lines)
- `hardware.nix` - Hardware configuration from nixos-generate-config

**See [docs/INSTALLATION.md](docs/INSTALLATION.md) for complete step-by-step instructions.**

## Features

### Desktop Experience
- **[Niri compositor](https://github.com/YaLTeR/niri)** - Scrollable tiling Wayland compositor with workspace overview
- **DankMaterialShell** - Material design shell with:
  - System monitoring widgets (CPU, RAM, disk usage)
  - Clipboard history management (cliphist)
  - VPN status widget
  - Brightness controls (screen & keyboard)
  - Color picker and dynamic theming (matugen)
  - Audio visualizer (cava)
  - Calendar integration (khal)
  - Built-in polkit agent
- **Idle management** - Automatic screen power-off after 30 minutes (configurable)
- **Curated wallpaper collection** - 18 high-quality wallpapers auto-deployed to `~/Pictures/Wallpapers`
  - Automatic updates when collection changes
  - Random wallpaper selection on first run and collection updates
  - Enable in your `user.nix`: add `axios.wallpapers.enable = true;` under `home-manager.users.${username}`
  - Optional: Set `axios.wallpapers.autoUpdate = false;` to disable auto-randomization
- **Wallpaper blur effects** - Automatic blur for overview mode
- **Ghostty terminal** - Modern GPU-accelerated terminal with dropdown mode
- **GPU Hardware Acceleration** - Automatic browser acceleration based on GPU type:
  - AMD: VA-API video decode/encode with modern Chrome 131+ flags
  - NVIDIA: VA-API via nvidia-vaapi-driver with optimized environment variables
  - Accelerates: Video playback, WebGL, Canvas rendering, GPU rasterization
  - Works automatically in Brave and Brave Nightly (no manual configuration)
- **Google Drive sync** - Automatic rclone-based sync with safety features (run `setup-gdrive-sync`)

### Development
- **Multi-language environments** - Rust, Zig, Python, Node.js
- **DevShells** - Project-specific toolchains via `nix develop`
- **LSP support** - Language servers pre-configured
- **Development tools** - Organized by category

### Infrastructure
- **Declarative disks** - Disko templates for automated provisioning
- **Secure boot** - Lanzaboote support
- **Virtualization** - libvirt, QEMU, Podman
- **Hardware optimization** - Automatic desktop/laptop configuration
- **Modular architecture** - Enable only what you need
- **Self-hosted services** - Caddy + Tailscale HTTPS, Immich photo backup

## Screenshots

### Workspace Overview with Blur Effect
![Workspace Overview](docs/screenshots/workspace-overview.png)
*Niri's scrollable workspace view showing multiple contexts (VS Code, Dolphin, terminals) with automatic wallpaper blur and built-in keybinding reference*

### Dropdown Terminal (Super+`)
![Dropdown Terminal](docs/screenshots/dropdown-terminal.png)
*Instant terminal overlay (97% width, 420px tall) for quick commands during focused work — nix build running over VS Code*

### Strategic Floating Windows
![Floating Utilities](docs/screenshots/floating-utilities.png)
*Supporting tools that don't disrupt focus: Qalculate calculator (floating), Dolphin file manager, and split-screen tiling with Brave browser and VS Code*

### DMS Material Design Shell
![DMS Settings and Monitor](docs/screenshots/dms-settings-monitor.png)
*DankMaterialShell with system monitor, settings panel, and Material Design widgets — showing user profile, network status, and performance graphs*

## Documentation

**📖 [Complete Documentation Hub](docs/README.md)** - Start here for comprehensive guides

**Quick Links:**
- [Installation Guide](docs/INSTALLATION.md) - Step-by-step setup
- [Application Catalog](docs/APPLICATIONS.md) - See what's included
- [Library API Reference](docs/LIBRARY_USAGE.md) - Using `axios.lib.mkSystem`
- [Adding Multiple Hosts](docs/ADDING_HOSTS.md) - Multi-host setups

## Library API

axiOS exports `axios.lib.mkSystem` for building NixOS configurations with minimal code:

```nix
nixosConfigurations.myhost = axios.lib.mkSystem {
hostname = "myhost";
formFactor = "desktop";  # or "laptop"
hardware = { cpu = "amd"; gpu = "amd"; };
modules = { desktop = true; development = true; };
userModulePath = ./user.nix;
hardwareConfigPath = ./hardware.nix;
};
```

**See [docs/LIBRARY_USAGE.md](docs/LIBRARY_USAGE.md) for complete API documentation and all available options.**

## Examples

Check out these example configurations:

- [examples/minimal-flake](examples/minimal-flake/) - Minimal single-host configuration
- [examples/multi-host](examples/multi-host/) - Multiple hosts with shared config

## What's Included

- **Desktop**: Niri compositor with scrollable tiling, DankMaterialShell with widgets, Ghostty terminal, GPU-accelerated browsers (AMD/NVIDIA), idle management, Google Drive sync
- **Development**: Rust, Zig, Python, Node.js toolchains with LSP support
- **Applications**: 80+ apps including productivity, media, and utilities - see [Application Catalog](docs/APPLICATIONS.md)
- **PWAs**: Progressive Web Apps integrated as native applications
- **Virtualization**: libvirt, QEMU, Podman support (optional)
- **Gaming**: Steam, GameMode, Proton (optional)
- **AI Services** (optional):
  - Cloud AI: 5 CLI coding agents (claude-code family, copilot-cli, gemini-cli) + workflow tools
  - Local LLM: Ollama + OpenCode with ROCm acceleration
  - 32K context window for agentic coding
  - Full MCP server integration
- **Self-Hosted Services**: Caddy reverse proxy with Tailscale HTTPS, Immich photo backup (optional)

**See project structure and module details in [docs/README.md](docs/README.md)**

## Installing Additional Applications

### For Most Users: Use Flathub (Recommended) 📦

axiOS includes **GNOME Software** with **Flathub** pre-configured as the primary way to install additional applications. This is the **recommended approach for most users**:

**Why Flathub?**
- ✅ **Sandboxed applications** - Better security isolation
- ✅ **Latest versions** - Apps update independently of NixOS
- ✅ **Graphical interface** - Browse and install via GNOME Software
- ✅ **Large ecosystem** - Thousands of desktop applications
- ✅ **Theme integration** - Apps automatically use your GTK theme
- ✅ **No system rebuilds** - Install/remove apps instantly

**To install apps:**
1. Open **GNOME Software** from your applications
2. Browse or search for applications
3. Click "Install" - that's it!

Popular apps available on Flathub:
- **Browsers**: Firefox, Chrome, Edge, Opera
- **Communication**: Slack, Discord, Telegram, Signal
- **Media**: Spotify, VLC, Audacity, GIMP, Kdenlive
- **Productivity**: LibreOffice, OnlyOffice, Thunderbird
- **Development**: Postman, MongoDB Compass, Beekeeper Studio
- **And thousands more...**

### For Technical Users: Declarative NixOS Packages

If you prefer declarative configuration, add packages to your `extraConfig` in your host configuration:

```nix
extraConfig = {
  environment.systemPackages = with pkgs; [
    firefox
    slack
    # your packages here
  ];
};
```

**When to use NixOS packages instead of Flathub:**
- You need packages for system services (not desktop apps)
- You want reproducible builds across multiple machines
- You need packages that integrate deeply with the system
- You're building a custom configuration to share

**Note**: Most desktop applications work better as Flatpaks due to sandboxing and independent updates. Reserve NixOS packages for system-level tools, command-line utilities, and development environments.

## Why axiOS?

- ✅ **Minimal maintenance** - Your config is ~30 lines, axios handles the rest
- ✅ **Selective updates** - `nix flake update` to get new features when you want
- ✅ **Version pinning** - Lock to specific axios versions for stability
- ✅ **Clear separation** - Your personal configs vs framework code
- ✅ **Easy sharing** - Your config repo is simple and understandable
- ✅ **Community framework** - Benefit from improvements and updates
- ✅ **Library design** - Not a personal config - no hardcoded regional defaults

### Workflow Philosophy

axiOS is built around a **focused, distraction-free workflow** optimized for single-monitor productivity:

**Maximized Windows by Default**
- All applications open maximized to keep your attention on the task at hand
- Web browsers, code editors, terminals, and productivity apps fill the screen
- Reduces context switching and visual clutter
- Window borders are disabled for a seamless, immersive experience

**Strategic Floating Windows**
- **Utility apps** that support your work open floating:
  - Qalculate (quick calculations during work)
  - Dolphin file manager (1200×900, for quick file operations)
  - Google Messages PWA (500×700, pinned top-left for quick replies)
  - DankMaterialShell settings (configuration without disruption)
  - Brave Picture-in-Picture (for background media)
- These apps are intentionally kept small and out-of-the-way

**Dropdown Terminal (Super+`)**
- Instant access to a terminal overlay (97% screen width, 420px tall)
- Perfect for quick commands while working:
  - Git operations during code review
  - Running builds without leaving your editor
  - System checks and monitoring
  - Command-line tools during development
- Press Super+` again to dismiss and return to focused work

**Scrolling Workspace Navigation**
- Niri's scrollable tiling compositor lets you organize work by project or context
- Each workspace holds maximized windows for different projects
- Scroll through workspaces (Mod+Wheel) to switch between contexts seamlessly
- Each context remains focused and distraction-free when you return to it

**Single-Monitor Optimized**
- The entire workflow is designed and tested for single-monitor setups
- Multi-monitor configurations are not tested and may not work as expected
- This deliberate constraint encourages focused work over sprawling layouts

This workflow prioritizes **deep work over multitasking**, with every design decision aimed at keeping you focused on one task at a time while maintaining quick access to supporting tools.

### Library Philosophy

axiOS is designed as a **framework/library**, not a personal configuration:

- **No regional defaults** - You must explicitly set timezone and locale (no assumptions about your location)
- **No hardcoded preferences** - Personal choices belong in your config, not the framework
- **Modular by design** - Enable only what you need, customize everything
- **Multi-user ready** - Built for diverse users with different needs

This means some options are **required** (like `axios.system.timeZone`) to force explicit configuration rather than assuming defaults that might not fit your use case.

## Contributing

Contributions welcome! This is a public framework meant to be used by others.

- Report issues for bugs or missing features
- Submit PRs for improvements
- Share your configurations using axios
- Improve documentation

## Acknowledgments

Built with and inspired by:
- [NixOS](https://nixos.org) and the nix-community
- [Home Manager](https://github.com/nix-community/home-manager)
- [Niri](https://github.com/YaLTeR/niri) compositor
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- Countless community configurations and blog posts

## License

MIT License. See [LICENSE](LICENSE) for details.
