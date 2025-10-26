#!/usr/bin/env bash
set -euo pipefail

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updating Material Code theme..."

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
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installing dependencies..."
bun install

# Copy TS out of Nix store
src="$(readlink -f update-theme.ts || echo update-theme.ts)"
cp -f "$src" ./update-theme.local.ts

# Build theme
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating theme..."
bun --bun run ./update-theme.local.ts

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Material Code theme update complete"
