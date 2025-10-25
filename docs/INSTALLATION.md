# Installing axiOS

This guide covers two ways to use axiOS: as a library (recommended) or via direct installation.

## Choose Your Approach

### Option 1: Use axiOS as a Library (Recommended)

**Best for:** Most users who want minimal maintenance and easy updates.

Create a minimal configuration that imports axiOS as a dependency. You maintain just a few files (~30 lines), and axiOS provides all the modules, packages, and home-manager configs.

**Advantages:**
- ✅ Minimal maintenance (just your personal configs)
- ✅ Easy updates (`nix flake update`)
- ✅ Version pinning for stability
- ✅ Your config repo is simple and understandable

See [Library Usage Guide](LIBRARY_USAGE.md) for complete instructions.

**Quick Start:**
```bash
mkdir ~/my-nixos-config
cd ~/my-nixos-config

# Copy the minimal example
nix flake init -t github:kcalvelli/axios#minimal
# Or manually copy from examples/minimal-flake/

# Customize flake.nix, user.nix, disks.nix
# Then install or rebuild
```

### Option 2: Direct Installation

**Best for:** Users who want complete control or to deeply customize the framework.

Clone the full axiOS repository and install it directly. You maintain the entire configuration.

**Advantages:**
- ✅ Complete control over all configuration
- ✅ Direct modification of any module
- ✅ Good for learning NixOS configuration structure
- ✅ Can contribute improvements back to axiOS

Continue with this guide for direct installation instructions.

---

## Direct Installation Guide

### Prerequisites

- axiOS installer ISO or standard NixOS installer
- Target machine with:
  - x86_64 CPU (AMD or Intel)
  - 4GB+ RAM (8GB+ recommended)
  - 20GB+ disk space (50GB+ recommended)
  - Internet connection

### Step 1: Get the Installer

#### Option A: axiOS Custom ISO (Recommended)

Download the latest ISO from [GitHub Releases](https://github.com/kcalvelli/axios/releases):

```bash
wget https://github.com/kcalvelli/axios/releases/latest/download/axios-installer-x86_64-linux.iso

# Verify checksum (optional)
sha256sum axios-installer-x86_64-linux.iso
```

#### Option B: Standard NixOS ISO

Download from [nixos.org](https://nixos.org/download):
- Minimal ISO: ~1GB, text-mode only
- Graphical ISO: ~3GB, includes GNOME desktop

### Step 2: Create Bootable USB

**Linux:**
```bash
# Find your USB device
lsblk

# Write ISO (replace /dev/sdX with your device)
sudo dd if=axios-installer-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

**macOS:**
```bash
diskutil list
sudo dd if=axios-installer-x86_64-linux.iso of=/dev/diskX bs=4m
```

**Windows:**
Use [Rufus](https://rufus.ie/) or [Etcher](https://www.balena.io/etcher/)

### Step 3: Boot from USB

1. Insert USB drive
2. Reboot and enter BIOS/UEFI (usually F2, F12, Del, or Esc)
3. Select USB drive as boot device
4. Boot into the installer

### Step 4: Automated Installation

If using the axiOS ISO, run the automated installer:

```bash
# From the installer environment
install
# or
/root/install
```

The installer will:
1. Detect your hardware (CPU, GPU, form factor)
2. Ask for disk configuration preference
3. Prompt for hostname and username
4. Ask which modules to enable (desktop, gaming, dev tools)
5. Set up passwords
6. Install the system
7. Configure for first boot

**Installation takes 15-30 minutes** depending on internet speed.

### Step 5: Manual Installation (Alternative)

If using a standard NixOS ISO or want more control:

```bash
# 1. Clone axiOS
git clone https://github.com/kcalvelli/axios /mnt/etc/nixos
cd /mnt/etc/nixos

# 2. Run the installer script
sudo ./scripts/shell/install-axios.sh

# 3. Or follow manual steps:
# - Create host config in hosts/
# - Configure disks with disko
# - Add user in modules/users/
# - Run: nixos-install --flake .#<hostname>
```

### Step 6: First Boot

1. Remove USB drive
2. Reboot
3. Login with the username and password you set
4. System will complete initial setup

### Step 7: Post-Installation

**Update the configuration:**
```bash
cd /etc/nixos
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git add -A
git commit -m "Initial installation on $(hostname)"
```

**Optional: Push to your own repository:**
```bash
# Create a new repo on GitHub/GitLab
git remote rename origin upstream
git remote add origin git@github.com:yourusername/my-nixos.git
git push -u origin master
```

**Configure Secure Boot (if desired):**
- See hardware manual for entering UEFI setup
- Enable Secure Boot
- Enroll keys generated during installation
- Reboot and verify with `bootctl status`

## Configuration Management

### After Direct Installation

Your configuration is in `/etc/nixos` as an independent git repository. You have several options:

**Option 1: Keep Independent**
- Maintain your own fork
- No upstream dependencies
- Full control

**Option 2: Track Upstream**
```bash
cd /etc/nixos
git remote add upstream https://github.com/kcalvelli/axios
git fetch upstream
git merge upstream/master  # When you want updates
```

**Option 3: Migrate to Library Approach**

Convert your direct installation to use axiOS as a library (recommended for easier maintenance):

1. Create new minimal config repository
2. Copy your `hosts/*.nix` and `modules/users/*.nix`
3. Create simple flake.nix using `axios.lib.mkSystem`
4. Test the new configuration
5. Switch to it with `nixos-rebuild`

See [LIBRARY_USAGE.md](LIBRARY_USAGE.md) for migration instructions.

## Updating the System

### Direct Installation Updates

```bash
cd /etc/nixos

# Update flake inputs
nix flake update

# Rebuild and switch
sudo nixos-rebuild switch --flake .#$(hostname)
```

### Pull Upstream Changes (if tracking)

```bash
cd /etc/nixos
git fetch upstream
git merge upstream/master
nix flake update
sudo nixos-rebuild switch --flake .#$(hostname)
```

## Adding Hosts

See [ADDING_HOSTS.md](ADDING_HOSTS.md) for managing multiple machines.

## Troubleshooting

### Installation Fails

**Check hardware compatibility:**
```bash
# Verify CPU
lscpu | grep "Model name"

# Verify disk
lsblk

# Check network
ip addr
```

**Boot issues:**
- Verify UEFI vs BIOS mode matches installation
- Check Secure Boot is disabled during install
- Ensure USB drive was written correctly

**Disk errors:**
- Verify disk device path in configuration
- Check disk has no existing partitions
- Ensure disk is not mounted during partitioning

### System Won't Boot

1. Boot from USB again
2. Mount your installation:
   ```bash
   mount /dev/disk/by-label/nixos /mnt
   mount /dev/disk/by-label/boot /mnt/boot
   ```
3. Enter the system:
   ```bash
   nixos-enter --root /mnt
   ```
4. Fix configuration and rebuild:
   ```bash
   cd /etc/nixos
   nixos-rebuild switch --flake .#$(hostname)
   ```

### Need Help?

- [GitHub Issues](https://github.com/kcalvelli/axios/issues)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Discourse](https://discourse.nixos.org/)

## Next Steps

- [Quick Reference](QUICK_REFERENCE.md) - Common commands
- [Adding Hosts](ADDING_HOSTS.md) - Multi-machine management
- [Package Reference](PACKAGES.md) - Understanding package organization
- [Library Usage](LIBRARY_USAGE.md) - Use axios as a library (recommended)
