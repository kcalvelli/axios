#!/usr/bin/env bash
# axiOS installer bootstrap
# Usage: bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/axios/master/scripts/install.sh)
set -euo pipefail

# Ensure wheel users are trusted by the nix daemon (needed for binary cache access).
# On a fresh NixOS install only root is trusted, so flake nixConfig substituters
# get rejected. NixOS makes /etc/nix/nix.conf a read-only symlink to the nix store,
# so we replace the symlink with a writable copy and append trusted-users.
# After the first axiOS rebuild, NixOS regenerates nix.conf from declarative config.
if ! grep -q '@wheel' /etc/nix/nix.conf 2>/dev/null; then
  echo "Configuring nix trusted-users for binary cache access..."
  sudo cp --remove-destination "$(readlink -f /etc/nix/nix.conf)" /etc/nix/nix.conf
  echo "trusted-users = root @wheel" | sudo tee -a /etc/nix/nix.conf >/dev/null
  sudo systemctl restart nix-daemon
fi

exec nix --extra-experimental-features "nix-command flakes" run --refresh github:kcalvelli/axios#init -- "$@"
