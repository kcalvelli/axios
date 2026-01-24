# Using axiOS as a Library

This guide explains how to use axiOS as a library/framework to build your own NixOS configurations with minimal maintenance.

## Why Use axiOS as a Library?

Instead of forking and maintaining thousands of lines of configuration code, you:

- ✅ Write ~30 lines for your flake.nix
- ✅ Maintain only your personal settings (users, hosts, disks)
- ✅ Get updates by running `nix flake update`
- ✅ Pin to specific versions for stability
- ✅ Override anything you need

**Your entire configuration can be just a few files:**
```
my-nixos-config/
├── flake.nix       # 30-60 lines
├── user.nix        # Your user definition
└── hosts/
    ├── machine1.nix
    └── machine1/disks.nix
```

## Quick Start

### 1. Create Your Configuration Repository

```bash
mkdir ~/my-nixos-config
cd ~/my-nixos-config
```

### 2. Create Your Flake

**flake.nix:**
```nix
{
  description = "My NixOS Configuration";

  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs = { self, axios, nixpkgs, ... }: {
    nixosConfigurations.myhost = axios.lib.mkSystem {
      hostname = "myhost";
      system = "x86_64-linux";
      formFactor = "desktop";
      
      hardware = {
        cpu = "amd";
        gpu = "amd";
        hasSSD = true;
        isLaptop = false;
      };
      
      modules = {
        system = true;
        desktop = true;
        development = true;
        graphics = true;
        networking = true;
        users = true;
        virt = false;
        gaming = false;
        services = false;
      };
      
      homeProfile = "workstation";
      userModulePath = self.outPath + "/user.nix";
      diskConfigPath = ./disks.nix;
    };
  };
}
```

### 3. Create Your User Module

**user.nix:**
```nix
{ self, config, ... }:
let
  username = "myname";
  fullName = "My Full Name";
  email = "me@example.com";
in
{
  users.users.${username} = {
    isNormalUser = true;
    description = fullName;
    # Set password with: sudo passwd ${username}
    # Or use: hashedPassword = "..."; (generate with mkpasswd)
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
  };

  home-manager.users.${username} = {
    home = {
      stateVersion = "24.05";
      homeDirectory = "/home/${username}";
      username = username;
    };

    programs.git.settings = {
      user = {
        name = fullName;
        email = email;
      };
    };
  };

  nix.settings.trusted-users = [ username ];
}
```

### 4. Create Disk Configuration

**disks.nix:**
```nix
{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

### 5. Build and Deploy

```bash
# Build
nix build .#nixosConfigurations.myhost.config.system.build.toplevel

# Install (from installer)
sudo nixos-install --flake .#myhost

# Switch (on existing system)
sudo nixos-rebuild switch --flake .#myhost
```

## Library API Reference

### `axios.lib.mkSystem`

Main function to create a NixOS configuration.

```nix
nixosConfigurations.<name> = axios.lib.mkSystem {
  # Required parameters
  hostname = "string";
  system = "x86_64-linux" | "aarch64-linux";

  # Hardware configuration
  formFactor = "desktop" | "laptop";
  hardware = {
    vendor = "msi" | "system76" | null;  # Optional: Hardware vendor for specific optimizations
    cpu = "amd" | "intel";                # CPU type
    gpu = "amd" | "nvidia" | "intel";     # GPU type
    hasSSD = bool;                        # SSD optimization
    isLaptop = bool;                      # Laptop optimizations
  };
  
  # Module selection
  modules = {
    system = bool;       # Core system config (recommended: true)
    desktop = bool;      # Niri desktop environment
    development = bool;  # Development tools and IDEs
    graphics = bool;     # Graphics drivers and tools
    networking = bool;   # Network configuration (recommended: true)
    users = bool;        # User management (recommended: true)
    virt = bool;         # Virtualization (libvirt, containers)
    gaming = bool;       # Gaming support (Steam, GameMode)
    ai = bool;           # AI tools (GitHub Copilot, Claude Code, MCP servers)
    secrets = bool;      # Encrypted secrets management (agenix)
    services = bool;     # Self-hosted services (Immich, Caddy)
  };
  
  # Home Manager profile
  homeProfile = "workstation" | "laptop";
  
  # Paths
  userModulePath = path;  # Path to your user.nix
  diskConfigPath = path;  # Path to your disks.nix
  
  # Optional: Additional configuration
  extraConfig = {
    # System timezone (required)
    axios.system.timeZone = "America/New_York";

    # Any additional NixOS configuration options
    # Examples:
    services.openssh.enable = true;

    # For extending with custom services, import your own modules:
    imports = [ ./my-services.nix ];
  };
  
  # Optional: Virtualization config (if modules.virt = true)
  virt = {
    libvirt.enable = bool;
    containers.enable = bool;
  };

  # Optional: Self-hosted services (if modules.services = true)
  axios = {
    immich = {
      enable = bool;                    # Photo management server
      role = "server" | "client";       # Server runs service, client gets PWA
      enableGpuAcceleration = bool;     # Use GPU for ML/transcoding (server only)
      gpuType = "amd" | "nvidia" | "intel";
      pwa = {
        enable = bool;
        tailnetDomain = "your-tailnet.ts.net";
      };
    };
  };
};
```

## Configuration Details

### Hardware Configuration

The `hardware` section configures hardware-specific optimizations:

**CPU:**
- `"amd"` - Enables AMD-specific optimizations and microcode
- `"intel"` - Enables Intel-specific optimizations and microcode

**GPU:**
- `"amd"` - AMD graphics drivers (mesa, AMDVLK)
- `"nvidia"` - Nvidia proprietary drivers
- `"intel"` - Intel graphics drivers

**Vendor (Optional):**

Most users should **omit this field** or set it to `null`. Only use vendor-specific options if you have that specific hardware and want the optimizations.

- `"msi"` - **MSI motherboard optimizations** (Desktop only):
  - Enables `nct6775` kernel module for Super I/O chip sensors (fan speeds, temperatures)
  - Sets `acpi_enforce_resources=lax` kernel parameter for sensor access
  - Auto-enables desktop hardware module with MSI-specific features
  - **When to use:** You have an MSI motherboard AND want hardware sensor monitoring
  
- `"system76"` - **System76 laptop support** (Laptop only):
  - Enables System76 firmware daemon for BIOS/EC updates
  - Enables System76 power daemon for advanced power management
  - Loads `system76_acpi` kernel module for keyboard backlight control
  - Includes Pangolin 12 quirks (disables psmouse, MediaTek Wi-Fi fix)
  - Auto-enables laptop hardware module with System76-specific features
  - **When to use:** You own a System76 laptop (Pangolin, Oryx, Lemur, etc.)
  
- `null` or omitted - **Generic hardware support (recommended for most users)**
  - Uses form-factor based optimizations (desktop/laptop) without vendor-specific features
  - Works with all hardware brands (ASUS, Gigabyte, Dell, Lenovo, HP, etc.)

**Form Factor:**
- `"desktop"` - Desktop optimizations
- `"laptop"` - Laptop power management and battery optimization

### Module Selection

Enable only the modules you need:

**System (Required):**
- Core NixOS configuration
- Boot settings
- Nix configuration
- System packages

**Desktop:**
- Niri compositor
- DankMaterialShell
- Desktop applications
- Fonts and themes

**Development:**
- Code editors (VSCode)
- Compilers and build tools
- Language servers
- Version control tools

**Graphics:**
- Hardware acceleration
- Graphics drivers
- GPU tools and monitoring

**Networking:**
- NetworkManager
- VPN support
- Firewall configuration
- Avahi/mDNS

**Users:**
- User account management
- Home Manager integration
- User environment setup

**Virtualization:**
- libvirt/QEMU
- Podman containers
- VM management tools

**Gaming:**
- Steam
- GameMode
- Gamescope
- Gaming utilities

**AI (Artificial Intelligence):**
- GitHub Copilot CLI (code suggestions)
- Claude Code (AI pair programming)
- MCP servers for enhanced context (filesystem, git, github, nixos, journal)
- AI development tools

**Secrets:**
- agenix for encrypted secrets
- Automatic secret decryption at boot
- Secure API key management
- See [SECRETS_MODULE.md](SECRETS_MODULE.md) for details

**Services (Self-Hosted):**
- Immich (photo management and backup)
- Caddy reverse proxy with automatic HTTPS
- Tailscale integration for secure remote access
- Optional GPU acceleration for photo ML features

### Home Manager Profiles

**Workstation:**
- Desktop productivity apps
- Full development environment
- Media applications
- Gaming support (if gaming module enabled)

**Laptop:**
- Battery optimization
- Power management
- Mobile-friendly apps
- Reduced resource usage

## Multiple Hosts

Manage multiple machines in one configuration:

```nix
{
  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs = { self, axios, nixpkgs, ... }:
    let
      # Shared user module
      userModule = self.outPath + "/user.nix";
      
      # Desktop configuration
      desktopConfig = {
        hostname = "desktop";
        formFactor = "desktop";
        hardware = {
          vendor = "msi";
          cpu = "amd";
          gpu = "amd";
          hasSSD = true;
          isLaptop = false;
        };
        modules = {
          system = true;
          desktop = true;
          development = true;
          gaming = true;
          # ... other modules
        };
        homeProfile = "workstation";
        userModulePath = userModule;
        diskConfigPath = ./hosts/desktop/disks.nix;
      };
      
      # Laptop configuration
      laptopConfig = {
        hostname = "laptop";
        formFactor = "laptop";
        hardware = {
          vendor = "system76";
          cpu = "amd";
          gpu = "amd";
          hasSSD = true;
          isLaptop = true;
        };
        modules = {
          system = true;
          desktop = true;
          development = true;
          gaming = false;  # No gaming on laptop
          # ... other modules
        };
        homeProfile = "laptop";
        userModulePath = userModule;
        diskConfigPath = ./hosts/laptop/disks.nix;
      };
    in
    {
      nixosConfigurations = {
        desktop = axios.lib.mkSystem desktopConfig;
        laptop = axios.lib.mkSystem laptopConfig;
      };
    };
}
```

See [examples/multi-host](../examples/multi-host/) for a complete example.

## Updating axiOS

### Regular Updates

Get the latest features from axiOS:

```bash
cd ~/my-nixos-config
nix flake update
sudo nixos-rebuild switch --flake .#myhost
```

### Pin to Specific Versions

For stability, pin to a specific version:

**Pin to branch:**
```nix
axios.url = "github:kcalvelli/axios/master";
```

**Pin to tag:**
```nix
axios.url = "github:kcalvelli/axios/v1.0.0";
```

**Pin to commit:**
```nix
axios.url = "github:kcalvelli/axios/abc123def456...";
```

### Check What Changed

Before updating, see what changed in axios:

```bash
# View axios commit history
nix flake metadata axios

# Compare your pinned version to latest
git log --oneline $(nix flake metadata --json | jq -r '.locks.nodes.axios.locked.rev')..origin/master
```

## Customization

### Override Specific Options

Use `extraConfig` to override or add options:

```nix
axios.lib.mkSystem {
  # ... standard config ...

  extraConfig = {
    # System timezone (required)
    axios.system.timeZone = "America/New_York";

    # Enable crash diagnostics for automatic recovery from system freezes
    hardware.crashDiagnostics = {
      enable = true;
      rebootOnPanic = 30;        # Auto-reboot after 30 seconds
      treatOopsAsPanic = true;   # Aggressive recovery from kernel errors
      enableCrashDump = false;   # Disable to save RAM (kdump uses memory)
    };

    # Add extra packages
    environment.systemPackages = with pkgs; [
      my-custom-package
    ];

    # Override any NixOS option
    services.openssh.settings.PermitRootLogin = "no";
  };
}
```

### Add Your Own Modules

Import additional modules alongside axios:

```nix
axios.lib.mkSystem {
  # ... standard config ...
  
  extraConfig = {
    imports = [
      ./my-custom-module.nix
      ./my-other-module.nix
    ];
  };
}
```

### Override Packages

Override specific packages from axios:

```nix
{
  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
    
    # Add your own input for a specific package
    my-package.url = "github:user/my-package";
  };

  outputs = { self, axios, nixpkgs, my-package, ... }: {
    nixosConfigurations.myhost = axios.lib.mkSystem {
      # ... config ...
      
      extraConfig = {
        nixpkgs.overlays = [
          (final: prev: {
            # Override a package
            some-package = my-package.packages.${prev.system}.default;
          })
        ];
      };
    };
  };
}
```

## Advanced Usage

### Use Specific axiOS Modules Only

If you want fine-grained control, you can import specific modules:

```nix
{
  inputs.axios.url = "github:kcalvelli/axios";
  
  outputs = { self, axios, nixpkgs, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Use only specific axios modules
        axios.nixosModules.desktop
        axios.nixosModules.networking
        
        # Your own configuration
        ./configuration.nix
      ];
    };
  };
}
```

### Fork and Customize

For deep customization, fork axios:

1. Fork the repository on GitHub
2. Update your flake input: `axios.url = "github:yourusername/axios";`
3. Make your changes in your fork
4. Optionally contribute improvements back upstream

## Troubleshooting

### Build Errors

If you get build errors after updating:

1. Check axios changelog for breaking changes
2. Update your configuration to match new API
3. Pin to previous version temporarily:
   ```bash
   nix flake lock --update-input axios --override-input axios github:kcalvelli/axios/<old-commit>
   ```

### Module Conflicts

If you have conflicting options:

1. Check what axios modules are setting with `extraConfig`
2. Use `lib.mkForce` to override:
   ```nix
   extraConfig = {
     some.option = lib.mkForce "my-value";
   };
   ```

### Missing Features

If axios doesn't provide something you need:

1. Add it to your `extraConfig`
2. Create a custom module
3. Submit a PR to axios with the feature
4. Fork axios and add it yourself

## Examples

- [Minimal Single Host](../examples/minimal-flake/) - Basic single machine
- [Multiple Hosts](../examples/multi-host/) - Managing multiple machines

## Support

- [GitHub Issues](https://github.com/kcalvelli/axios/issues) - Bug reports and feature requests
- [Documentation](../docs/) - Additional guides and references
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS documentation

## Migration from Direct Installation

If you previously cloned axios directly and want to switch to library usage:

1. Create new repo with your personal configs
2. Copy your `hosts/*.nix` files
3. Copy your `modules/users/*.nix` files  
4. Create flake.nix using `axios.lib.mkSystem`
5. Test the new configuration
6. Switch to it with `nixos-rebuild`

Your old configuration can be removed once verified working.
