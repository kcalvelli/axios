#!/usr/bin/env bash
set -e

# Dank Hooks script for onWallpaperChanged
# Called with: $1 = hook name ("onWallpaperChanged"), $2 = wallpaper path

HOOK_NAME="${1:-}"
WALLPAPER="${2:-}"
START_TIME=$(date +%s%N)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper changed: $WALLPAPER"

# Generate blurred wallpaper for Niri overview
CACHE_DIR="$HOME/.cache/niri"
BLURRED="$CACHE_DIR/overview-blur.jpg"

mkdir -p "$CACHE_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating blurred wallpaper..."
BLUR_START=$(date +%s%N)
magick "$WALLPAPER" -filter Gaussian -blur 0x18 "$BLURRED"
BLUR_END=$(date +%s%N)
BLUR_TIME=$(( (BLUR_END - BLUR_START) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Blur generation took ${BLUR_TIME}ms"

# Kill any existing swaybg process
pkill swaybg || true
sleep 0.1

# Start swaybg with the blurred wallpaper
swaybg --mode stretch --image "$BLURRED" >/dev/null 2>&1 &

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper blur updated"

# Reload Ghostty config with keys
wtype -M ctrl -M shift , -m shift -m ctrl

END_TIME=$(date +%s%N)
TOTAL_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper change handling complete (total: ${TOTAL_TIME}ms)"
