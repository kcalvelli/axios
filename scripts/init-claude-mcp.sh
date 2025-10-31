#!/usr/bin/env bash
# Initialize Claude CLI MCP configuration for a project
# Usage: init-claude-mcp.sh [project-directory]

set -euo pipefail

PROJECT_DIR="${1:-.}"
TEMPLATE="$HOME/.mcp.json.template"
TARGET="$PROJECT_DIR/.mcp.json"

if [ ! -f "$TEMPLATE" ]; then
    echo "Error: Template file not found at $TEMPLATE"
    echo "Make sure your Home Manager configuration is activated."
    exit 1
fi

if [ -f "$TARGET" ]; then
    echo "Warning: $TARGET already exists."
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

cp "$TEMPLATE" "$TARGET"
echo "✓ Created $TARGET"
echo ""
echo "MCP servers configured:"
echo "  - journal: System journal log access"
echo "  - mcp-nixos: NixOS package and option search"
echo "  - sequential-thinking: Enhanced reasoning"
echo "  - context7: Context management"
echo "  - filesystem: File access (/tmp and ~/Projects)"
echo ""
echo "Run 'claude mcp list' to verify the configuration."
