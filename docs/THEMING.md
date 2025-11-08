# Desktop Theming

## Overview

axiOS uses [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) with [Niri compositor](https://github.com/YaLTeR/niri) to provide a cohesive Material Design-inspired desktop experience with automatic theming.

## DankMaterialShell Features

- Material Design-inspired theming
- Automatic color generation from wallpapers
- Dynamic application theming
- Custom keybindings and shortcuts
- Enhanced overview mode with visual effects

## Wallpaper Blur for Overview Mode

When you change wallpapers in DankMaterialShell, a blurred version is automatically created for Niri's overview background.

### How It Works

The Dank Hooks plugin automatically:
1. Detects when wallpaper changes
2. Generates a blurred version using ImageMagick
3. Saves it to `~/.cache/niri/overview-blur.jpg`
4. Displays it using `swaybg` as the overview background

The wallpaper blur script and plugin are automatically configured by axiOS. No manual setup required.

### Manual Testing

Test the wallpaper blur generation:

```bash
~/scripts/wallpaper-changed.sh "onWallpaperChanged" "/path/to/wallpaper.jpg"
```

### Troubleshooting

**Blurred background not appearing:**
1. Check that `~/.cache/niri/overview-blur.jpg` exists
2. Verify ImageMagick is installed: `which magick`
3. Check that swaybg is running: `ps aux | grep swaybg`
4. Monitor logs: `journalctl --user -u dms -f`

## Niri Overview Mode

To activate the overview mode and see the blurred background:
- Press `Super+Tab` (or your configured keybinding)
- The blurred wallpaper appears as the backdrop
- All windows are shown in a grid layout

## VSCode Theming

VSCode automatically receives a dynamic theme that matches your system colors:

1. Open the command palette with `Ctrl+Shift+P`
2. Choose **Preferences: Color Theme**
3. Select **Dynamic Base16 DankShell**

The theme updates automatically when you change wallpapers.

## Application Theming

For more information about how applications are themed in DankMaterialShell, see the [DankLinux documentation](https://danklinux.com/docs/dankmaterialshell/application-themes).

## Related Files

- `home/desktop/wallpaper.nix` - Wallpaper blur setup
- `home/desktop/niri.nix` - Niri compositor configuration
- `home/desktop/default.nix` - DankMaterialShell integration
- `home/desktop/theming.nix` - Theme configuration

## References

- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [Niri Compositor](https://github.com/YaLTeR/niri)
- [DankLinux Application Theming](https://danklinux.com/docs/dankmaterialshell/application-themes)


