# Package Organization Guide

This document explains how packages are organized throughout the configuration and where to add new packages.

## Overview

Packages are deliberately split between **system-level** (`modules/`) and **user-level** (`home/`) to maintain proper separation of concerns while keeping related functionality modular.

All packages are defined **inline** within their respective modules for better discoverability and maintainability.

## Quick Reference

| Package Type | System Location | Home Location |
|--------------|----------------|---------------|
| Core utilities | `modules/system/default.nix` | - |
| Desktop services | `modules/desktop.nix` | - |
| Development tools | `modules/development.nix` | `home/terminal/` |
| Gaming infrastructure | `modules/gaming.nix` | `home/workstation.nix` |
| Graphics/GPU | `modules/graphics.nix` | - |
| Desktop apps | `modules/desktop.nix` (if privileged) | `home/workstation.nix` or `home/laptop.nix` |
| Wayland tools | `modules/wayland.nix` | `home/wayland.nix` |
| User applications | - | `home/workstation.nix` or `home/laptop.nix` |

## System vs Home-Manager Decision Tree

### Install at System Level (`modules/`) if:
- ✓ Requires privileged access or runs as a service
- ✓ Needs hardware access (GPU tools, peripherals)
- ✓ Must be available to root or multiple users
- ✓ Provides system-wide infrastructure (containers, VMs)
- ✓ Requires firewall rules or system networking

### Install with Home-Manager (`home/`) if:
- ✓ User desktop application
- ✓ Has user-specific configuration/dotfiles
- ✓ User preference tool (themes, fonts)
- ✓ Personal productivity software
- ✓ User-specific development tools

## Package Organization Pattern

All modules define packages inline, organized with comments for clarity:

```nix
# modules/example/default.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Category 1: Description
    pkg1
    pkg2
    
    # Category 2: Description
    pkg3
    pkg4
  ];
}
```

### Modules and Their Package Categories:

**System Modules:**
- `modules/system/default.nix` - Core utilities, filesystem, monitoring, archives, security, nix tools
- `modules/wayland.nix` - System desktop apps, icon themes, file manager
- `modules/development.nix` - Development tools and language servers
- `modules/graphics.nix` - GPU utilities and drivers
- `modules/gaming.nix` - Gaming infrastructure (Steam, GameMode, etc.)
- `modules/virtualisation.nix` - VM and container tools
- `modules/desktop.nix` - Desktop services and privileged apps

**Home Modules:**
- `home/wayland.nix` - Wayland-specific user tools (launchers, screenshot, themes, fonts, utilities)
- `home/workstation.nix` - Desktop applications for workstation profile
- `home/laptop.nix` - Desktop applications for laptop profile
- `home/terminal/` - Terminal configuration and tools
- `home/browser/` - Browser configuration

## Directory Structure

```
.
├── modules/                          # System-level (NixOS modules)
│   ├── system/                       # Core system utilities
│   │   ├── default.nix               # System packages inline
│   │   └── README.md                 # Module documentation
│   ├── desktop.nix                   # Desktop services
│   ├── wayland.nix                   # Wayland packages inline
│   ├── development.nix               # Dev tools inline
│   ├── gaming.nix                    # Gaming packages inline
│   ├── graphics.nix                  # GPU packages inline
│   └── virtualisation.nix            # VM packages inline
│
└── home/                             # User-level (home-manager)
    ├── wayland.nix                   # Wayland user packages inline
    ├── workstation.nix               # Workstation packages inline
    ├── laptop.nix                    # Laptop packages inline
    ├── terminal/                     # Shell configurations
    ├── browser/                      # Browser configs
    └── README.md
```

## Common Patterns

### 1. Categories with Comments
Files use section headers for clarity:
```nix
environment.systemPackages = with pkgs; [
  # Network Tools
  curl
  wget
  
  # System Monitoring
  htop
  gtop
];
```

### 2. Intentional Duplication
Some tools appear in both system and home-manager by design:

**Example: Shell tools (fish, eza, fzf)**
- **System** (`modules/development.nix`): Available for root and system operations
- **Home** (`home/terminal/`): User-specific configuration via `programs.*`

This is intentional and documented in module README files.

### 3. Gaming Split
Gaming infrastructure is split across two locations:

**System** (`modules/gaming.nix`):
- Steam (service + firewall rules)
- GameMode (system daemon)
- Gamescope (privileged compositor)

**Home** (`home/workstation.nix`):
- protonup-ng (user tool)
- Game-specific configs

### 4. Desktop Apps Split
Desktop applications are split by privilege requirement:

**System** (`modules/desktop.nix`):
- VPN clients (network configuration)
- OBS (hardware access)
- System services (kdeconnect, localsend)

**Home** (`home/workstation.nix` or `home/laptop.nix`):
- Productivity apps (LibreOffice, Obsidian)
- Media apps (Celluloid, Pinta)
- Communication (Discord)

## Adding New Packages

### Step 1: Determine Location
Use the decision tree above to choose system or home-manager.

### Step 2: Find the Right Module
- System utilities → `modules/system/default.nix`
- Development tools → `modules/development.nix`
- Desktop apps → `home/workstation.nix` or `home/laptop.nix`
- Wayland tools → `home/wayland.nix`

### Step 3: Add to Appropriate Category
Add the package under the appropriate comment section:
```nix
# System Monitoring
htop
gtop
your-new-tool  # Add here
```

### Step 4: Check README
Read the module's README.md to ensure the package belongs there.

## Module Documentation

Each major module directory contains a README.md explaining:
- Purpose and scope
- Package organization
- What belongs in that module
- Where alternatives should go
- Configuration examples

**Read these first** when adding packages to understand the module's role.

## Examples

### Adding a System Monitoring Tool
1. Location: System-level (needs hardware access)
2. Module: `modules/system/default.nix`
3. Category: System monitoring and information
4. Update: Add to inline list in the module

### Adding a Text Editor
1. Location: User-level (user preference)
2. Module: `home/workstation.nix` or `home/laptop.nix`
3. Category: Add under appropriate comment section
4. Update: Add to inline list in the module

### Adding a Wayland Widget
1. Location: User-level (UI tool)
2. Module: `home/wayland.nix`
3. Category: System utilities
4. Update: Add to inline list in the module

## Maintenance

### Reviewing Package Organization
```bash
# Find all modules with packages
grep -r "environment.systemPackages\|home.packages" modules/ home/ --include="*.nix"

# Find all READMEs
find . -name "README.md" | grep -E "(modules|home)"
```

### Adding New Categories
When a category grows beyond 10-15 packages, consider:
1. Adding sub-sections with more specific comments
2. Creating a dedicated sub-module
3. Documenting the new organization in README.md

### Refactoring Guidance
- Keep modules focused on a single concern
- Document intentional duplication in READMEs
- Use clear comment headers to organize packages
- Group related packages together

## Philosophy

This organization maintains modularity while improving discoverability:

1. **Modular**: Related packages stay in their logical modules
2. **Discoverable**: All functionality visible in one file per module
3. **Maintainable**: Comments and clear structure make updates easy
4. **Consistent**: All modules follow the same inline pattern

The goal is to make it immediately clear where a new package should go based on its purpose and requirements, and to see everything a module provides in one place.

