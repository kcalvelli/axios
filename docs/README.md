# axiOS Documentation

Welcome to the axiOS documentation. This guide will help you install, configure, and maintain your NixOS system.

## Documentation Overview

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [INSTALLATION.md](INSTALLATION.md) | Install axiOS on your machine | **Start here** for new installations |
| [MODULE_REFERENCE.md](MODULE_REFERENCE.md) | Complete guide to all modules | **Learn what each module does** |
| [LIBRARY_USAGE.md](LIBRARY_USAGE.md) | Using axios as a library | Using axios in your own flake |
| [APPLICATIONS.md](APPLICATIONS.md) | Complete application catalog | See what's included in axiOS |
| [ADDING_HOSTS.md](ADDING_HOSTS.md) | Multi-machine management | Managing multiple systems |
| [USER_MODULE.md](USER_MODULE.md) | User configuration guide | Understanding user setup |
| [SECRETS_MODULE.md](SECRETS_MODULE.md) | Managing encrypted secrets | Using age-encrypted secrets |
| [THEMING.md](THEMING.md) | Desktop theming and customization | Customizing your desktop |
| [UPGRADE.md](UPGRADE.md) | Update axios to latest version | When updating axios input |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and fixes | When experiencing problems |
| [BINARY_CACHE.md](BINARY_CACHE.md) | Using the binary cache | Speed up builds |
| [MCP_GUIDE.md](MCP_GUIDE.md) | Complete MCP integration guide | **Understanding AI & MCP** |
| [MCP_REFERENCE.md](MCP_REFERENCE.md) | Quick MCP command reference | Quick lookup for mcp-cli |

## Quick Start

### New Users

The fastest way to get started with axiOS:

```bash
# Create a directory and run the interactive generator
mkdir ~/my-nixos-config && cd ~/my-nixos-config
nix run --refresh --extra-experimental-features "nix-command flakes" github:kcalvelli/axios#init
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
- **Add new machine**: See [ADDING_HOSTS.md](ADDING_HOSTS.md)
- **Enable AI**: Set `modules.ai = true` in host config

## Installation & Setup

### 📦 [INSTALLATION.md](INSTALLATION.md)
**Complete installation guide from start to finish**

Topics covered:
- Using the interactive generator
- Manual configuration setup
- Creating your user module
- Disk configuration options
- Building and deploying your system

**Start here if you're installing axiOS for the first time.**

## AI & MCP Integration

### 🤖 [MCP_GUIDE.md](MCP_GUIDE.md)
**Complete guide to MCP (Model Context Protocol) integration**

Essential topics:
- What is MCP and how axios configures it
- 10 pre-configured MCP servers (no setup required)
- How mcp-cli saves 96.8% tokens (vs traditional MCP)
- Adding new MCP servers to axios
- Configuration guide with examples
- Real-world workflows and debugging
- Cost savings analysis ($169/year for typical usage)

**Start here to understand axios's AI capabilities.**

### 📚 [MCP_REFERENCE.md](MCP_REFERENCE.md)
**Quick reference card for mcp-cli commands**

One-page reference:
- Quick command syntax and examples
- Token savings breakdown
- Cost analysis tables
- Scaling comparison
- Best practices and verification

**Use as a cheat sheet for mcp-cli.**

### 🔮 [advanced-tool-use.md](advanced-tool-use.md)
**Anthropic beta features (API-only)**

Future capabilities:
- Tool Search Tool (defer_loading)
- Programmatic Tool Calling
- Tool Use Examples

**For users interested in upcoming Anthropic API features.**

### 💡 [../home/ai/mcp-examples.nix](../home/ai/mcp-examples.nix)
**100+ ready-to-use MCP server configurations**

Copy-paste examples for popular services:
- Notion, Slack, Jira, Linear
- PostgreSQL, SQLite, MongoDB
- Docker, Kubernetes
- And many more!

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

### 🖥️ [ADDING_HOSTS.md](ADDING_HOSTS.md)
**Managing multiple machines with axiOS**

Covers:
- Adding new hosts to your configuration
- Host configuration structure
- Hardware-specific settings
- Template usage and examples
- Multi-machine best practices

**For users managing axiOS across multiple machines.**

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
axios/
├── lib/                # Library functions (mkSystem API)
├── modules/            # NixOS system modules
│   ├── system/        # Core system configuration
│   ├── desktop.nix    # Desktop environment
│   ├── wayland.nix    # Niri compositor
│   ├── development.nix # Development tools
│   ├── gaming.nix     # Gaming support (optional)
│   ├── hardware/      # Hardware configs
│   ├── networking/    # Network services
│   ├── services/      # Optional services
│   ├── secrets/       # Secrets management
│   └── users.nix      # User management
├── home/              # Home Manager user configs
│   ├── profiles/      # Workstation and laptop profiles
│   ├── browser/       # Browser and PWA configs
│   └── terminal/      # Shell configurations
├── examples/          # Example configurations
└── docs/              # Documentation
```

## Help and Support

### Getting Help

1. **Check documentation**: Start with the relevant guide above
2. **Search issues**: Look through [existing GitHub issues](https://github.com/kcalvelli/axios/issues)
3. **Ask the community**: Post on [NixOS Discourse](https://discourse.nixos.org/)
4. **Report bugs**: Create a [new issue](https://github.com/kcalvelli/axios/issues/new) with details

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
- 💾 **Repository**: https://github.com/kcalvelli/axios
- 🚀 **Releases**: https://github.com/kcalvelli/axios/releases
- 🐛 **Issues**: https://github.com/kcalvelli/axios/issues

---

**Last Updated**: January 2026
