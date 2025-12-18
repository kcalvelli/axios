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
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper change handling complete"
