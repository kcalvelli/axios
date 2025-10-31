#!/usr/bin/env bash
# Setup user-scoped MCP servers for Claude CLI
# Run this manually after nixos-rebuild if activation doesn't trigger

set -euo pipefail

# Check if claude is available
if ! command -v claude &> /dev/null; then
  echo "Error: claude command not found"
  echo "Make sure the AI module is enabled and you've rebuilt your system."
  exit 1
fi

echo "Setting up user-scoped MCP servers for Claude CLI..."

# Function to add MCP server if it doesn't exist at user scope
add_mcp_server() {
  local name="$1"
  shift

  # Check if server already exists at user scope
  if claude mcp get "$name" -s user &> /dev/null 2>&1; then
    echo "  ✓ $name already configured"
  else
    echo "  + Adding $name..."
    # Run from /tmp to avoid project-specific behavior
    (cd /tmp && claude mcp add --transport stdio "$name" --scope user -- "$@") || {
      echo "  ✗ Failed to add $name"
      return 1
    }
  fi
}

# Get the mcp-journal path from current system
JOURNAL_PATH=$(nix-build '<nixpkgs>' -A mcp-journal 2>/dev/null || echo "/run/current-system/sw/bin/mcp-journal")

# Add all MCP servers at user scope
add_mcp_server journal \
  "$JOURNAL_PATH"

add_mcp_server mcp-nixos \
  nix run github:utensils/mcp-nixos --

add_mcp_server sequential-thinking \
  npx -y @modelcontextprotocol/server-sequential-thinking

add_mcp_server context7 \
  npx -y @upstash/context7-mcp

add_mcp_server filesystem \
  npx -y @modelcontextprotocol/server-filesystem /tmp "$HOME/Projects"

echo ""
echo "✓ Claude CLI MCP setup complete!"
echo ""
echo "Test it from any directory:"
echo "  cd ~"
echo "  claude mcp list"
