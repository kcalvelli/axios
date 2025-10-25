# axiOS Scripts

Utility scripts for axiOS framework desktop customization.

## Directory Structure

```
scripts/
├── shell/              # Shell scripts
│   ├── wallpaper-blur.sh
│   └── update-material-code-theme.sh
├── nix/                # Nix wrapper modules
│   └── wallpaper-scripts.nix
└── README.md           # This file
```

## Available Scripts

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

This script is automatically installed to `~/scripts/` by home-manager when you enable the desktop module.

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

This script is automatically installed to `~/scripts/` by home-manager when you enable the desktop module.

---

## Nix Integration Module

The `nix/` directory contains a Nix module that integrates shell scripts into the system:

### 🎨 wallpaper-scripts.nix

Manages wallpaper and theme scripts with:
- Script installation to `~/scripts/`
- ImageMagick dependencies
- Cache directory creation
- DankMaterialShell hook integration

**Imported by:** `home/desktops/common/wallpaper-blur.nix`

---

## For axiOS Library Users

If you're using axiOS as a library (recommended), these scripts are automatically available when you enable the desktop module:

```nix
# In your flake that uses axios
axios.lib.mkSystem {
  # ... other config ...
  modules.desktop = true;  # Scripts automatically installed
}
```

The scripts work automatically with DankMaterialShell and Niri. No manual setup needed.

---

## Notes

- Scripts are installed to `~/scripts/` in your home directory
- Scripts integrate with DankMaterialShell hooks automatically
- ImageMagick dependency is handled by the Nix module
- Scripts run without root privileges
