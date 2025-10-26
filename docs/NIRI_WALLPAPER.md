# Niri with DankMaterialShell Integration

## Overview

This configuration uses [Niri](https://github.com/YaLTeR/niri), a scrollable-tiling Wayland compositor, with [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) for enhanced functionality and aesthetics.

## DankMaterialShell Features

DankMaterialShell provides:
- Material Design-inspired theming
- Custom keybindings and shortcuts
- Plugin system for extended functionality
- Enhanced overview mode with visual effects

## Wallpaper Blur for Overview Mode

### What It Does

Automatic wallpaper blur generation for Niri's overview mode using the **Dank Hooks** plugin. When you change wallpapers in DankMaterialShell, a blurred version is automatically created for the overview background.

### How It Works

The system uses the Dank Hooks plugin to automatically:
1. Detect when wallpaper changes (`onWallpaperChanged` hook)
2. Generate a blurred version using ImageMagick
3. Save it to `~/.cache/niri/overview-blur.jpg`
4. Display it using `swaybg` as the overview background

### Setup

**Scripts are automatically installed to `~/scripts/`:**
- `wallpaper-changed.sh` - Handles wallpaper blur + VSCode theme update

**Configure Dank Hooks plugin:**

Open DankMaterialShell settings → Dank Hooks plugin:

- **Wallpaper Changed**: `/home/keith/scripts/wallpaper-changed.sh`

When you change wallpaper in DMS, matugen generates new colors and this hook handles both blur generation and VSCode theme updates.

See `home/wayland.nix` for the wallpaper blur script configuration.

### Configuration

The wallpaper blur uses these settings:
- **Blur strength**: `0x18` (Gaussian blur with sigma 18)
- **Display mode**: `stretch` (fits to screen)
- **Cache location**: `~/.cache/niri/overview-blur.jpg`

### Manual Testing

Test the complete workflow:

```bash
# Test wallpaper change (includes blur + theme update)
~/scripts/wallpaper-changed.sh "onWallpaperChanged" "/path/to/wallpaper.jpg"
```

### Dependencies

All required dependencies are automatically installed:

**Hooks not triggering:**
1. Verify Dank Hooks plugin is enabled in DankMaterialShell
2. Check plugin settings have correct script paths
3. Monitor logs: `journalctl --user -u dankMaterialShell -f`

**Blurred background not appearing:**
1. Check that `~/.cache/niri/overview-blur.jpg` exists
2. Verify ImageMagick is installed: `which magick`
3. Test manually: `~/scripts/wallpaper-changed.sh "onWallpaperChanged" "/path/to/image.jpg"`
4. Check that swaybg is running: `ps aux | grep swaybg`

**Scripts not found:**
- Run `home-manager switch` to deploy scripts
- Check: `ls -la ~/scripts/`

## Niri Overview Mode

To activate the overview mode and see the blurred background:
- Default keybind is usually `Super+Tab` or configured in your keybindings
- The blurred wallpaper appears as the backdrop
- All windows are shown in a grid layout

## Related Files

- **Wallpaper hook**: Scripts installed to `~/scripts/wallpaper-changed.sh`
- **Configuration**: `home/wayland.nix` - Wallpaper blur setup
- **Niri config**: `home/niri.nix` - Keybindings and window rules
- **DankMaterialShell config**: `home/wayland.nix` - DMS integration

## References

- [Niri Compositor](https://github.com/YaLTeR/niri)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [swaybg](https://github.com/swaywm/swaybg)
- [ImageMagick](https://imagemagick.org/)

