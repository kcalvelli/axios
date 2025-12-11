# Getting Started with axiOS

This guide shows you how to use axiOS as a library to build your NixOS configuration.

**Important**: axiOS is designed to be installed **on top of an existing NixOS installation**. Install NixOS first using the standard installer, then use axiOS to configure it.

## What You'll Create

A minimal configuration repository with just a few files:

```
~/.config/nixos_config/
├── flake.nix              # Your system configuration (~40 lines)
├── user.nix               # Your user account definition
├── hosts/
│   ├── hostname.nix       # Host-specific configuration
│   └── hostname/
│       └── disks.nix      # Disk/filesystem config (auto-generated)
├── README.md              # Personalized instructions
└── .gitignore             # Standard ignores
```

That's it! All modules, packages, and home-manager configs come from axios.

## Prerequisites

**You must have NixOS already installed** using the standard installer. axiOS configures existing NixOS systems, it does not replace the NixOS installer.

**IMPORTANT: axiOS requires UEFI boot mode.** BIOS/MBR systems are not supported.

If you haven't installed NixOS yet:
1. Download the [NixOS installer ISO](https://nixos.org/download)
2. **Boot in UEFI mode** (not BIOS/Legacy mode)
   - For VMs: Enable UEFI in VM settings before installation
   - For physical machines: Ensure UEFI boot is enabled in BIOS/firmware settings
3. Follow the [NixOS installation guide](https://nixos.org/manual/nixos/stable/#sec-installation)
   - The installer will create a `/boot` partition with vfat filesystem for EFI
4. Complete the installation and boot into your new NixOS system
5. Then return here to install axiOS

## Quick Start (Recommended)

### Using the Interactive Generator

On your **existing NixOS system**, run:

```bash
# Run the interactive generator
nix run --refresh --extra-experimental-features "nix-command flakes" github:kcalvelli/axios#init
```

> **Note:** The `--refresh` flag ensures you get the latest version of axios. Without it, Nix may use a cached flake.

The generator will:

1. **Ask you questions** about your system:
   - Hostname, username, email, timezone
   - Form factor (desktop/laptop/server)
   - Hardware (CPU/GPU vendors)
   - Optional modules (gaming, virtualization, AI, secrets)

2. **Generate files** in `~/.config/nixos_config/`:
   - `flake.nix` - Main flake configuration
   - `user.nix` - Your user account
   - `hosts/HOSTNAME.nix` - Host configuration
   - `hosts/HOSTNAME/disks.nix` - **Auto-extracted** from `/etc/nixos/hardware-configuration.nix`
   - `README.md` - Personalized next-steps guide

3. **Auto-extract disk configuration**:
   - Reads `/etc/nixos/hardware-configuration.nix` (created during NixOS installation)
   - Extracts filesystem mounts, boot config, and swap
   - Creates clean `disks.nix` with only disk-related configuration
   - **No manual copying required!**

Then just:
```bash
cd ~/.config/nixos_config
git init
git add .
git commit -m "Initial axiOS configuration"
sudo nixos-rebuild switch --flake .#HOSTNAME
```

**That's it!** Your system is now managed by axiOS.

---

## What Happens During Init

The `nix run .#init` script:

1. **Creates** `~/.config/nixos_config/` directory
2. **Prompts** for system configuration (hostname, user, hardware, etc.)
3. **Generates** configuration files from templates
4. **Extracts** disk configuration from `/etc/nixos/hardware-configuration.nix`:
   ```bash
   # Automatically extracts these sections:
   - boot.initrd.availableKernelModules
   - boot.kernelModules
   - fileSystems.* (all mount points)
   - swapDevices
   - hardware.cpu.*.updateMicrocode
   ```
5. **Creates** `hosts/HOSTNAME/disks.nix` with extracted config
6. **Shows** next steps

**No manual file editing required** - the disk configuration is automatically extracted from your existing NixOS installation.

---

## Applying Your Configuration

After running the init script:

```bash
# Navigate to your configuration
cd ~/.config/nixos_config

# Initialize git (optional but recommended)
git init
git add .
git commit -m "Initial axiOS configuration"

# Apply the configuration
sudo nixos-rebuild switch --flake .#HOSTNAME

# Log out and back in to activate home-manager changes
```

Your system is now managed by axiOS! 🎉

---

## Using Fish Shell Helpers

axiOS provides convenient fish functions for managing your system:

```bash
# Update flake inputs (axios and dependencies)
update-flake

# Rebuild and switch to new configuration
rebuild-switch

# Rebuild and activate on next boot
rebuild-boot

# Test new configuration without making it default
rebuild-test

# Navigate to your flake directory
flake-cd
```

These commands automatically use your configuration at `~/.config/nixos_config` (set via `FLAKE_PATH` environment variable).

---

## Manual Setup (Alternative)

If you prefer to create files manually instead of using the generator:

### Step 1: Create Configuration Directory

```bash
mkdir -p ~/.config/nixos_config
cd ~/.config/nixos_config
```

### Step 2: Create flake.nix

```nix
{
  description = "My NixOS Configuration";

  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs =
    {
      self,
      axios,
      nixpkgs,
      ...
    }:
    {
      nixosConfigurations.myhost = axios.lib.mkSystem {
        hostConfig = {
          hostname = "myhost";
          system = "x86_64-linux";
          formFactor = "desktop"; # or "laptop" or "server"

          hardware = {
            cpu = "amd"; # "amd" or "intel"
            gpu = "amd"; # "amd", "nvidia", or "intel"
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
            virt = false; # Enable for virtualization (libvirt/containers)
            gaming = false; # Enable for Steam and gaming tools
            ai = false; # Enable for AI tools (claude-code, copilot, etc.)
            secrets = false; # Enable for agenix secrets management
          };

          homeProfile = "workstation"; # or "laptop"
          userModulePath = self.outPath + "/user.nix";
          diskConfigPath = ./hosts/myhost/disks.nix;

          extraConfig = {
            # System timezone (required)
            axios.system.timeZone = "America/New_York";

            # Add any additional NixOS configuration here
            # environment.systemPackages = with pkgs; [ ... ];
          };
        };
      };
    };
}
```

### Step 3: Create user.nix

```nix
{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  username = "myuser";
  fullName = "My Full Name";
  email = "me@example.com";
in
{
  axios.user = {
    username = username;
    fullName = fullName;
    email = email;
    initialPassword = "changeme"; # Change on first login!

    groups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
  };
}
```

### Step 4: Extract Disk Configuration

```bash
# Create host directory
mkdir -p hosts/myhost

# Extract disk config from hardware-configuration.nix
# Copy filesystem, boot, and swap sections to hosts/myhost/disks.nix
```

Or manually create `hosts/myhost/disks.nix`:

```nix
# Disk configuration extracted from hardware-configuration.nix
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
  };

  swapDevices = [ ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
```

Find your actual UUIDs with:
```bash
lsblk -f
# or
blkid
```

### Step 5: Create hosts/myhost.nix

```nix
# Host: myhost (desktop)
{ lib, userModulePath, ... }:
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
      ai = false;
      secrets = false;
    };

    homeProfile = "workstation";
    userModulePath = userModulePath;
    diskConfigPath = ./myhost/disks.nix;

    extraConfig = {
      axios.system.timeZone = "America/New_York";
    };
  };
}
```

### Step 6: Apply Configuration

```bash
cd ~/.config/nixos_config
git init
git add .
git commit -m "Initial configuration"
sudo nixos-rebuild switch --flake .#myhost
```

---

## Updating Your System

### Update axiOS Framework

```bash
cd ~/.config/nixos_config
nix flake update
sudo nixos-rebuild switch --flake .#myhost
```

Or use the fish helper:
```bash
update-flake && rebuild-switch
```

### Update Only axios (Keep Other Inputs Locked)

```bash
nix flake lock --update-input axios
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

---

## What You Get

By using axios as a library, you automatically get:

✅ **Desktop Environment:**
- Niri compositor with DankMaterialShell
- Ghostty terminal
- Modern applications (Firefox, etc.)
- Flatpak support via GNOME Software

✅ **Development Tools:**
- VSCode with extensions
- Neovim (LazyVim)
- Git and development utilities
- Language-specific tooling

✅ **System Features:**
- Automatic hardware optimization for your CPU/GPU
- Power management (laptops)
- Secure boot support (Lanzaboote)
- Networking with NetworkManager + Tailscale
- Fish shell with helpful aliases

✅ **Home Manager:**
- Declarative user environment
- Dotfile management
- Application settings
- XDG user directories (optional)

✅ **Optional Modules:**
- **Gaming**: Steam, game launchers, performance tools
- **Virtualization**: Libvirt/QEMU, Podman containers
- **AI Tools**: claude-code, copilot-cli, MCP servers
- **Secrets**: agenix for encrypted secrets management

---

## Customization

### Override or Add Settings

Use `extraConfig` in your host configuration:

```nix
extraConfig = {
  # System timezone (required)
  axios.system.timeZone = "America/New_York";

  # Add extra packages
  environment.systemPackages = with pkgs; [
    htop
    neofetch
  ];

  # Enable SSH
  services.openssh.enable = true;

  # Override defaults
  services.xserver.enable = false;
};
```

### What You Get Automatically

When you create a user with `axios.user`, the system automatically:

✅ **Creates standard directories** on first boot:
- Desktop, Documents, Downloads, Music, Pictures, Videos, Public, Templates
- Uses systemd-tmpfiles (idempotent, won't fail if they already exist)
- Owned by your user with correct permissions

✅ **Sets up FLAKE_PATH** environment variable:
- Points to `~/.config/nixos_config` by default
- Used by fish helper functions (rebuild-switch, update-flake, etc.)
- Customize in your `user.nix` if needed:
  ```nix
  {
    axios.user = { ... };

    # Optional: customize FLAKE_PATH
    axios.home.flakePath = "/custom/path";
  }
  ```

### Add Your Own Modules

```nix
extraConfig = {
  imports = [
    ./my-custom-module.nix
    ./services.nix
  ];
};
```

### Disable Specific Features

```nix
modules = {
  system = true;
  desktop = true;
  development = true;
  gaming = false; # ✗ No gaming
  virt = false; # ✗ No virtualization
  ai = false; # ✗ No AI tools
};
```

---

## Managing Multiple Machines

See [ADDING_HOSTS.md](ADDING_HOSTS.md) for managing multiple hosts in one configuration.

---

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

### Fish Helpers Not Working

The helper functions (`rebuild-switch`, etc.) won't work until you:
1. Log out and back in (to load new environment)
2. Or restart your shell: `exec fish`

### Missing /etc/nixos/hardware-configuration.nix

This file is created during NixOS installation. If it's missing:
1. You may not have NixOS installed yet (install it first!)
2. Or run: `sudo nixos-generate-config` to generate it

### Disk Configuration Issues

Check your filesystem UUIDs:
```bash
lsblk -f
# or
blkid
```

Update `hosts/HOSTNAME/disks.nix` with correct UUIDs.

### BIOS/MBR Boot Mode (Not Supported)

**Error**: "systemd-boot cannot be installed on this system" or similar boot errors

**Cause**: axiOS requires UEFI boot mode and uses systemd-boot, which does not support BIOS/MBR systems.

**Solution**: Reinstall NixOS in UEFI mode:
1. For VMs: Enable UEFI/EFI in your VM settings (e.g., VMware: Firmware Type = EFI, VirtualBox: Enable EFI)
2. For physical machines: Enable UEFI boot in BIOS/firmware settings, disable Legacy/CSM mode
3. Reinstall NixOS ensuring UEFI boot
4. Verify after install: `/boot` should be mounted as vfat filesystem

Check boot mode:
```bash
# Should show files if UEFI
ls /sys/firmware/efi

# Should show vfat for /boot
lsblk -f | grep /boot
```

---

## Migration Guide: diskConfigPath → hardwareConfigPath

**For existing axiOS users:**

axiOS now supports `hardwareConfigPath` which includes the **full** `hardware-configuration.nix` (boot modules, kernel modules, filesystems, and swap). This fixes boot issues with VMs and other hardware that needs specific kernel modules.

### Why the Change?

The old `diskConfigPath` only extracted filesystems and swap, missing critical boot configuration like:
- `boot.initrd.availableKernelModules` (needed for VMs with VirtIO, exotic hardware)
- `boot.kernelModules` (KVM, hardware-specific modules)
- `hardware.cpu.*.updateMicrocode` settings

This caused emergency boot issues in VMs and some hardware configurations.

### Backward Compatibility

**Your existing config still works!** Both `diskConfigPath` and `hardwareConfigPath` are supported:

```nix
# OLD (still works, no changes needed)
diskConfigPath = ./hosts/hostname/disks.nix;

# NEW (recommended for new configs)
hardwareConfigPath = ./hosts/hostname/hardware.nix;
```

### How to Migrate (Optional)

If you want to switch to the new approach:

1. **Copy your full hardware config:**
   ```bash
   cp /etc/nixos/hardware-configuration.nix ~/.config/nixos_config/hosts/HOSTNAME/hardware.nix
   ```

2. **Update your host config:**
   ```nix
   # Change from:
   diskConfigPath = ./hosts/HOSTNAME/disks.nix;

   # To:
   hardwareConfigPath = ./hosts/HOSTNAME/hardware.nix;
   ```

3. **Remove old file (optional):**
   ```bash
   rm hosts/HOSTNAME/disks.nix
   ```

4. **Rebuild:**
   ```bash
   sudo nixos-rebuild switch --flake .#HOSTNAME
   ```

**No rush to migrate** - your existing config will continue working indefinitely.

---

## More Information

- [Library API Reference](LIBRARY_USAGE.md) - Complete documentation
- [Adding Hosts](ADDING_HOSTS.md) - Multi-machine management
- [Application Catalog](APPLICATIONS.md) - See what's included
- [Examples](../examples/) - Working examples

---

## Getting Help

- [GitHub Issues](https://github.com/kcalvelli/axios/issues)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Discourse](https://discourse.nixos.org/)
