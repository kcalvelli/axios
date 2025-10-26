# Getting Started with axiOS

This guide shows you how to use axiOS as a library to build your NixOS configuration.

## What You'll Create

A minimal configuration repository with just a few files:

```
my-nixos-config/
├── flake.nix       # ~40 lines - your system config
├── user.nix        # Your user definition
├── disks.nix       # Disk layout
└── README.md       # Optional
```

That's it! All modules, packages, and home-manager configs come from axios.

## Quick Start

### Step 1: Create Your Repository

```bash
mkdir ~/my-nixos-config
cd ~/my-nixos-config
```

### Step 2: Copy the Example

The fastest way to get started:

```bash
# Copy the minimal example from axios
git clone https://github.com/kcalvelli/axios /tmp/axios
cp -r /tmp/axios/examples/minimal-flake/* .
rm -rf /tmp/axios
```

Or create files manually (see below).

### Step 3: Customize for Your System

Edit `flake.nix`:
- Change `hostname` to your computer name
- Set `cpu` and `gpu` to match your hardware ("amd" or "intel"/"nvidia")
- Set `formFactor` to "laptop" or "desktop"
- Enable/disable modules as needed

Edit `user.nix`:
- Change `username`, `fullName`, and `email`
- Add/remove groups as needed

Edit `disks.nix`:
- Change `/dev/sda` to your actual disk device
- Adjust partition sizes if needed

### Step 4: Install or Rebuild

**From NixOS installer:**
```bash
sudo nixos-install --flake .#myhost
```

**On existing NixOS system:**
```bash
sudo nixos-rebuild switch --flake .#myhost
```

### Step 5: Initialize Git

```bash
git init
git add .
git commit -m "Initial NixOS configuration"
```

Optional: Push to your own GitHub/GitLab repository.

## Manual File Creation

If you prefer to create files manually:

### flake.nix

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
      formFactor = "desktop";  # or "laptop"
      
      hardware = {
        cpu = "amd";      # "amd" or "intel"
        gpu = "amd";      # "amd", "nvidia", or "intel"
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
      
      homeProfile = "workstation";  # or "laptop"
      userModulePath = self.outPath + "/user.nix";
      diskConfigPath = ./disks.nix;
      
      extraConfig = {
        # Add any additional NixOS options here
      };
    };
  };
}
```

### user.nix

```nix
{ self, config, ... }:
let
  username = "myuser";
  fullName = "My Full Name";
  email = "me@example.com";
in
{
  users.users.${username} = {
    isNormalUser = true;
    description = fullName;
    initialPassword = "changeme";  # Change on first login!
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
  };

  home-manager.users.${username} = {
    home = {
      stateVersion = "24.05";
      homeDirectory = "/home/${username}";
      username = username;
    };

    nixpkgs.config.allowUnfree = true;

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

### disks.nix

```nix
{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";  # Change to your disk!
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

## Installing NixOS

### Prerequisites

- Boot from NixOS installer ISO ([download](https://nixos.org/download))
- Internet connection
- Your configuration files ready

### Installation Steps

1. **Boot NixOS installer**

2. **Connect to network:**
   ```bash
   # WiFi
   nmtui
   
   # Verify connection
   ping -c 3 nixos.org
   ```

3. **Clone your configuration:**
   ```bash
   git clone https://github.com/yourusername/my-nixos-config /mnt/etc/nixos
   cd /mnt/etc/nixos
   ```

4. **Or create configuration on-the-fly:**
   ```bash
   mkdir -p /mnt/etc/nixos
   cd /mnt/etc/nixos
   # Create flake.nix, user.nix, disks.nix here
   ```

5. **Install:**
   ```bash
   sudo nixos-install --flake .#myhost
   ```

6. **Reboot:**
   ```bash
   reboot
   ```

7. **Login** with your username and initial password

8. **Change password:**
   ```bash
   passwd
   ```

9. **Set up environment (optional but recommended):**
   ```bash
   # For fish shell (default in axiOS)
   set -Ux FLAKE_PATH ~/my-nixos-config
   
   # For bash/zsh (add to ~/.bashrc or ~/.zshrc)
   echo 'export FLAKE_PATH=~/my-nixos-config' >> ~/.bashrc
   ```
   
   This enables convenient aliases like `rebuild-switch`, `flake-cd`, etc.

## Updating Your System

### Update axiOS Framework

```bash
cd ~/my-nixos-config  # Or wherever your config is
nix flake update
sudo nixos-rebuild switch --flake .#myhost
```

### Pin to Specific Version

For stability, pin to a specific axios version:

```nix
# In flake.nix
inputs.axios.url = "github:kcalvelli/axios/v1.0.0";  # Pin to tag
# or
inputs.axios.url = "github:kcalvelli/axios/<commit-sha>";  # Pin to commit
```

## Managing Multiple Machines

See [ADDING_HOSTS.md](ADDING_HOSTS.md) for managing multiple hosts in one configuration.

## What You Get

By using axios as a library, you automatically get:

✅ **Desktop Environment:**
- Niri compositor with Material Shell
- Ghostty terminal
- Modern applications

✅ **Development Tools:**
- VSCode, Neovim (LazyVim)
- Compilers and build tools
- Language servers
- Git, development utilities

✅ **System Features:**
- Hardware optimization for your CPU/GPU
- Power management (laptops)
- Secure boot support (Lanzaboote)
- Networking with NetworkManager

✅ **Home Manager:**
- Dotfile management
- User environment configuration
- Application settings

## Customization

### Override or Add Settings

Use `extraConfig` in your host configuration:

```nix
axios.lib.mkSystem {
  # ... your config ...
  
  extraConfig = {
    # Override time zone
    time.timeZone = "America/New_York";
    
    # Add extra packages
    environment.systemPackages = with pkgs; [
      htop
      neofetch
    ];
    
    # Enable SSH
    services.openssh.enable = true;
  };
}
```

### Add Your Own Modules

```nix
extraConfig = {
  imports = [
    ./my-custom-module.nix
  ];
};
```

### Disable Specific Features

```nix
modules = {
  system = true;
  desktop = true;
  development = true;
  gaming = false;      # ✗ No gaming
  virt = false;        # ✗ No virtualization
  services = false;    # ✗ No extra services
};
```

## Troubleshooting

### Build Errors

```bash
# Check for syntax errors
nix flake check

# Show detailed errors
nix build .#nixosConfigurations.myhost.config.system.build.toplevel --show-trace
```

### Can't Find axios

Make sure flake inputs are updated:
```bash
nix flake update
```

### Network Issues During Install

```bash
# Reconnect to WiFi
nmtui

# Test connection
ping -c 3 1.1.1.1
```

### Disk Not Found

Check your disk device:
```bash
lsblk
# Update disks.nix with correct device
```

## More Information

- [Library API Reference](LIBRARY_USAGE.md) - Complete documentation
- [Quick Reference](QUICK_REFERENCE.md) - Common commands
- [Adding Hosts](ADDING_HOSTS.md) - Multi-machine management
- [Examples](../examples/minimal-flake/) - Working example

## Getting Help

- [GitHub Issues](https://github.com/kcalvelli/axios/issues)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Discourse](https://discourse.nixos.org/)
