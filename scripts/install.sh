#!/usr/bin/env bash
# axiOS installer bootstrap
# Usage: bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/axios/master/scripts/install.sh)
set -euo pipefail

echo "Note: The first build may take a while as packages are compiled from source."
echo "      After the first rebuild, axiOS configures binary caches for faster builds."
echo ""

exec nix --extra-experimental-features "nix-command flakes" run --refresh github:kcalvelli/axios#init -- "$@"
