#!/usr/bin/env bash
set -e

# Dank Hooks script for onWallpaperChanged
# Called with: $1 = hook name ("onWallpaperChanged"), $2 = wallpaper path

HOOK_NAME="${1:-}"
WALLPAPER="${2:-}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper changed: $WALLPAPER"

# Generate blurred wallpaper for Niri overview
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

# Reload Ghostty config with keys
wtype -M ctrl -M shift , -m shift -m ctrl

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper change handling complete"
