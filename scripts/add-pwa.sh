#!/usr/bin/env bash
# Interactive helper for adding custom PWAs to user configurations
# Usage: ./add-pwa.sh [output-directory]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Use environment variable if set (for nix run), otherwise use local path
FETCH_SCRIPT="${FETCH_SCRIPT:-$SCRIPT_DIR/fetch-pwa-icon.sh}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  axiOS PWA Setup Helper${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Determine output directory
DETECTED_DIR=""
PWA_URL_PRESET=""

if [ $# -gt 0 ]; then
    if [[ "$1" =~ ^https?:// ]]; then
        PWA_URL_PRESET="$1"
        if [ $# -gt 1 ]; then
            OUTPUT_DIR="$2"
        fi
    else
        OUTPUT_DIR="$1"
    fi
fi

if [ -z "${OUTPUT_DIR:-}" ]; then
    # Strategy 1: Check FLAKE_PATH environment variable
    if [ -n "${FLAKE_PATH:-}" ] && [ -d "$FLAKE_PATH" ]; then
        DETECTED_DIR="$FLAKE_PATH/pwa-icons"
    # Strategy 2: Find git root with flake.nix
    elif git rev-parse --git-dir > /dev/null 2>&1; then
        GIT_ROOT=$(git rev-parse --show-toplevel)
        if [ -f "$GIT_ROOT/flake.nix" ]; then
            DETECTED_DIR="$GIT_ROOT/pwa-icons"
        fi
    fi

    # Strategy 3: Common config locations
    if [ -z "$DETECTED_DIR" ]; then
        if [ -d "$HOME/.config/nixos_config" ]; then
            DETECTED_DIR="$HOME/.config/nixos_config/pwa-icons"
        elif [ -d "$HOME/.dotfiles" ]; then
            DETECTED_DIR="$HOME/.dotfiles/pwa-icons"
        else
            DETECTED_DIR="./pwa-icons"
        fi
    fi

    OUTPUT_DIR="$DETECTED_DIR"
fi

print_header

echo "This helper will:"
echo "  1. Fetch a PWA icon from a website"
echo "  2. Generate the Nix configuration code"
echo "  3. Show you how to add it to your config"
echo ""

# Prompt for directory confirmation
echo -e "Icons will be saved to: ${BLUE}$OUTPUT_DIR${NC}"
read -p "Press Enter to confirm, or type a different path: " CUSTOM_DIR
if [ -n "$CUSTOM_DIR" ]; then
    OUTPUT_DIR="$CUSTOM_DIR"
    echo -e "Using custom path: ${BLUE}$OUTPUT_DIR${NC}"
fi
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get PWA URL from user
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PWA URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$PWA_URL_PRESET" ]; then
    echo "Using URL: $PWA_URL_PRESET"
    PWA_URL="$PWA_URL_PRESET"
else
    read -p "URL (e.g., 'https://github.com'): " PWA_URL
fi

# Validate URL
if [[ ! "$PWA_URL" =~ ^https?:// ]]; then
    print_error "Invalid URL. Must start with http:// or https://"
    exit 1
fi

# Fetch and parse manifest
echo ""
print_info "Fetching manifest from $PWA_URL..."
TEMP_DIR=$(mktemp -d)
HTML_FILE="$TEMP_DIR/page.html"
MANIFEST_FILE="$TEMP_DIR/manifest.json"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Get base URL for resolving paths
BASE_URL=$(echo "$PWA_URL" | sed -E 's|(https?://[^/]+).*|\1|')

# Fetch HTML
if ! curl -sL -A "Mozilla/5.0" "$PWA_URL" > "$HTML_FILE"; then
    print_error "Failed to fetch $PWA_URL"
    exit 1
fi

# Extract manifest URL
MANIFEST_URL=$(grep -oP 'rel=["\x27]manifest["\x27]\s+href=["\x27]\K[^"'\'']+' "$HTML_FILE" | head -1 || true)

MANIFEST_NAME=""
MANIFEST_SHORT_NAME=""
MANIFEST_CATEGORIES=""
MANIFEST_SHORTCUTS=""

if [ -n "$MANIFEST_URL" ]; then
    # Resolve manifest URL
    if [[ "$MANIFEST_URL" =~ ^https?:// ]]; then
        FULL_MANIFEST_URL="$MANIFEST_URL"
    elif [[ "$MANIFEST_URL" =~ ^/ ]]; then
        FULL_MANIFEST_URL="${BASE_URL}${MANIFEST_URL}"
    else
        FULL_MANIFEST_URL="${PWA_URL%/*}/${MANIFEST_URL}"
    fi

    print_success "Found manifest: $FULL_MANIFEST_URL"

    # Fetch manifest
    if curl -sL "$FULL_MANIFEST_URL" -o "$MANIFEST_FILE"; then
        # Extract metadata
        MANIFEST_NAME=$(jq -r '.name // empty' "$MANIFEST_FILE" 2>/dev/null || true)
        MANIFEST_SHORT_NAME=$(jq -r '.short_name // empty' "$MANIFEST_FILE" 2>/dev/null || true)
        MANIFEST_CATEGORIES=$(jq -r '.categories // [] | join(" ")' "$MANIFEST_FILE" 2>/dev/null || true)

        # Check for shortcuts
        SHORTCUTS_COUNT=$(jq '.shortcuts // [] | length' "$MANIFEST_FILE" 2>/dev/null || echo "0")
        if [ "$SHORTCUTS_COUNT" -gt 0 ]; then
            MANIFEST_SHORTCUTS="yes"
            print_info "Found $SHORTCUTS_COUNT desktop shortcuts in manifest"
        fi
    fi
else
    print_info "No manifest found, will use manual input"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PWA Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate default ID from manifest
DEFAULT_ID=""
if [ -n "$MANIFEST_SHORT_NAME" ]; then
    DEFAULT_ID=$(echo "$MANIFEST_SHORT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')
elif [ -n "$MANIFEST_NAME" ]; then
    DEFAULT_ID=$(echo "$MANIFEST_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')
fi

# PWA ID
if [ -n "$DEFAULT_ID" ]; then
    read -p "PWA identifier [${DEFAULT_ID}]: " PWA_ID_INPUT
    PWA_ID="${PWA_ID_INPUT:-$DEFAULT_ID}"
else
    read -p "PWA identifier (lowercase, dashes only, e.g., 'github'): " PWA_ID
fi

# Validate PWA ID
if [[ ! "$PWA_ID" =~ ^[a-z0-9-]+$ ]]; then
    print_error "Invalid PWA ID. Use only lowercase letters, numbers, and dashes."
    exit 1
fi

# Display name - use manifest or prompt
if [ -n "$MANIFEST_NAME" ]; then
    echo "Display name from manifest: $MANIFEST_NAME"
    read -p "Press Enter to use '$MANIFEST_NAME' or type a different name: " PWA_NAME
    PWA_NAME="${PWA_NAME:-$MANIFEST_NAME}"
elif [ -n "$MANIFEST_SHORT_NAME" ]; then
    echo "Display name from manifest: $MANIFEST_SHORT_NAME"
    read -p "Press Enter to use '$MANIFEST_SHORT_NAME' or type a different name: " PWA_NAME
    PWA_NAME="${PWA_NAME:-$MANIFEST_SHORT_NAME}"
else
    read -p "Display name (e.g., 'GitHub'): " PWA_NAME
fi

# Categories - use manifest or prompt
echo ""
if [ -n "$MANIFEST_CATEGORIES" ]; then
    echo "Categories from manifest: $MANIFEST_CATEGORIES"
    CATEGORIES_ARRAY=$(echo "$MANIFEST_CATEGORIES" | sed 's/\([^ ]*\)/"\1"/g')
    CATEGORIES="[ $CATEGORIES_ARRAY ]"
    read -p "Press Enter to use these categories or 'c' to customize: " CUSTOM_CHOICE
    if [[ "$CUSTOM_CHOICE" =~ ^[Cc]$ ]]; then
        MANIFEST_CATEGORIES=""  # Fall through to manual selection
    fi
fi

if [ -z "$MANIFEST_CATEGORIES" ]; then
    echo "Select category (or type custom):"
    echo "  1) Office"
    echo "  2) Network / Communication"
    echo "  3) Development"
    echo "  4) Graphics / Design"
    echo "  5) ProjectManagement"
    echo "  6) Custom"
    read -p "Choice [1-6]: " CATEGORY_CHOICE

    case "$CATEGORY_CHOICE" in
        1) CATEGORIES='[ "Office" ]' ;;
        2) CATEGORIES='[ "Network" ]' ;;
        3) CATEGORIES='[ "Development" ]' ;;
        4) CATEGORIES='[ "Graphics" "VectorGraphics" ]' ;;
        5) CATEGORIES='[ "Office" "ProjectManagement" ]' ;;
        6)
            read -p "Enter categories (space-separated, e.g., 'Network InstantMessaging'): " CUSTOM_CATS
            CATEGORIES="[ $(echo "$CUSTOM_CATS" | sed 's/\([^ ]*\)/"\1"/g' | sed 's/ / /g') ]"
            ;;
        *) CATEGORIES='[ "Network" ]' ;;
    esac
fi

# Desktop actions - use manifest shortcuts or prompt
echo ""
ACTIONS_CODE=""

if [ -n "$MANIFEST_SHORTCUTS" ]; then
    echo "Use manifest shortcuts for desktop actions?"
    read -p "[Y/n]: " USE_SHORTCUTS
    if [[ ! "$USE_SHORTCUTS" =~ ^[Nn]$ ]]; then
        # Parse shortcuts from manifest
        ACTIONS_CODE="        actions = {"
        SHORTCUTS_JSON=$(jq -c '.shortcuts // []' "$MANIFEST_FILE" 2>/dev/null)

        while IFS= read -r shortcut; do
            SC_NAME=$(echo "$shortcut" | jq -r '.name')
            SC_URL=$(echo "$shortcut" | jq -r '.url')

            # Generate action ID from name (lowercase, replace spaces with dashes)
            SC_ID=$(echo "$SC_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

            # Resolve shortcut URL (might be relative)
            if [[ "$SC_URL" =~ ^https?:// ]]; then
                FULL_SC_URL="$SC_URL"
            elif [[ "$SC_URL" =~ ^/ ]]; then
                FULL_SC_URL="${BASE_URL}${SC_URL}"
            else
                FULL_SC_URL="${PWA_URL%/*}/${SC_URL}"
            fi

            ACTIONS_CODE="$ACTIONS_CODE
          \"$SC_ID\" = {
            name = \"$SC_NAME\";
            url = \"$FULL_SC_URL\";
          };"
        done < <(echo "$SHORTCUTS_JSON" | jq -c '.[]')

        ACTIONS_CODE="$ACTIONS_CODE
        };"
    fi
fi

if [ -z "$ACTIONS_CODE" ]; then
    read -p "Add custom desktop actions (right-click menu)? [y/N]: " ADD_ACTIONS

    if [[ "$ADD_ACTIONS" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Desktop actions allow right-click menu entries."
        echo "Example: 'Compose' action opens Gmail compose window"
        echo ""
        read -p "Number of actions to add: " NUM_ACTIONS

        ACTIONS_CODE="        actions = {"
        for ((i=1; i<=NUM_ACTIONS; i++)); do
            echo ""
            echo "Action $i:"
            read -p "  Action ID (e.g., 'compose'): " ACTION_ID
            read -p "  Action name (e.g., 'Compose Email'): " ACTION_NAME
            read -p "  Action URL: " ACTION_URL

            ACTIONS_CODE="$ACTIONS_CODE
          \"$ACTION_ID\" = {
            name = \"$ACTION_NAME\";
            url = \"$ACTION_URL\";
          };"
        done
        ACTIONS_CODE="$ACTIONS_CODE
        };"
    fi
fi

# Fetch the icon
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fetching Icon"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run fetch script
# Pass TEMP_DIR as the output directory for the icon
if "$FETCH_SCRIPT" "$PWA_URL" "$PWA_ID" "$TEMP_DIR"; then
    # Move icon from temp dir to final output directory
    mv "$TEMP_DIR/${PWA_ID}.png" "$OUTPUT_DIR/"
    print_success "Icon saved to: $OUTPUT_DIR/${PWA_ID}.png"
else
    print_error "Failed to fetch icon automatically"
    echo ""
    print_info "You can manually add an icon later:"
    echo "  1. Save a 128x128 PNG icon as: $OUTPUT_DIR/${PWA_ID}.png"
    echo "  2. Or use: magick your-icon.svg -resize 128x128 $OUTPUT_DIR/${PWA_ID}.png"
    echo ""
    read -p "Continue anyway? [y/N]: " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Generate Nix code
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect config file location
CONFIG_FILE=""
CONFIG_DIR=$(dirname "$OUTPUT_DIR")
FLAKE_FILE="$CONFIG_DIR/flake.nix"

# Strategy 1: Parse flake.nix for userModule definition (most reliable)
if [ -f "$FLAKE_FILE" ]; then
    # Pattern 1: userModule = self.outPath + "/keith.nix";
    USER_MODULE=$(grep -oP 'userModule\s*=\s*self\.outPath\s*\+\s*"\K[^"]+' "$FLAKE_FILE" | head -1)

    # Pattern 2: userModule = ./keith.nix;
    if [ -z "$USER_MODULE" ]; then
        USER_MODULE=$(grep -oP 'userModule\s*=\s*\./\K[^;]+' "$FLAKE_FILE" | head -1 | tr -d ' "')
    fi

    if [ -n "$USER_MODULE" ]; then
        # Remove leading slash if present
        USER_MODULE_FILE="${USER_MODULE#/}"
        CONFIG_FILE="$CONFIG_DIR/$USER_MODULE_FILE"

        # Verify the file exists
        if [ ! -f "$CONFIG_FILE" ]; then
            print_info "Detected userModule=$USER_MODULE_FILE in flake.nix but file doesn't exist"
            CONFIG_FILE=""
        fi
    fi
fi

# Strategy 2: Fallback to common naming patterns
if [ -z "$CONFIG_FILE" ]; then
    if [ -f "$CONFIG_DIR/home.nix" ]; then
        CONFIG_FILE="$CONFIG_DIR/home.nix"
    elif [ -f "$CONFIG_DIR/user.nix" ]; then
        CONFIG_FILE="$CONFIG_DIR/user.nix"
    elif [ -f "$CONFIG_DIR/${USER}.nix" ]; then
        CONFIG_FILE="$CONFIG_DIR/${USER}.nix"
    elif [ -f "$CONFIG_DIR/home-manager.nix" ]; then
        CONFIG_FILE="$CONFIG_DIR/home-manager.nix"
    fi
fi

# Get relative path from config directory to icon directory
if [ -n "$CONFIG_FILE" ]; then
    REL_ICON_PATH=$(realpath --relative-to="$CONFIG_DIR" "$OUTPUT_DIR" 2>/dev/null || echo "./pwa-icons")
else
    REL_ICON_PATH="./pwa-icons"
fi

cat << EOF
${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}Configuration Generated${NC}
${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${BLUE}Option 1: Add to existing home-manager config${NC}
EOF

if [ -n "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Edit: ${CONFIG_FILE}${NC}"
else
    echo -e "${YELLOW}Edit your home-manager config file (home.nix, user.nix, ${USER}.nix, etc.)${NC}"
fi

cat << EOF

Add this configuration:

{
  axios.pwa = {
    enable = true;
    iconPath = ${REL_ICON_PATH};
    extraApps = {
      ${PWA_ID} = {
        name = "${PWA_NAME}";
        url = "${PWA_URL}";
        icon = "${PWA_ID}";
        categories = ${CATEGORIES};${ACTIONS_CODE}
      };
    };
  };
}

${BLUE}Option 2: Create modular pwa.nix file${NC}
${YELLOW}Create: ${CONFIG_DIR}/pwa.nix${NC}

{
  axios.pwa = {
    enable = true;
    iconPath = ${REL_ICON_PATH};
    extraApps = {
      ${PWA_ID} = {
        name = "${PWA_NAME}";
        url = "${PWA_URL}";
        icon = "${PWA_ID}";
        categories = ${CATEGORIES};${ACTIONS_CODE}
      };
    };
  };
}
EOF

if [ -n "$CONFIG_FILE" ]; then
cat << EOF

${YELLOW}Then add to imports in ${CONFIG_FILE}:${NC}

{
  imports = [
    ./pwa.nix
  ];
}
EOF
fi

cat << EOF

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${YELLOW}Next Steps${NC}
${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

1. ${BLUE}Choose Option 1 or Option 2${NC} above
2. ${BLUE}Rebuild your system:${NC}
   sudo nixos-rebuild switch --flake .#your-hostname
   ${YELLOW}(or)${NC} home-manager switch --flake .#your-username
3. ${BLUE}Launch your PWA${NC} from the application launcher!

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${YELLOW}Tips${NC}
${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

• ${BLUE}Add more PWAs:${NC} Extend the extraApps block
• ${BLUE}Disable defaults:${NC} Set includeDefaults = false
• ${BLUE}Documentation:${NC} See docs/PWA_GUIDE.md for examples

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

EOF

print_success "PWA configuration generated!"
echo ""
echo "Icon: $OUTPUT_DIR/${PWA_ID}.png"
if [ -n "$CONFIG_FILE" ]; then
    echo "Config: $CONFIG_FILE"
fi
echo ""
