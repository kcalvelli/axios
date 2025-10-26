# axiOS Application Catalog

Complete list of applications included in axiOS with descriptions and categories.

## Table of Contents

- [Desktop Applications](#desktop-applications)
- [Progressive Web Apps (PWAs)](#progressive-web-apps-pwas)
- [Development Tools](#development-tools)
- [System Utilities](#system-utilities)
- [Terminal Applications](#terminal-applications)
- [Media Applications](#media-applications)
- [Productivity](#productivity)

---

## Desktop Applications

### Communication

- **Discord** - Voice, video, and text communication platform for communities
- **Element** - Decentralized Matrix protocol messaging client (via PWA)
- **Telegram Web** - Cloud-based instant messaging service (via PWA)
- **Microsoft Teams** - Business communication and collaboration platform (via PWA)

### Note-Taking & Knowledge Management

- **Obsidian** - Markdown-based knowledge base and note-taking application with backlinks and graph view

### Office & Productivity

- **LibreOffice Fresh** - Full-featured office suite (Writer, Calc, Impress, Draw)
- **Typora** - Minimalist Markdown editor with live preview

### File Management

- **Nautilus** - GNOME file manager with extensions support
  - code-nautilus extension for VS Code integration

---

## Progressive Web Apps (PWAs)

All PWAs work immediately without manual browser installation. Icons are bundled and version-controlled.

### Google Services

- **Google Drive** - Cloud storage and file synchronization
- **YouTube** - Video streaming platform
  - Includes quick actions: Subscriptions, Explore
- **Google Messages** - SMS/RCS messaging for web
  - Special niri window rule: floats at 500x700 size
- **Google Meet** - Video conferencing and meetings
- **Google Chat** - Team messaging and collaboration
- **Google Maps** - Navigation and mapping service
- **Google Photos** - Photo storage and management

### Proton Services

Privacy-focused alternatives to mainstream services:

- **Proton Pass** - Encrypted password manager
- **Proton Mail** - Encrypted email service
  - Registered as mailto: handler
- **Proton Drive** - Encrypted cloud storage
- **Proton Calendar** - Encrypted calendar
  - Registered handler for .ics files and webcal: links
- **Proton Wallet** - Cryptocurrency wallet

### Microsoft Services

- **Outlook (PWA)** - Email and calendar client
  - Quick actions: New Event, New Message, Open Calendar
  - Registered as mailto: handler
- **Windows App** - Remote Desktop client for Azure/RDP connections

### Other Web Apps

- **Sonos** - Multi-room audio controller

---

## Development Tools

### Editors & IDEs

- **VS Code** - Extensible code editor with extensive language support
- **Vim** - Classic modal text editor
- **Neovim** - Modern Vim fork with LazyVim configuration

### Version Control

- **Git** - Distributed version control system
- **GitHub CLI (gh)** - GitHub command-line interface

### Languages & Runtimes

Development environments available via `nix develop`:

- **Rust** - Systems programming language (via Fenix toolchain)
- **Zig** - General-purpose systems language
- **Python** - General-purpose scripting language
- **Node.js** - JavaScript runtime
- **Qt6/QML** - Cross-platform UI framework

### Build Tools & Package Managers

- **Nix** - Declarative package manager and build system
- **direnv** - Environment switcher for the shell
- **devenv** - Fast, declarative development environments
- **lorri** - nix-shell replacement for project-specific environments

### Language Servers & Tools

- **nil** - Nix language server for IDE support

### AI Tools

- **whisper-cpp** - Speech recognition model
- **Copilot CLI** - AI-powered command-line assistant (from nix-ai-tools)

---

## System Utilities

### Core System Tools

- **curl** - Command-line tool for transferring data with URLs
- **wget** - Network downloader
- **killall** - Kill processes by name

### Filesystem Tools

- **sshfs** - Mount remote filesystems over SSH
- **fuse** - Filesystem in userspace
- **ntfs3g** - NTFS filesystem driver with read/write support

### System Monitoring

- **htop** - Interactive process viewer
- **gtop** - System monitoring dashboard in the terminal
- **pciutils** - PCI device information utilities
- **wirelesstools** - Wireless network configuration tools
- **lm_sensors** - Hardware monitoring sensors
- **smartmontools** - Hard drive health monitoring (SMART)

### Archive & Compression

- **p7zip** - 7-Zip file archiver
- **unzip** - ZIP archive extractor
- **unrar** - RAR archive extractor
- **xarchiver** - Lightweight desktop archive manager

### Security

- **libsecret** - Library for storing and retrieving passwords
- **lssecret** - List secret tool
- **openssl** - Cryptography toolkit

### Nix Ecosystem

- **fh** - Flake helper CLI for easier flake management

---

## Terminal Applications

### Shell & Prompt

- **Fish** - Friendly interactive shell with autosuggestions
- **Starship** - Fast, customizable shell prompt
- **Ghostty** - Modern GPU-accelerated terminal emulator
  - Supports drop-down mode (quake-style)

### Terminal Utilities

- **bat** - Cat clone with syntax highlighting and Git integration
- **eza** - Modern ls replacement with color and Git support
- **jq** - JSON processor for command-line
- **fzf** - Fuzzy finder for files and command history

### File Transfer

- **rsync** - Incremental file transfer and synchronization

---

## Media Applications

### Photo Management

- **Shotwell** - Photo organizer and viewer
- **Loupe** - Simple image viewer

### Video

- **Celluloid** - Modern GTK frontend for MPV media player
- **Pitivi** - Video editor for Linux

### Audio

- **Amberol** - Simple music player
- **Cava** - Console-based audio visualizer
- **playerctl** - Command-line media player controller
- **pavucontrol** - PulseAudio volume control

### Graphics & Design

- **Pinta** - Simple image editor
- **Inkscape** - Professional vector graphics editor

---

## Productivity

### Browsers

- **Brave** - Privacy-focused web browser with ad blocking
  - Configured with extensions:
    - ProtonPass password manager
    - Google Docs Offline
    - Brave Talk for Calendars

### Cloud & Sync

- **Nextcloud Client** - File synchronization with Nextcloud servers

### System Tools

- **Baobab** - Disk usage analyzer (GNOME Disks)
- **GNOME Software** - Application browser and updater
- **GNOME Text Editor** - Simple text editor
- **qalculate-gtk** - Advanced calculator

### Screenshot & Screen Tools

- **grimblast** - Screenshot tool for wlroots compositors
- **grim** - Screenshot utility for Wayland
- **slurp** - Region selection tool for Wayland
- **swappy** - Wayland screenshot annotation tool
- **hyprpicker** - Color picker for Wayland

### Wayland Tools

- **fuzzel** - Application launcher for Wayland
- **wl-clipboard** - Command-line clipboard manager for Wayland
- **wtype** - Xdotool type for Wayland
- **swaybg** - Wallpaper setter for Wayland

---

## Gaming (Optional Module)

When `gaming` module is enabled:

- **Steam** - Digital distribution platform for games
  - Includes Proton for Windows game compatibility
  - Proton-GE enabled for enhanced compatibility
- **GameMode** - System optimizer for gaming performance
- **Gamescope** - SteamOS session compositing window manager
- **mangohud** - Vulkan and OpenGL overlay for monitoring FPS and performance
- **SuperTuxKart** - Open-source kart racing game
- **protonup-ng** - Proton-GE installer and manager (user-level)

---

## Virtualization (Optional Module)

When `virt` module is enabled:

### Containers

- **Podman** - Daemonless container engine (Docker-compatible)

### Virtual Machines

- **virt-manager** - Desktop application for managing VMs
- **virt-viewer** - Viewer for virtualized guest displays
- **QEMU** - Generic machine emulator and virtualizer
- **quickemu** - Quickly create and manage optimized VMs
- **quickgui** - GUI for quickemu

---

## Graphics Tools (GPU Module)

When `graphics` module is enabled:

### AMD GPU Tools

- **radeontop** - GPU utilization monitor for AMD cards
- **CoreCtrl** - System performance control utility
- **amdgpu_top** - Tool to display AMD GPU utilization
- **clinfo** - OpenCL information utility

### Wayland Utilities

- **wayland-utils** - Wayland utilities for debugging

---

## Theming & Appearance

### Icon Themes

- **Colloid Icon Theme** - Colorful icon theme
- **Adwaita Icon Theme** - GNOME default icon theme
- **Papirus Icon Theme** - Popular SVG icon theme

### GTK Themes

- **Colloid GTK Theme** - Modern GTK theme
- **adw-gtk3** - LibAdwaita theme for GTK3

### Material Design

- **matugen** - Material Design color scheme generator

### Fonts

- **Fira Code Nerd Font** - Monospace font with programming ligatures and icons
- **Inter** - Modern sans-serif font family
- **Material Symbols** - Material Design icon font

### Qt

- **qt6ct** - Qt6 configuration tool for non-KDE desktops

---

## Desktop Environment

### Compositor

- **Niri** - Scrollable-tiling Wayland compositor
  - Custom keybindings and window rules
  - Drop-down terminal support
  - Overview mode with workspace management

### Shell

- **DankMaterialShell** - Material Design shell for Niri
  - Quickshell-based panel and widgets
  - Material theming integration
  - Wallpaper blur effects

### Desktop Services

- **mate-polkit** - PolicyKit authentication agent
- **wayvnc** - VNC server for Wayland
- **xwayland-satellite** - Xwayland outside your Wayland compositor
- **brightnessctl** - Screen brightness control

---

## Network Services (Optional)

When `services` module is enabled, additional services are available:

- **Caddy** - Web server with automatic HTTPS
- **Home Assistant** - Home automation platform
- **MQTT** - Message broker for IoT
- **ntopng** - Network traffic monitoring
- **OpenWebUI** - Web interface for LLMs

---

## Notes

### Installation

Applications are automatically installed based on your module selection and home profile (workstation/laptop).

### PWA Limitations

PWAs require Brave browser and work via `--app=URL` mode. They function as standalone applications but require an internet connection.

### Optional Modules

Gaming, virtualization, and services modules are opt-in via the `modules` configuration in your flake.

### Updates

All applications are managed through Nix and updated when you run `nix flake update` and rebuild your system.
