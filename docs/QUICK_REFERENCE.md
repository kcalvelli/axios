# axiOS Quick Reference

Quick command reference for common tasks with axiOS.

## Getting Started

### Using axiOS as a Library (Recommended)

```bash
# Create your config repository
mkdir ~/my-nixos-config && cd ~/my-nixos-config

# Copy minimal example
cp -r /path/to/axios/examples/minimal-flake/* .

# Or start from scratch
cat > flake.nix << 'FLAKE'
{
  inputs.axios.url = "github:kcalvelli/axios";
  inputs.nixpkgs.follows = "axios/nixpkgs";
  
  outputs = { self, axios, ... }: {
    nixosConfigurations.myhost = axios.lib.mkSystem {
      hostname = "myhost";
      # ... configuration ...
    };
  };
}
FLAKE

# Build configuration
nix build .#nixosConfigurations.myhost.config.system.build.toplevel

# Install (from installer)
sudo nixos-install --flake .#myhost

# Switch (on existing system)
sudo nixos-rebuild switch --flake .#myhost
```

## Environment Setup

Set `FLAKE_PATH` to your config location for convenience:

```bash
# Set permanently (fish shell)
set -Ux FLAKE_PATH ~/my-nixos-config

# Or in bash/zsh (~/.bashrc or ~/.zshrc)
export FLAKE_PATH=~/my-nixos-config
```

This enables convenient aliases like `rebuild-switch`, `flake-cd`, etc.

## System Management

### Rebuild System

```bash
# Test configuration (doesn't activate)
sudo nixos-rebuild test --flake .#<hostname>

# Build configuration (creates result symlink)
sudo nixos-rebuild build --flake .#<hostname>

# Switch to new configuration
sudo nixos-rebuild switch --flake .#<hostname>

# Add to boot menu but don't switch now
sudo nixos-rebuild boot --flake .#<hostname>

# Dry run (show what would be built)
sudo nixos-rebuild dry-run --flake .#<hostname>
```

### Update System

```bash
cd ~/my-nixos-config  # Or wherever your config is

# Update axiOS and all inputs
nix flake update

# Update only axiOS
nix flake lock --update-input axios

# Check what changed
nix flake metadata axios

# Apply updates
sudo nixos-rebuild switch --flake .#<hostname>
```

### Rollback

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Boot into previous generation
sudo nixos-rebuild switch --rollback

# Or select at boot menu (shown during boot)
```

## Configuration

### Edit Configuration

```bash
cd ~/my-nixos-config  # Or wherever your config is
$EDITOR flake.nix     # Edit host config
$EDITOR user.nix      # Edit user
$EDITOR disks.nix     # Edit disk layout
```

### Add/Remove Packages

Add to your flake.nix via extraConfig:
```nix
axios.lib.mkSystem {
  # ... other config ...
  extraConfig = {
    environment.systemPackages = with pkgs; [
      firefox
      git
      htop
    ];
  };
}
```

Or add to your user.nix:
```nix
home-manager.users.myuser = {
  home.packages = with pkgs; [
    firefox
    vscode
  ];
};
```

### Test Configuration

```bash
# Check for syntax errors
nix flake check

# Build without switching
sudo nixos-rebuild build --flake .#<hostname>

# Eval a specific option
nix eval .#nixosConfigurations.<hostname>.config.networking.hostName

# Show what will be built
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --dry-run
```

## Development Shells

```bash
# Enter default shell
nix develop

# Enter specific shell
nix develop .#rust
nix develop .#zig
nix develop .#qml

# Show available shells
nix flake show | grep devShells

# Run command in shell without entering
nix develop .#rust --command cargo build
```

## Building ISOs

```bash
# Build installer ISO
nix build .#iso

# Output location
ls -lh result/iso/*.iso

# Test in QEMU
qemu-system-x86_64 -cdrom result/iso/*.iso -m 4096 -enable-kvm

# Burn to USB
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Package Management

### Search Packages

```bash
# Search nixpkgs
nix search nixpkgs <package>

# Show package info
nix search nixpkgs --json <package> | jq

# Search locally available
nix-env -qaP | grep <package>
```

### User Packages (Home Manager)

Add to your user.nix:
```nix
home-manager.users.myuser = {
  home.packages = with pkgs; [
    firefox
    vscode
  ];
};
```

## Disk Management

### View Disk Layout

```bash
# List disks
lsblk

# Show partitions
sudo fdisk -l

# Show filesystem usage
df -h

# Show disk UUID
ls -l /dev/disk/by-uuid/
```

### Disko Configuration

```nix
# Simple ext4 layout in disks.nix
{
  disko.devices.disk.main = {
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
}
```

## Flake Commands

### Update Flake

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input <input>

# Show flake metadata
nix flake metadata

# Show flake outputs
nix flake show
```

### Lock File

```bash
# Show what's locked
cat flake.lock | jq '.nodes.axios.locked'

# Pin to specific commit
nix flake lock --override-input axios github:kcalvelli/axios/<commit>

# Pin to branch
nix flake lock --override-input axios github:kcalvelli/axios/<branch>
```

## Garbage Collection

```bash
# Delete old generations
sudo nix-collect-garbage --delete-older-than 30d

# Delete specific generations
sudo nix-env --delete-generations 1 2 3 --profile /nix/var/nix/profiles/system

# Delete all old generations
sudo nix-collect-garbage --delete-old

# Optimize store
sudo nix-store --optimize

# Check store size
du -sh /nix/store
```

## Troubleshooting

### Boot Issues

```bash
# Boot into previous generation (at boot menu)
# Select older generation with arrow keys

# Or from running system
sudo nixos-rebuild switch --rollback

# Check boot entries
bootctl list

# Check systemd boot status
bootctl status
```

### Build Errors

```bash
# Show detailed error messages
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --show-trace

# Check for infinite recursion
nix-instantiate --eval --strict .#nixosConfigurations.<hostname> 2>&1 | less

# Verify flake syntax
nix flake check
```

### Network Issues

```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check status
systemctl status NetworkManager

# Connect to WiFi
nmtui

# Show connections
nmcli connection show

# Show devices
nmcli device status
```

## Git Operations

```bash
cd ~/my-nixos-config

# Initialize git
git init
git add .
git commit -m "Initial commit"

# Push to remote
git remote add origin git@github.com:user/my-nixos-config.git
git push -u origin main

# Update from remote
git pull

# Commit changes
git add -A
git commit -m "Update configuration"
git push
```

## Useful Queries

```bash
# Show current generation
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current

# Show installed packages
nix-env -q

# Show package dependencies
nix-store --query --references $(which firefox)

# Show package reverse dependencies
nix-store --query --referrers $(which firefox)

# Find which package provides a file
nix-locate <filename>
```

## Tips & Tricks

### Fast Rebuilds

```bash
# Use nom for prettier output
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel |& nom

# Parallel builds (in configuration.nix)
nix.settings.max-jobs = 8;
nix.settings.cores = 4;
```

### Shell Aliases

The fish shell configuration in axiOS includes convenient aliases that use the `FLAKE_PATH` environment variable:

- `rebuild-switch` - Switch to new configuration
- `rebuild-boot` - Add to boot menu
- `rebuild-test` - Test configuration
- `update-flake` - Update flake inputs
- `flake-cd` - Jump to your config directory

These work automatically when you set `FLAKE_PATH` (see Environment Setup above).

For other shells, add to your user.nix:
```nix
programs.bash.shellAliases = {
  rebuild-switch = "sudo nixos-rebuild switch --flake $FLAKE_PATH#$(hostname)";
  rebuild-boot = "sudo nixos-rebuild boot --flake $FLAKE_PATH#$(hostname)";
  update-flake = "cd $FLAKE_PATH && nix flake update";
};
```

## More Information

- [Library Usage Guide](LIBRARY_USAGE.md) - Complete library documentation
- [Installation Guide](INSTALLATION.md) - Detailed installation instructions
- [Adding Hosts](ADDING_HOSTS.md) - Multi-machine management
- [Package Organization](PACKAGES.md) - Understanding package structure
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official documentation
