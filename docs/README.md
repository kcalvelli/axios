# Cairn Documentation

Welcome to the Cairn documentation. This guide will help you install, configure, and maintain your NixOS system.

## Documentation Overview

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [INSTALLATION.md](INSTALLATION.md) | Install Cairn on your machine | **Start here** for new installations |
| [MODULE_REFERENCE.md](MODULE_REFERENCE.md) | Complete guide to all modules | **Learn what each module does** |
| [LIBRARY_USAGE.md](LIBRARY_USAGE.md) | Using cairn as a library | Using cairn in your own flake |
| [APPLICATIONS.md](APPLICATIONS.md) | Complete application catalog | See what's included in Cairn |
| [ADDING_HOSTS.md](ADDING_HOSTS.md) | Multi-machine management | Managing multiple systems |
| [USER_MODULE.md](USER_MODULE.md) | User configuration guide | Understanding user setup |
| [SECRETS_MODULE.md](SECRETS_MODULE.md) | Managing encrypted secrets | Using age-encrypted secrets |
| [THEMING.md](THEMING.md) | Desktop theming and customization | Customizing your desktop |
| [UPGRADE.md](UPGRADE.md) | Update cairn to latest version | When updating cairn input |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and fixes | When experiencing problems |
| [BINARY_CACHE.md](BINARY_CACHE.md) | Using the binary cache | Speed up builds |
| [MCP_GUIDE.md](MCP_GUIDE.md) | Complete MCP integration guide | **Understanding AI & MCP** |
| [MCP_REFERENCE.md](MCP_REFERENCE.md) | Quick MCP command reference | Quick lookup for MCP tools |

## Quick Start

### New Users

**Fresh NixOS install:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/cairn/master/scripts/install.sh)
```

**Flakes already enabled:**
```bash
nix run --refresh github:kcalvelli/cairn#init
```

See [INSTALLATION.md](INSTALLATION.md) for full details.

### Existing Users

- **Update system**: `cd ~/my-nixos-config && nix flake update && sudo nixos-rebuild switch --flake .#HOSTNAME`
- **Add new machine**: See [ADDING_HOSTS.md](ADDING_HOSTS.md)
- **Enable AI**: AI is enabled by default (`modules.ai` defaults to `true`)

## Installation & Setup

### 📦 [INSTALLATION.md](INSTALLATION.md)
**Complete installation guide from start to finish**

Topics covered:
- Using the interactive generator
- Manual configuration setup
- Creating your user module
- Disk configuration options
- Building and deploying your system

**Start here if you're installing Cairn for the first time.**

## AI & MCP Integration

### 🤖 [MCP_GUIDE.md](MCP_GUIDE.md)
**Complete guide to MCP (Model Context Protocol) integration**

Essential topics:
- What is MCP and how cairn configures it
- 11 pre-configured MCP servers (no setup required)
- How on-demand tool discovery saves 99% tokens (vs traditional MCP)
- Adding new MCP servers to cairn
- Configuration guide with examples
- Real-world workflows and debugging
- Cost savings analysis ($169/year for typical usage)

**Start here to understand cairn's AI capabilities.**

### 📚 [MCP_REFERENCE.md](MCP_REFERENCE.md)
**Quick reference card for MCP commands**

One-page reference:
- mcp-gateway REST API commands
- Available MCP servers and tools
- Service management
- Common use cases

**Use as a cheat sheet for MCP tool access.**

### 🔮 [advanced-tool-use.md](advanced-tool-use.md)
**Anthropic beta features (API-only)**

Future capabilities:
- Tool Search Tool (defer_loading)
- Programmatic Tool Calling
- Tool Use Examples

**For users interested in upcoming Anthropic API features.**

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

**Browse this to see everything Cairn includes out of the box.**

### 🖥️ [ADDING_HOSTS.md](ADDING_HOSTS.md)
**Managing multiple machines with Cairn**

Covers:
- Adding new hosts to your configuration
- Host configuration structure
- Hardware-specific settings
- Template usage and examples
- Multi-machine best practices

**For users managing Cairn across multiple machines.**

### 🎨 [THEMING.md](THEMING.md)
**Desktop theming and customization**

Includes:
- Wallpaper blur effects for overview mode
- DankMaterialShell integration
- VSCode theme setup
- Application theming overview

**For desktop users wanting to customize their experience.**

## Common Tasks

### Updating Your System

```bash
# Navigate to your config repository
cd ~/my-nixos-config

# Update cairn specifically (recommended)
nix flake lock --update-input cairn

# Or update all inputs
nix flake update

# Rebuild and switch to new configuration
sudo nixos-rebuild switch --flake .#HOSTNAME

# Optionally, clean up old generations
sudo nix-collect-garbage -d
```

**See [UPGRADE.md](UPGRADE.md) for detailed upgrade instructions and troubleshooting.**

### Adding a New Package

Add packages to your `extraConfig` in your host configuration:

```nix
extraConfig = {
  environment.systemPackages = with pkgs; [ package-name ];
  # or for user packages
  home-manager.users.youruser = {
    home.packages = with pkgs; [ package-name ];
  };
};
```

Then rebuild: `sudo nixos-rebuild switch --flake .#HOSTNAME`

### Adding a New Machine

1. Create a new host configuration in your flake.nix
2. Create corresponding disk config  
3. See [ADDING_HOSTS.md](ADDING_HOSTS.md) for details

## Repository Structure

```
cairn/
├── lib/                # Library functions (mkSystem API)
├── modules/            # NixOS system modules
│   ├── default.nix     # Module registry
│   ├── system/         # Core system configuration
│   ├── desktop/        # Desktop environment
│   ├── development/    # Development tools
│   ├── gaming/         # Gaming support (optional)
│   ├── graphics/       # GPU configuration
│   ├── hardware/       # Hardware configs
│   ├── networking/     # Network services
│   ├── pim/            # Personal Information Management
│   ├── services/       # Optional services (Caddy, Immich)
│   ├── ai/             # AI tools and configuration
│   ├── secrets/        # Secrets management
│   ├── virtualisation/ # Libvirt, containers
│   ├── wayland/        # Wayland compositor
│   └── users.nix       # User management
├── home/               # Home Manager user configs
│   ├── profiles/       # Workstation and laptop profiles
│   ├── ai/             # AI tools and MCP configuration
│   ├── browser/        # Browser and PWA configs
│   └── wayland/        # Wayland home configuration
├── examples/           # Example configurations
└── docs/               # Documentation
```

## Help and Support

### Getting Help

1. **Check documentation**: Start with the relevant guide above
2. **Search issues**: Look through [existing GitHub issues](https://github.com/kcalvelli/cairn/issues)
3. **Ask the community**: Post on [NixOS Discourse](https://discourse.nixos.org/)
4. **Report bugs**: Create a [new issue](https://github.com/kcalvelli/cairn/issues/new) with details

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
- 💾 **Repository**: https://github.com/kcalvelli/cairn
- 🚀 **Releases**: https://github.com/kcalvelli/cairn/releases
- 🐛 **Issues**: https://github.com/kcalvelli/cairn/issues

---

**Last Updated**: January 2026
