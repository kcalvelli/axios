# Using axiOS as a Library

This guide explains how to use axiOS as a library/framework to build your own NixOS configurations with minimal maintenance.

## Why Use axiOS as a Library?

Instead of forking and maintaining thousands of lines of configuration code, you:

- Write ~30 lines for your flake.nix
- Maintain only your personal settings (users, hosts)
- Get updates by running `nix flake update`
- Pin to specific versions for stability
- Override anything you need

**Your entire configuration can be just a few files:**
```
~/.config/nixos_config/
├── flake.nix                 # 30-60 lines
├── hosts/
│   ├── desktop.nix           # Host configuration
│   └── desktop/
│       └── hardware.nix      # From nixos-generate-config
└── users/
    └── alice.nix             # Per-user definition
```

## Quick Start

### 1. Create Your Configuration Repository

```bash
mkdir -p ~/.config/nixos_config
cd ~/.config/nixos_config
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

  outputs = { self, axios, nixpkgs, ... }:
    let
      mkHost = hostname: axios.lib.mkSystem (
        (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
          configDir = self.outPath;
        }
      );
    in
    {
      nixosConfigurations = {
        myhost = mkHost "myhost";
      };
    };
}
```

### 3. Create Your Host Configuration

**hosts/myhost.nix:**
```nix
{ lib, ... }:
{
  hostConfig = {
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
    };

    homeProfile = "workstation";
    hardwareConfigPath = ./myhost/hardware.nix;

    users = [ "alice" ];  # References users/alice.nix

    extraConfig = {
      # System timezone (required)
      axios.system.timeZone = "America/New_York";
    };
  };
}
```

### 4. Create Your User Module

**users/alice.nix:**
```nix
{ ... }:
{
  axios.users.users.alice = {
    fullName = "Alice Smith";
    email = "alice@example.com";
    isAdmin = true;
  };
}
```

That's it! axiOS automatically creates the user account, assigns groups based on enabled modules, configures home-manager, and sets up git.

### 5. Copy Hardware Configuration

```bash
mkdir -p hosts/myhost
cp /etc/nixos/hardware-configuration.nix hosts/myhost/hardware.nix
```

### 6. Build and Deploy

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
  # Required
  hostname = "string";

  # System architecture (default: "x86_64-linux")
  system = "x86_64-linux" | "aarch64-linux";

  # Hardware configuration
  formFactor = "desktop" | "laptop";
  hardware = {
    vendor = "msi" | "system76" | null;  # Optional vendor-specific optimizations
    cpu = "amd" | "intel";
    gpu = "amd" | "nvidia" | "intel";
    hasSSD = bool;
    isLaptop = bool;
  };

  # Module selection
  modules = {
    system = bool;        # Core system config (default: true)
    desktop = bool;       # Niri desktop environment (default: false)
    development = bool;   # Development tools and IDEs (default: false)
    graphics = bool;      # Graphics drivers and tools (default: false)
    networking = bool;    # Network configuration (default: true)
    users = bool;         # User management (default: true)
    virt = bool;          # Virtualization - libvirt, containers (default: false)
    gaming = bool;        # Gaming - Steam, GameMode (default: false)
    ai = bool;            # AI tools - Claude Code, Gemini, MCP servers (default: true)
    pim = bool;           # Personal info management - email, calendar (default: false)
    secrets = bool;       # Encrypted secrets via agenix (default: false)
    syncthing = bool;     # Peer-to-peer XDG directory sync (default: false)
    services = bool;      # Self-hosted services - Immich (default: false)
  };

  # Home Manager profile
  homeProfile = "workstation" | "laptop";

  # Multi-user support
  users = [ "alice" "bob" ];  # References users/<name>.nix files
  configDir = path;           # Root of your config repo (typically self.outPath)

  # Hardware configuration path (from nixos-generate-config)
  hardwareConfigPath = path;

  # Optional: Additional NixOS configuration
  extraConfig = { /* any NixOS options */ };

  # Optional: Pass additional flake inputs
  inputs = { /* override or supplement framework inputs */ };

  # Optional: Virtualization config (if modules.virt = true)
  virt = {
    libvirt.enable = bool;
    containers.enable = bool;
  };

  # Optional: Secrets config (if modules.secrets = true)
  secrets = { /* agenix configuration */ };
};
```

**Notes:**
- `modules.ai` defaults to `true` (opt-out, not opt-in)
- `modules.system`, `modules.networking`, and `modules.users` default to `true`
- `configDir` is required when `users` list is non-empty

## Configuration Details

### Hardware Configuration

The `hardware` section configures hardware-specific optimizations:

**CPU:**
- `"amd"` - Enables AMD-specific optimizations and microcode
- `"intel"` - Enables Intel-specific optimizations and microcode

**GPU:**
- `"amd"` - AMD graphics drivers (mesa, RADV Vulkan, GPU recovery)
- `"nvidia"` - Nvidia proprietary drivers (modesetting, PRIME for laptops)
- `"intel"` - Intel graphics drivers (mesa, media driver)

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
- `"desktop"` - Desktop optimizations (power management, PCIe, irqbalance)
- `"laptop"` - Laptop power management and battery optimization

### Module Selection

Enable only the modules you need:

**System (default: true):**
- Core NixOS configuration and boot settings
- Plymouth branded splash screen
- Nix settings and garbage collection
- systemd-oomd for memory pressure management
- PipeWire audio stack
- CUPS printing support
- Bluetooth support
- Core system packages

**Desktop:**
- Niri scrollable tiling Wayland compositor
- DankMaterialShell with greetd greeter
- Dolphin file manager (KDE)
- Desktop applications (see [APPLICATIONS.md](APPLICATIONS.md))
- Fonts and icon themes

**Development:**
- Code editors (VSCode)
- Compilers and build tools
- Language servers
- Version control tools

**Graphics:**
- Hardware acceleration (OpenGL, Vulkan)
- GPU-specific drivers and configuration
- GPU monitoring tools (radeontop for AMD, nvtop for NVIDIA)
- AMD GPU recovery (auto-reset on hang)

**Networking (default: true):**
- NetworkManager
- Tailscale VPN
- Samba file sharing
- Avahi/mDNS
- Firewall configuration

**Users (default: true):**
- Multi-user account management via `axios.users.users.<name>`
- Home Manager integration
- Automatic group assignment based on enabled modules

**Virtualization:**
- libvirt/QEMU for full virtual machines
- Podman containers
- VM management tools

**Gaming:**
- Steam with Proton and Proton-GE
- GameMode for CPU/GPU optimization
- Gamescope session support
- mangohud performance overlay
- prismlauncher (Minecraft), superTuxKart
- nix-ld for native Linux game compatibility

**AI (default: true):**
- Claude Code, Claude Desktop, Gemini CLI
- MCP servers for enhanced AI context (11 servers)
- claude-monitor, openspec, spec-kit
- whisper-cpp for speech-to-text
- Optional local LLM stack (Ollama + OpenCode)

**PIM:**
- axios-ai-mail (AI-powered email)
- Calendar and contacts via axios-dav (mcp-dav)

**Secrets:**
- agenix for encrypted secrets
- Automatic secret decryption at boot
- Secure API key management
- See [SECRETS_MODULE.md](SECRETS_MODULE.md) for details

**Syncthing:**
- Peer-to-peer XDG directory synchronization
- Tailscale-only transport
- Declarative folder and device configuration

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

**Laptop:**
- Power management optimizations
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
      mkHost = hostname: axios.lib.mkSystem (
        (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
          configDir = self.outPath;
        }
      );
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        laptop = mkHost "laptop";
      };
    };
}
```

See [examples/example-config/](../examples/example-config/) for a complete multi-host example.

## Updating axiOS

### Regular Updates

Get the latest features from axiOS:

```bash
cd ~/.config/nixos_config
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
            some-package = my-package.packages.${prev.stdenv.hostPlatform.system}.default;
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

- [Example Configuration](../examples/example-config/) - Multi-host setup with multiple users

## Support

- [GitHub Issues](https://github.com/kcalvelli/axios/issues) - Bug reports and feature requests
- [Documentation](../docs/) - Additional guides and references
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS documentation

## Migration from Old Format

If you're migrating from the old `userModulePath`/`diskConfigPath` API:

1. **`userModulePath` -> `users` list + `configDir`**: Replace stringly-typed path with `users = [ "username" ]` in host config and add `configDir = self.outPath`
2. **`diskConfigPath` -> `hardwareConfigPath`**: Rename the parameter
3. **`axios.user` -> `axios.users.users.<name>`**: Replace singular user options with multi-user submodule
4. **`user.nix` -> `users/<name>.nix`**: Move root-level user file to `users/` directory
5. **Host config extraction**: Move inline host configs from flake.nix to `hosts/<hostname>.nix` files
