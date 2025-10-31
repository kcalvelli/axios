#!/usr/bin/env bash
set -e

# Dank Hooks script for onWallpaperChanged
# Called with: $1 = hook name ("onWallpaperChanged"), $2 = wallpaper path
# 
# When wallpaper changes in DMS, matugen generates new theme colors.
# This script handles both wallpaper blur AND VSCode theme update.

HOOK_NAME="${1:-}"
WALLPAPER="${2:-}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper changed: $WALLPAPER"

# 1. Generate blurred wallpaper for Niri overview
CACHE_DIR="$HOME/.cache/niri"
BLURRED="$CACHE_DIR/overview-blur.jpg"

mkdir -p "$CACHE_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating blurred wallpaper..."
magick "$WALLPAPER" -filter Gaussian -blur 0x18 "$BLURRED"

# Kill any existing swaybg process
pkill swaybg || true
sleep 0.1

# Start swaybg with the blurred wallpaper
swaybg --mode stretch --image "$BLURRED" >/dev/null 2>&1 &

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper blur updated"

# 2. Update VSCode Material Code theme (matugen colors have changed)
if [ -d "$HOME/.config/material-code-theme" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updating VSCode Material Code theme..."
  cd "$HOME/.config/material-code-theme"
  bun run update-theme.ts >> "$HOME/.config/material-code-theme/theme-update.log" 2>&1 || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Material Code theme update failed"
  }
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Material Code theme directory not found, skipping"
fi

# 3. Reload Ghostty config with keys
wtype -M ctrl -M shift , -m shift -m ctrl

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper change handling complete"
