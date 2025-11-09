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

axiOS provides a wallpaper blur script that creates a blurred version of your wallpaper for Niri's overview background.

### Setup Instructions

To enable automatic wallpaper blur when changing wallpapers:

1. **Enable the DankHooks Plugin:**
   - Open DankMaterialShell settings
   - Navigate to **Plugins**
   - Find **Dank Hooks** and click **Enable**

2. **Configure the Wallpaper Hook:**
   - In the DankHooks plugin settings, find **Wallpaper Changed**
   - Set the hook path to: `~/scripts/wallpaper-changed.sh`
   - The script is automatically deployed to your home directory by axiOS

The hook will now automatically:
1. Detect when wallpaper changes
2. Generate a blurred version using ImageMagick
3. Save it to `~/.cache/niri/overview-blur.jpg`
4. Display it using `swaybg` as the overview background

### Manual Testing

Test the wallpaper blur generation:

```bash
~/scripts/wallpaper-changed.sh "onWallpaperChanged" "/path/to/wallpaper.jpg"
```

### Troubleshooting

**Blurred background not appearing:**
1. Verify DankHooks plugin is enabled in DMS settings
2. Check that the wallpaper hook path is correctly configured to `~/scripts/wallpaper-changed.sh`
3. Ensure `~/.cache/niri/overview-blur.jpg` exists after changing wallpapers
4. Verify ImageMagick is installed: `which magick`
5. Check that swaybg is running: `ps aux | grep swaybg`

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


