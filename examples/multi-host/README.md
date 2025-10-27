# Multi-Host axiOS Configuration Example

This example demonstrates managing multiple NixOS systems with axiOS, showing how to share configuration while customizing for different machines.

## Structure

```
multi-host/
├── flake.nix                    # Main flake with all host configurations
├── users/
│   ├── desktop-user.nix         # Desktop user configuration
│   ├── laptop-user.nix          # Laptop user configuration
│   └── server-user.nix          # Server user configuration
├── hosts/
│   ├── desktop/
│   │   └── disks.nix            # Desktop disk layout
│   ├── laptop/
│   │   └── disks.nix            # Laptop disk layout
│   └── server/
│       └── disks.nix            # Server disk layout
└── README.md                    # This file
```

## Hosts Included

### Desktop Workstation
- **Hostname**: `desktop`
- **Hardware**: AMD CPU/GPU, NVMe SSD
- **Profile**: Full workstation with Niri desktop
- **User**: alice

### Laptop
- **Hostname**: `laptop`
- **Hardware**: Intel CPU/GPU, NVMe SSD
- **Profile**: Laptop with power management
- **User**: alice

### Server
- **Hostname**: `server`
- **Hardware**: Intel CPU, SATA disk
- **Profile**: Headless server with virtualization
- **User**: admin
- **Note**: No desktop environment or graphics drivers

## Key Concepts

### Shared Configuration

The `sharedConfig` in `flake.nix` defines common module settings used by desktop and laptop:

```nix
sharedConfig = {
  modules = {
    system = true;
    desktop = true;
    development = true;
    graphics = true;
    networking = true;
    users = true;
    services = false;
    virt = false;
    gaming = false;
  };
};
```

### Per-Host Customization

Each host configuration extends or overrides shared settings:

```nix
desktopConfig = sharedConfig // {
  hostname = "desktop";
  hardware = { cpu = "amd"; gpu = "amd"; ... };
  userModulePath = ./users/desktop-user.nix;
  diskConfigPath = ./hosts/desktop/disks.nix;
};
```

### Multiple Configurations

The flake exports all hosts in `nixosConfigurations`:

```nix
nixosConfigurations = {
  desktop = axios.lib.mkSystem desktopConfig;
  laptop = axios.lib.mkSystem laptopConfig;
  server = axios.lib.mkSystem serverConfig;
};
```

## Usage

### Building a Specific Host

```bash
# Build desktop configuration
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Build laptop configuration
nix build .#nixosConfigurations.laptop.config.system.build.toplevel

# Build server configuration
nix build .#nixosConfigurations.server.config.system.build.toplevel
```

### Installing to a Machine

```bash
# From installer, specify which host to install
sudo nixos-install --flake .#desktop
# or
sudo nixos-install --flake .#laptop
# or
sudo nixos-install --flake .#server
```

### Switching Configuration

```bash
# On the desktop
sudo nixos-rebuild switch --flake .#desktop

# On the laptop
sudo nixos-rebuild switch --flake .#laptop

# On the server
sudo nixos-rebuild switch --flake .#server
```

### Remote Deployment

```bash
# Deploy to server from your workstation
nixos-rebuild switch --flake .#server --target-host admin@server --use-remote-sudo
```

## Customization Guide

### 1. Copy This Example

```bash
mkdir ~/my-nixos-config
cp -r examples/multi-host/* ~/my-nixos-config/
cd ~/my-nixos-config
```

### 2. Customize Hostnames

Edit `flake.nix` and change the `hostname` field for each host to match your actual machine names.

### 3. Update Hardware Configuration

For each host, edit the hardware settings in `flake.nix`:
- Set correct `cpu` type (amd/intel)
- Set correct `gpu` type (amd/nvidia/intel)
- Adjust `hasSSD` and `isLaptop` flags

### 4. Configure Disks

Edit the disk configurations in `hosts/*/disks.nix`:
- Change device paths (`/dev/sda`, `/dev/nvme0n1`, etc.)
- Adjust partition sizes
- Modify filesystem types if needed

### 5. Update User Information

Edit user files in `users/`:
- Change usernames, full names, and emails
- Adjust user groups as needed
- Customize per-user settings

### 6. Enable/Disable Modules

Modify the `modules` section for each host to enable or disable features:
- `gaming = true` - Add Steam and gaming tools
- `virt = true` - Enable virtualization (libvirt, QEMU)
- `services = true` - Enable additional system services

## Adding More Hosts

To add a new host:

1. Create a new configuration in `flake.nix`:

```nix
newhostConfig = sharedConfig // {
  hostname = "newhost";
  hardware = { ... };
  userModulePath = ./users/newhost-user.nix;
  diskConfigPath = ./hosts/newhost/disks.nix;
};
```

2. Add to `nixosConfigurations`:

```nix
nixosConfigurations = {
  desktop = axios.lib.mkSystem desktopConfig;
  laptop = axios.lib.mkSystem laptopConfig;
  server = axios.lib.mkSystem serverConfig;
  newhost = axios.lib.mkSystem newhostConfig;  # Add this
};
```

3. Create user and disk configurations:

```bash
mkdir -p hosts/newhost
touch users/newhost-user.nix
touch hosts/newhost/disks.nix
```

## Version Management

### Update All Hosts

```bash
nix flake update
sudo nixos-rebuild switch --flake .#desktop
sudo nixos-rebuild switch --flake .#laptop
sudo nixos-rebuild switch --flake .#server
```

### Pin Specific Versions

You can pin different hosts to different axios versions:

```nix
inputs = {
  axios-stable.url = "github:kcalvelli/axios/v1.0.0";
  axios-latest.url = "github:kcalvelli/axios";
};

# Use different versions per host
desktopConfig = { ... };  # Uses axios-latest
serverConfig = { ... };   # Uses axios-stable for stability
```

## Benefits of Multi-Host Setup

- ✅ **Centralized management** - All configs in one repository
- ✅ **Shared configuration** - DRY principle for common settings
- ✅ **Per-host customization** - Easy to override for specific needs
- ✅ **Version control** - Track changes across all machines
- ✅ **Consistent environment** - Same tools and settings everywhere
- ✅ **Easy deployment** - Build and deploy from anywhere

## Tips

### Same User Across Hosts

If you use the same username across machines, you can create a shared user module:

```bash
# Create shared user config
touch users/shared-user.nix

# Reference it from multiple hosts
desktopConfig.userModulePath = ./users/shared-user.nix;
laptopConfig.userModulePath = ./users/shared-user.nix;
```

### Secrets Management

For managing secrets across hosts, consider using:
- [sops-nix](https://github.com/Mic92/sops-nix)
- [agenix](https://github.com/ryantm/agenix)

### Git Integration

```bash
git init
git add .
git commit -m "Initial multi-host configuration"

# Optional: Push to private repository
git remote add origin git@github.com:yourusername/nixos-config.git
git push -u origin main
```

## Documentation

- [axiOS Library Usage Guide](../../docs/LIBRARY_USAGE.md)
- [Adding Hosts Documentation](../../docs/ADDING_HOSTS.md)
- [Library API Reference](../../lib/README.md)

## Real-World Example

See [kcalvelli/nixos_config](https://github.com/kcalvelli/nixos_config) for a production multi-host setup using axiOS.
