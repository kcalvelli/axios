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

**You must have NixOS already installed.** axiOS configures existing NixOS systems — it does not replace the NixOS installer.

**IMPORTANT: axiOS requires UEFI boot mode.** BIOS/MBR systems are not supported.

If you haven't installed NixOS yet:

1. Download the **NixOS Graphical Installer** from [nixos.org/download](https://nixos.org/download#nixos-iso)
   - The graphical ISO is recommended — it provides a desktop environment with a guided installer that handles partitioning, formatting, and base system setup
2. **Boot in UEFI mode** (not BIOS/Legacy)
   - Physical machines: enable UEFI in firmware settings
   - VMs: enable EFI in VM settings before installation
3. Complete the installation and reboot into your new NixOS system
4. Return here to install axiOS

## Install

### Fresh NixOS Install

On your **existing NixOS system**, run:

```bash
bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/axios/master/scripts/install.sh)
```

This bootstrap script handles everything automatically:
- Enables flakes (if not already configured)
- Configures binary caches for faster builds
- Launches the interactive installer

### Flakes Already Enabled

If you already have flakes configured:

```bash
nix run --refresh github:kcalvelli/axios#init
```

### Installer Modes

The installer offers three modes:

1. **New configuration** — Scripted setup that walks through hardware, users, and features
2. **Add host to existing config** — Clone your config repo (authenticates via GitHub CLI) and add a new host
3. **AI-assisted configuration** — Claude Code interactively guides you through setup

All modes generate a complete configuration in `~/.config/nixos_config/` and offer to rebuild your system when done.

---

## What the Installer Does

1. **Detects hardware** — CPU, GPU, form factor, SSD, timezone
2. **Collects configuration** — hostname, users, features (gaming, PIM, Immich, local LLM, secure boot, etc.)
3. **Generates files** in `~/.config/nixos_config/`:
   - `flake.nix` — Main flake configuration
   - `hosts/HOSTNAME.nix` — Host configuration with all selected features
   - `hosts/HOSTNAME/hardware.nix` — Copied from `nixos-generate-config`
   - `users/USERNAME.nix` — Per-user configuration
4. **Initializes git** and commits the configuration
5. **Offers to rebuild** — runs `nixos-rebuild switch` with the generated config

**No manual file editing required.**

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
    let
      mkHost = hostname: axios.lib.mkSystem (
        (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
          configDir = self.outPath;
        }
      );
    in
    {
      nixosConfigurations.myhost = mkHost "myhost";
    };
}
```

### Step 3: Create hosts/myhost.nix

```nix
{ lib, ... }:
{
  hostConfig = {
    hostname = "myhost";
    system = "x86_64-linux";
    formFactor = "desktop"; # or "laptop"

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
      # ai defaults to true (Claude Code, Gemini, MCP servers)
      secrets = false; # Enable for agenix secrets management
    };

    homeProfile = "workstation"; # or "laptop"
    hardwareConfigPath = ./myhost/hardware.nix;

    users = [ "myuser" ]; # References users/myuser.nix

    extraConfig = {
      # System timezone (required)
      axios.system.timeZone = "America/New_York";

      # Add any additional NixOS configuration here
      # environment.systemPackages = with pkgs; [ ... ];
    };
  };
}
```

### Step 4: Create users/myuser.nix

```nix
{ ... }:
{
  axios.users.users.myuser = {
    fullName = "My Full Name";
    email = "me@example.com";
    isAdmin = true;
  };

  # That's it! axiOS automatically:
  # - Creates the user account (isNormalUser = true)
  # - Assigns groups based on enabled modules (wheel, video, audio, etc.)
  # - Configures git (user.name and user.email)
  # - Sets up home-manager with stateVersion and FLAKE_PATH
}
```

### Step 5: Copy Hardware Configuration

```bash
mkdir -p hosts/myhost
cp /etc/nixos/hardware-configuration.nix hosts/myhost/hardware.nix
```

This file contains boot modules, kernel modules, filesystems, and swap configuration generated by `nixos-generate-config`.

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
- Flatpak support with one-click Flathub installer

✅ **Development Tools:**
- VSCode with extensions
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
- **AI Tools**: claude-code, gemini, antigravity, MCP servers
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

When you create a user with `axios.users.users.<name>`, the system automatically:

✅ **Creates standard directories** on first boot:
- Desktop, Documents, Downloads, Music, Pictures, Videos, Public, Templates
- Uses systemd-tmpfiles (idempotent, won't fail if they already exist)
- Owned by your user with correct permissions

✅ **Sets up FLAKE_PATH** environment variable:
- Points to `~/.config/nixos_config` by default
- Used by fish helper functions (rebuild-switch, update-flake, etc.)
- Customize in your `users/<name>.nix` if needed:
  ```nix
  {
    axios.users.users.alice = { ... };

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
