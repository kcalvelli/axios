#!/usr/bin/env bash
# Format Nix files in the project
# Usage: ./scripts/fmt.sh [--check]
#
# This script provides AI-safe formatting commands that won't hang.
# It always operates on the current directory tree.

set -euo pipefail

# Navigate to project root
cd "$(git rev-parse --show-toplevel)"

if [[ "${1:-}" == "--check" ]]; then
  echo "🎨 Checking Nix formatting..."
  exec nix fmt -- --fail-on-change .
else
  echo "🎨 Formatting Nix files..."
  exec nix fmt .
fi
