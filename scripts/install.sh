#!/usr/bin/env bash
# axiOS installer bootstrap
# Usage: bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/axios/master/scripts/install.sh)
set -euo pipefail

exec nix --extra-experimental-features "nix-command flakes" run --refresh github:kcalvelli/axios#init -- "$@"
