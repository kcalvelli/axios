# axiOS Documentation

Welcome to the axiOS documentation. This guide will help you install, configure, and maintain your NixOS system.

## Documentation Overview

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [INSTALLATION.md](INSTALLATION.md) | Install axiOS on your machine | **Start here** for new installations |
| [UPGRADE.md](UPGRADE.md) | Update axios to latest version | When updating axios input |
| [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) | Breaking changes between versions | Before major version updates |
| [APPLICATIONS.md](APPLICATIONS.md) | Complete application catalog | **See what's included** in axiOS |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick command reference | Quick lookups and common tasks |
| [PACKAGES.md](PACKAGES.md) | Package organization guide | Before adding new packages |
| [ADDING_HOSTS.md](ADDING_HOSTS.md) | Multi-machine management | Managing multiple systems |
| [LIBRARY_USAGE.md](LIBRARY_USAGE.md) | Using axios as a library | Using axios in your own flake |
| [NIRI_WALLPAPER.md](NIRI_WALLPAPER.md) | Desktop customization | Customizing Niri compositor |

## Quick Start

### New Users

The fastest way to get started with axiOS:

```bash
# Create a directory and run the interactive generator
mkdir ~/my-nixos-config && cd ~/my-nixos-config
nix run --extra-experimental-features "nix-command flakes" github:kcalvelli/axios#init
```

The generator will:
- Ask you about your system (hostname, hardware, preferences)
- Generate a complete configuration tailored to your needs
- Provide clear next-steps instructions

Or follow the manual installation guide:

1. **Read installation guide**: [INSTALLATION.md](INSTALLATION.md) for detailed instructions
2. **Generate config**: Use `axios init` or copy the minimal example
3. **Customize**: Edit generated files for your hardware
4. **Install**: Boot from installer and run nixos-install

### Existing Users

- **Update system**: `cd ~/my-nixos-config && nix flake update && sudo nixos-rebuild switch --flake .#HOSTNAME`
- **Add packages**: See [PACKAGES.md](PACKAGES.md) for organization guidelines
- **Add new machine**: See [ADDING_HOSTS.md](ADDING_HOSTS.md)
- **Quick reference**: See [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

## Installation & Setup

### 📦 [INSTALLATION.md](INSTALLATION.md)
**Complete installation guide from start to finish**

Topics covered:
- Downloading and preparing the installer ISO
- Creating bootable installation media
- Installing to VMs (VMware, VirtualBox, QEMU, etc.)
- Installing to bare metal
- Automated vs manual installation
- Post-installation setup and configuration
- Troubleshooting common issues

**Start here if you're installing axiOS for the first time.**

### 🔨 [BUILDING_ISO.md](BUILDING_ISO.md)
**Build and customize the axiOS installer ISO**

Topics covered:
- Building the ISO from source
- Customizing packages and branding
- Testing in VMs and QEMU
- CI/CD integration for automated builds
- Creating custom variations

**For developers who want to build or customize the installer.**

### ⚡ [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
**Fast command reference for common operations**

Quick access to:
- ISO build and testing commands
- VM testing procedures
- Installer customization
- Common troubleshooting fixes
- Frequently used operations

**For quick lookups without reading full documentation.**

## Configuration & Maintenance

### 📱 [APPLICATIONS.md](APPLICATIONS.md)
**Complete catalog of included applications**

Comprehensive list of:
- Desktop applications and productivity tools
- Progressive Web Apps (PWAs) with descriptions
- Development tools and environments
- System utilities and monitoring tools
- Terminal applications
- Media applications (photo, video, audio)
- Gaming support (when enabled)
- Virtualization tools (when enabled)

**Browse this to see everything axiOS includes out of the box.**

### 📚 [PACKAGES.md](PACKAGES.md)
**Package organization philosophy and best practices**

Learn about:
- System vs Home Manager package placement
- Module organization structure
- Decision trees for adding packages
- Inline package organization
- Best practices for package management

**Read this before adding new packages to understand where they belong.**

### 🖥️ [ADDING_HOSTS.md](ADDING_HOSTS.md)
**Managing multiple machines with axiOS**

Covers:
- Adding new hosts to your configuration
- Host configuration structure
- Hardware-specific settings
- Template usage and examples
- Multi-machine best practices

**For users managing axiOS across multiple machines.**

### 🎨 [NIRI_WALLPAPER.md](NIRI_WALLPAPER.md)
**Desktop customization with Niri compositor**

Includes:
- Wallpaper blur effects for overview mode
- DankMaterialShell integration
- Automatic wallpaper script setup
- Troubleshooting desktop issues

**For desktop users wanting to customize their Niri experience.**

## Common Tasks

### Updating Your System

```bash
# Navigate to your config repository
cd ~/my-nixos-config

# Update axios specifically (recommended)
nix flake lock --update-input axios

# Or update all inputs
nix flake update

# Rebuild and switch to new configuration
sudo nixos-rebuild switch --flake .#HOSTNAME

# Optionally, clean up old generations
sudo nix-collect-garbage -d
```

**See [UPGRADE.md](UPGRADE.md) for detailed upgrade instructions and troubleshooting.**

### Adding a New Package

1. Determine if it's a system or user package (see [PACKAGES.md](PACKAGES.md))
2. Add to `extraConfig` in your flake.nix or user.nix
3. Rebuild: `sudo nixos-rebuild switch --flake .#HOSTNAME`

### Adding a New Machine

1. Create a new host configuration in your flake.nix
2. Create corresponding disk config
3. See [ADDING_HOSTS.md](ADDING_HOSTS.md) for details

### Customizing Desktop

- Edit Niri config: `home/niri.nix` in your axios fork or via extraConfig
- Set wallpaper with blur: `~/scripts/wallpaper-changed.sh "onWallpaperChanged" /path/to/image.jpg`
- See [NIRI_WALLPAPER.md](NIRI_WALLPAPER.md) for desktop customization

## Screenshots

Visual examples of the axiOS desktop:

- **Niri Overview**: `screenshots/overview.png` - Workspace overview mode
- **Dropdown Terminal**: `screenshots/dropdown.png` - Ghostty terminal
- **File Manager**: `screenshots/nautilus.png` - Themed file browser

## Repository Structure

```
axios/
├── lib/                # Exported library functions (mkSystem)
├── modules/            # NixOS system modules
│   ├── system/        # Core system utilities and configuration
│   ├── desktop.nix    # Desktop services
│   ├── wayland.nix    # Niri compositor and Wayland setup
│   ├── development.nix # Development tools and environments
│   ├── gaming.nix     # Gaming support (Steam, GameMode) - optional
│   ├── graphics.nix   # Graphics drivers and GPU tools
│   ├── hardware/      # Hardware-specific configs (desktop/laptop)
│   ├── networking/    # Network configuration and services
│   ├── services/      # System services - optional
│   ├── users.nix      # User management
│   └── virtualisation.nix # VMs and containers - optional
├── home/               # Home Manager configurations
│   ├── browser/       # Browser and PWA configurations
│   ├── terminal/      # Shell and terminal configs
│   ├── wayland.nix    # Wayland desktop user config
│   ├── workstation.nix # Workstation profile
│   ├── laptop.nix     # Laptop profile
│   ├── niri.nix       # Niri compositor keybindings and rules
│   └── resources/     # Icons, themes, and assets
│       └── pwa-icons/ # PWA application icons (bundled)
├── pkgs/               # Custom package definitions
│   └── pwa-apps/      # PWA package with bundled icons
├── scripts/            # Utility scripts
├── devshells/          # Development environments (Rust, Zig, QML, etc.)
├── examples/           # Example configurations
└── docs/               # Documentation (you are here)
    ├── APPLICATIONS.md # Complete application catalog
    └── ...
```

Each module directory contains a `README.md` explaining its purpose and organization.

## Help and Support

### Getting Help

1. **Check documentation**: Start with the relevant guide above
2. **Search issues**: Look through [existing GitHub issues](https://github.com/kcalvelli/nixos_config/issues)
3. **Ask the community**: Post on [NixOS Discourse](https://discourse.nixos.org/)
4. **Report bugs**: Create a [new issue](https://github.com/kcalvelli/nixos_config/issues/new) with details

### External Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official NixOS documentation
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - User environment management
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dive into Nix
- [NixOS Wiki](https://wiki.nixos.org/) - Community knowledge base

## Contributing to Documentation

When updating documentation:

- **Keep it clear**: Use simple, direct language
- **Keep it concise**: Get to the point quickly
- **Keep it complete**: Include examples and troubleshooting
- **Keep it current**: Update when features change
- **Test instructions**: Verify commands and procedures work

## Quick Links

- 📖 **Main README**: [../README.md](../README.md)
- 💾 **Repository**: https://github.com/kcalvelli/nixos_config
- 🚀 **Releases**: https://github.com/kcalvelli/nixos_config/releases
- 🐛 **Issues**: https://github.com/kcalvelli/nixos_config/issues

---

**Last Updated**: October 2025
