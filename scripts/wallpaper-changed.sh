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

THEME_LOG="$HOME/.config/material-code-theme/theme-update.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper blur updated" | tee -a "$THEME_LOG"

# 2. Update VSCode Material Code theme (matugen colors have changed)
# Add a delay to give matugen time to finish updating colors
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting 2 seconds for matugen to finish..." | tee -a "$THEME_LOG"
sleep 2

if [ -d "$HOME/.config/material-code-theme" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updating VSCode Material Code theme..." | tee -a "$THEME_LOG"

  # Inline theme update logic
  (
    cd "$HOME/.config/material-code-theme"

    URL="https://github.com/rakibdev/material-code/releases/latest/download/npm.tgz"

    # Write package.json
    cat > package.json <<JSON
{
  "name": "material-code-theme",
  "version": "0.0.0",
  "type": "module",
  "dependencies": {
    "material-code": "$URL"
  }
}
JSON

    rm -f bun.lockb

    # Install deps
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing dependencies..." >> "$THEME_LOG"
    bun install >> "$THEME_LOG" 2>&1

    # Copy TS out of Nix store
    src="$(readlink -f update-theme.ts || echo update-theme.ts)"
    cp -f "$src" ./update-theme.local.ts

    # Build theme
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating theme..." >> "$THEME_LOG"
    bun --bun run ./update-theme.local.ts >> "$THEME_LOG" 2>&1

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Material Code theme update complete" >> "$THEME_LOG"
  ) || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Material Code theme update failed" | tee -a "$THEME_LOG"
  }
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Material Code theme directory not found, skipping" | tee -a "$THEME_LOG"
fi

# 3. Reload Ghostty config with keys
wtype -M ctrl -M shift , -m shift -m ctrl

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Wallpaper change handling complete"
