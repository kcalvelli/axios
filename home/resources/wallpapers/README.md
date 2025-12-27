# Wallpaper Collection

This directory contains curated wallpapers that will be deployed to `~/Pictures/Wallpapers` on systems with wallpaper collection enabled.

## Adding/Removing/Updating Wallpapers

1. Place your wallpaper images (PNG, JPG, JPEG) in this directory
2. Wallpapers will automatically be deployed when `axios.wallpapers.enable = true` is set
3. Supported formats: PNG, JPG, JPEG

**When you change wallpapers in this directory:**
- Users will receive the updated collection when they rebuild after updating their axios flake input
- The system automatically detects changes via SHA256 hash of wallpaper filenames
- By default, a new random wallpaper will be set when the collection changes

## Usage

### Basic Configuration

```nix
# In your home-manager configuration
axios.wallpapers.enable = true;
```

### Advanced Configuration

```nix
# Enable wallpapers but don't auto-randomize on collection changes
axios.wallpapers = {
  enable = true;
  autoUpdate = false;  # Files still update, but active wallpaper doesn't change
};
```

## Behavior

When enabled, axiOS will:
- Copy all wallpapers to `~/Pictures/Wallpapers` (updates automatically on rebuild)
- Detect collection changes via hash tracking (`~/.cache/axios-wallpaper-collection-hash`)
- Set a random wallpaper when collection changes (if `autoUpdate = true`, default)
- Allow manual wallpaper selection via DMS
