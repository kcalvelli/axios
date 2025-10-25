# axiOS Scripts

Utility scripts for axiOS framework and desktop customization.

## Directory Structure

```
scripts/
├── shell/              # Shell scripts (*.sh)
│   ├── burn-iso.sh
│   ├── wallpaper-blur.sh
│   └── update-material-code-theme.sh
├── nix/                # Nix wrapper modules
│   ├── installer.nix
│   └── wallpaper-scripts.nix
└── README.md           # This file
```

## Available Scripts

### 🔥 burn-iso.sh

Burns the axiOS ISO to a USB drive.

**Usage:**
```bash
sudo ./shell/burn-iso.sh [device]
```

**Features:**
- Automatically builds ISO if not present
- Interactive device selection with safety checks
- Progress indication during write
- Optional data verification

**Examples:**
```bash
sudo ./shell/burn-iso.sh              # Interactive mode
sudo ./shell/burn-iso.sh /dev/sdb     # Direct device
sudo ./shell/burn-iso.sh sdb          # Auto-adds /dev/
```

**Requirements:**
- Root access (uses dd)
- USB drive (will be completely erased)

---

### 🎨 wallpaper-blur.sh

Generates blurred wallpaper for Niri overview mode.

**Usage:**
```bash
~/scripts/wallpaper-blur.sh
```

**What it does:**
- Takes current wallpaper
- Creates blurred version
- Saves to `~/.cache/niri/overview-blur.jpg`
- Used by DankMaterialShell hooks

**Requirements:**
- ImageMagick (automatically installed)
- Niri compositor
- Wallpaper set via `swaybg` or similar

This script is automatically installed to `~/scripts/` by home-manager.

---

### 🎨 update-material-code-theme.sh

Updates Material Code theme for Niri.

**Usage:**
```bash
~/scripts/update-material-code-theme.sh
```

**What it does:**
- Downloads latest Material Code theme
- Applies to Niri configuration
- Refreshes desktop appearance

This script is automatically installed to `~/scripts/` by home-manager.

---

## Nix Integration Modules

The `nix/` directory contains Nix modules that integrate shell scripts into the system:

### 📦 installer.nix

Configures the axiOS installer ISO with:
- Network tools (NetworkManager)
- Disk management utilities (disko, parted)
- Text editors (vim, nano)
- Git and development tools
- User-friendly shell environment

**Imported by:** `hosts/installer/default.nix`

### 🎨 wallpaper-scripts.nix

Manages wallpaper and theme scripts with:
- Script installation to `~/scripts/`
- ImageMagick dependencies
- Cache directory creation
- DankMaterialShell hook integration

**Imported by:** `home/desktops/common/wallpaper-blur.nix`

---

## For axiOS Framework Users

If you're using axiOS as a library (recommended), these scripts are automatically available:

- **wallpaper-blur.sh** and **update-material-code-theme.sh** are installed via home-manager
- Scripts work automatically with DankMaterialShell
- No manual setup needed

Just enable the desktop module in your configuration:

```nix
modules.desktop = true;
```

---

## Building the ISO

To build the axiOS installer ISO:

```bash
# From axios repository root
nix build .#iso

# Output location
ls -lh result/iso/*.iso

# Test in QEMU
qemu-system-x86_64 -cdrom result/iso/*.iso -m 4096 -enable-kvm

# Burn to USB
sudo ./scripts/shell/burn-iso.sh
```

The ISO includes:
- Standard NixOS installer tools
- Network configuration utilities
- Example configuration templates
- This README and documentation

---

## Safety Features

All scripts include:
- ✅ Input validation
- ✅ Confirmation prompts for destructive operations
- ✅ Error handling with clear messages
- ✅ Color-coded output for clarity

---

## Notes

- Most scripts run without root except `burn-iso.sh`
- Scripts use color-coded output (disable with `NO_COLOR=1`)
- Wallpaper scripts integrate with DankMaterialShell automatically
- ISO can be built on any system with Nix/NixOS
