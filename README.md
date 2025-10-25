# axiOS

<p align="center">
  <img src="docs/logo.png" alt="axiOS Logo" width="400">
</p>

<p align="center">
  <em>A modular <a href="https://nixos.org">NixOS</a> framework and library for building reproducible systems with <a href="https://github.com/nix-community/home-manager">Home Manager</a>, modern desktop environments, and curated development tools.</em>
</p>

## What is axiOS?

axiOS is a **NixOS framework and library** that you import into your own flake to build NixOS configurations. Think of it as a curated collection of modules, packages, and home-manager configs that work together.

Import axios into your own minimal flake and use `axios.lib.mkSystem` to build configurations. You maintain just a few files (~30 lines), and axios provides everything else.

## Quick Start - Using axiOS as a Library

Create your own minimal configuration repository:

```nix
# flake.nix
{
  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
  };
  
  outputs = { self, axios, nixpkgs, ... }:
    let
      myHostConfig = {
        hostname = "mycomputer";
        system = "x86_64-linux";
        formFactor = "desktop";  # or "laptop"
        
        hardware = {
          cpu = "amd";     # or "intel"
          gpu = "amd";     # or "nvidia"
          hasSSD = true;
          isLaptop = false;
        };
        
        modules = {
          system = true;
          desktop = true;
          development = true;
          gaming = false;
          # ... etc
        };
        
        homeProfile = "workstation";  # or "laptop"
        diskConfigPath = ./disks.nix;
        
        # User module
        userModulePath = ./myuser.nix;
      };
    in
    {
      nixosConfigurations.mycomputer = axios.lib.mkSystem myHostConfig;
    };
}
```

That's it! Your entire configuration is ~30 lines. All the modules, packages, and home-manager configs come from axios.

See [docs/LIBRARY_USAGE.md](docs/LIBRARY_USAGE.md) for complete documentation on using axios as a library.

## Features

### Desktop Experience
- **[Niri compositor](https://github.com/YaLTeR/niri)** - Scrollable tiling Wayland compositor
- **DankMaterialShell** - Material design shell with custom theming
- **Wallpaper blur effects** - Automatic blur for overview mode
- **Ghostty terminal** - Modern GPU-accelerated terminal
- **LazyVim** - Pre-configured Neovim with LSP support
- **Hardware acceleration** - Optimized for AMD/Intel/Nvidia graphics

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

## Screenshots

### Niri Overview
![Niri Overview](docs/screenshots/overview.png)
*[Niri](https://github.com/YaLTeR/niri) scrollable tiling compositor with workspace overview*

### Dropdown Terminal
![Dropdown Terminal](docs/screenshots/dropdown.png)
*Ghostty terminal with dropdown mode and custom theming*

### File Manager
![Nautilus File Manager](docs/screenshots/nautilus.png)
*Nautilus file manager with custom theme integration*

## Documentation

### Using as a Library
- [Library Usage Guide](docs/LIBRARY_USAGE.md) - Complete guide to using axios.lib.*
- [Adding Hosts](docs/ADDING_HOSTS.md) - Managing multiple machines
- [Quick Reference](docs/QUICK_REFERENCE.md) - Common commands

### Direct Installation
- [Installation Guide](docs/INSTALLATION.md) - Install axios directly
- [Building ISOs](docs/BUILDING_ISO.md) - Create custom installer images

### Reference
- [Package Organization](docs/PACKAGES.md) - How packages are structured
- [Desktop Customization](docs/NIRI_WALLPAPER.md) - Wallpaper and theming

## Library API

axiOS exports library functions for building NixOS configurations:

### `axios.lib.mkSystem`

Main function to create a NixOS system configuration.

```nix
nixosConfigurations.myhost = axios.lib.mkSystem {
  hostname = "myhost";
  system = "x86_64-linux";
  formFactor = "desktop" | "laptop";
  
  hardware = {
    vendor = "msi" | "system76" | null;
    cpu = "amd" | "intel";
    gpu = "amd" | "nvidia";
    hasSSD = bool;
    isLaptop = bool;
  };
  
  modules = {
    system = bool;      # Core system config
    desktop = bool;     # Niri desktop
    development = bool; # Dev tools
    services = bool;    # System services
    graphics = bool;    # Graphics drivers
    networking = bool;  # Network config
    users = bool;       # User management
    virt = bool;        # Virtualization
    gaming = bool;      # Gaming support
  };
  
  homeProfile = "workstation" | "laptop";
  diskConfigPath = ./path/to/disks.nix;
  userModulePath = ./path/to/user.nix;
  
  extraConfig = {
    # Any additional NixOS configuration
  };
};
```

See [docs/LIBRARY_USAGE.md](docs/LIBRARY_USAGE.md) and [lib/README.md](lib/README.md) for complete API documentation.

## Examples

Check out these example repositories:

- [examples/minimal-flake](examples/minimal-flake/) - Minimal single-host configuration
- [examples/multi-host](examples/multi-host/) - Multiple hosts with shared config

Real-world example: [kcalvelli/nixos_config](https://github.com/kcalvelli/nixos_config) - Personal configs using axios as a library

## Project Structure

```
.
├── lib/              # Exported library functions
│   └── README.md     # Library API documentation
├── modules/          # NixOS modules (system-level)
│   ├── desktop/      # Desktop environment
│   ├── development/  # Development tools
│   ├── gaming/       # Gaming support
│   ├── graphics/     # Graphics drivers
│   ├── hardware/     # Hardware configs
│   ├── networking/   # Network services
│   ├── services/     # System services
│   ├── system/       # Core system
│   ├── users/        # User management
│   └── virtualisation/ # VMs and containers
├── home/             # Home Manager configs
│   ├── common/       # Shared user configs
│   ├── desktops/     # Desktop-specific
│   ├── profiles/     # User profiles
│   └── resources/    # Themes and resources
├── hosts/            # Example host configs
├── docs/             # Documentation
├── scripts/          # Utility scripts
├── devshells/        # Development environments
└── pkgs/             # Custom packages
```

Each directory contains a README explaining its purpose.

## Development Environments

Available development shells:

```bash
nix develop          # Default: Spec Kit
nix develop .#rust   # Rust with Fenix
nix develop .#zig    # Zig compiler
nix develop .#qml    # Qt6/QML
```

## Why axiOS?

- ✅ **Minimal maintenance** - Your config is ~30 lines, axios handles the rest
- ✅ **Selective updates** - `nix flake update` to get new features when you want
- ✅ **Version pinning** - Lock to specific axios versions for stability
- ✅ **Clear separation** - Your personal configs vs framework code
- ✅ **Easy sharing** - Your config repo is simple and understandable
- ✅ **Community framework** - Benefit from improvements and updates

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
