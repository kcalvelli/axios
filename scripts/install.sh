#!/usr/bin/env bash
# axiOS installer bootstrap
# Usage: bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/axios/master/scripts/install.sh)
set -euo pipefail

# Ensure wheel users are trusted by the nix daemon (needed for binary cache access).
# On a fresh NixOS install only root is trusted, so flake nixConfig substituters
# get silently ignored. After the first rebuild, axiOS's declarative nix config
# takes over and /etc/nix/nix.conf is regenerated.
if ! grep -q '@wheel' /etc/nix/nix.conf 2>/dev/null; then
  echo "Adding @wheel to nix trusted-users (needed for binary cache access)..."
  sudo sh -c 'echo "trusted-users = root @wheel" >> /etc/nix/nix.conf'
  sudo systemctl restart nix-daemon 2>/dev/null || true
fi

exec nix --extra-experimental-features "nix-command flakes" run --refresh github:kcalvelli/axios#init -- "$@"
