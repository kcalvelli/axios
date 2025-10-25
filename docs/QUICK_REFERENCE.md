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

### Direct Installation

```bash
# Boot axiOS installer ISO
# Run automated installer
/root/install

# Or manual
git clone https://github.com/kcalvelli/axios /mnt/etc/nixos
cd /mnt/etc/nixos
sudo ./scripts/shell/install-axios.sh
```

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

**Library approach:**
```bash
cd ~/my-nixos-config

# Update axiOS and all inputs
nix flake update

# Update only axiOS
nix flake lock --update-input axios

# Check what changed
nix flake metadata axios

# Apply updates
sudo nixos-rebuild switch --flake .#<hostname>
```

**Direct installation:**
```bash
cd /etc/nixos

# Update all flake inputs
nix flake update

# Pull upstream changes (if tracking)
git fetch upstream
git merge upstream/master

# Rebuild
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

**Library approach:**
```bash
cd ~/my-nixos-config
$EDITOR flake.nix        # Edit host config
$EDITOR user.nix         # Edit user
$EDITOR hosts/myhost.nix # Edit specific host
```

**Direct installation:**
```bash
cd /etc/nixos
$EDITOR hosts/<hostname>.nix
$EDITOR modules/users/<user>.nix
```

### Add/Remove Packages

**Library approach - via extraConfig:**
```nix
# In your flake.nix
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

**Direct installation:**
```nix
# In modules/system/packages.nix or similar
environment.systemPackages = with pkgs; [
  firefox
  git
  htop
];
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

**Library approach:**
```nix
# In user.nix
home-manager.users.myuser = {
  home.packages = with pkgs; [
    firefox
    vscode
  ];
};
```

**Direct installation:**
```nix
# In modules/users/myuser.nix
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

### Library Approach Repository

```bash
cd ~/my-nixos-config

# Initialize git
git init
git add .
git commit -m "Initial commit"

# Push to remote
git remote add origin git@github.com:user/my-nixos.git
git push -u origin master

# Update from remote
git pull
```

### Direct Installation

```bash
cd /etc/nixos

# Commit changes
git add -A
git commit -m "Update configuration"

# Pull upstream updates
git fetch upstream
git merge upstream/master

# Push to your fork
git push origin master
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

### Aliases

Add to your user config:

```nix
programs.fish.shellAliases = {
  rebuild-switch = "sudo nixos-rebuild switch --flake /path/to/config#$(hostname)";
  rebuild-boot = "sudo nixos-rebuild boot --flake /path/to/config#$(hostname)";
  rebuild-test = "sudo nixos-rebuild test --flake /path/to/config#$(hostname)";
  update-flake = "nix flake update --flake /path/to/config";
};
```

## More Information

- [Library Usage Guide](LIBRARY_USAGE.md) - Complete library documentation
- [Installation Guide](INSTALLATION.md) - Detailed installation instructions
- [Adding Hosts](ADDING_HOSTS.md) - Multi-machine management
- [Package Organization](PACKAGES.md) - Understanding package structure
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official documentation
