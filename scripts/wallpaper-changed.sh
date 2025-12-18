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

# Reload Neovim colorscheme (optional - manual reload also works)
if command -v nvim &> /dev/null; then
  for NVIM_ADDR in /tmp/nvim.*.0; do
    if [ -S "$NVIM_ADDR" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Reloading nvim colorscheme at $NVIM_ADDR"
      nvim --server "$NVIM_ADDR" --remote-send ':colorscheme dankshell<CR>' 2>/dev/null || true
    fi
  done
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Neovim theme reload attempted"
END_TIME=$(date +%s%N)
TOTAL_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper change handling complete (total: ${TOTAL_TIME}ms)"
