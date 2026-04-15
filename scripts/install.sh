#!/usr/bin/env bash
# Cairn installer bootstrap
# Usage: bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/cairn/master/scripts/install.sh)
set -euo pipefail

exec nix --extra-experimental-features "nix-command flakes" run --refresh github:kcalvelli/cairn#init -- "$@"
