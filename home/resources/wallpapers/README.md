# Wallpaper Collection (Maintainer Guide)

> **Note**: This document is for axiOS maintainers managing the wallpaper collection.
> **Users**: See the main [README.md](../../../README.md) for user-facing documentation.

This directory contains curated wallpapers that will be deployed to `~/Pictures/Wallpapers` on systems with wallpaper collection enabled.

## Adding/Removing/Updating Wallpapers

1. Place your wallpaper images (PNG, JPG, JPEG) in this directory
2. Wallpapers will automatically be deployed when `axios.wallpapers.enable = true` is set
3. Supported formats: PNG, JPG, JPEG

**When you change wallpapers in this directory:**
- Users will receive the updated collection when they rebuild after updating their axios flake input
- The system automatically detects changes via SHA256 hash of wallpaper filenames
- By default, a new random wallpaper will be set when the collection changes

## How It Works (For Maintainers)

When users enable `axios.wallpapers.enable = true`:
1. All wallpapers in this directory are deployed to `~/Pictures/Wallpapers`
2. Collection changes are detected via SHA256 hash of filenames
3. Hash stored in `~/.cache/axios-wallpaper-collection-hash`
4. Random wallpaper set when hash changes (controlled by `autoUpdate` option)

## Testing Changes

After adding/removing wallpapers:

```bash
# Format and validate
nix fmt .
nix flake check

# Commit and push
git add home/resources/wallpapers/
git commit -m "feat(wallpapers): Add/update wallpaper collection"
git push
```

Users will receive the updated collection on their next `nix flake update` and rebuild.
