#!/usr/bin/env bash
# axiOS installer bootstrap
# Usage: bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/axios/master/scripts/install.sh)
set -euo pipefail

# Ensure wheel users are trusted by the nix daemon (needed for binary cache access).
# On a fresh NixOS install only root is trusted, so flake nixConfig substituters
# get silently ignored. NixOS makes /etc/nix/nix.conf a read-only symlink to the
# nix store, so we use nix.conf.d instead. After the first rebuild, axiOS's
# declarative nix config takes over.
if ! grep -q '@wheel' /etc/nix/nix.conf 2>/dev/null; then
  echo "Configuring nix trusted-users for binary cache access..."
  sudo mkdir -p /etc/nix/nix.conf.d
  echo "trusted-users = root @wheel" | sudo tee /etc/nix/nix.conf.d/axios-bootstrap.conf >/dev/null
  sudo systemctl restart nix-daemon 2>/dev/null || true
fi

exec nix --extra-experimental-features "nix-command flakes" run --refresh github:kcalvelli/axios#init -- "$@"
