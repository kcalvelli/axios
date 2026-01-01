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

# --- 1. Parse Arguments ---
PWA_URL_PRESET=""
ARG_OUTPUT_DIR=""

if [ $# -gt 0 ]; then
    if [[ "$1" =~ ^https?:// ]]; then
        PWA_URL_PRESET="$1"
        if [ $# -gt 1 ]; then
            ARG_OUTPUT_DIR="$2"
        fi
    else
        ARG_OUTPUT_DIR="$1"
    fi
fi

# --- 2. Detect Config File (Pre-scan) ---
# We need to find the config file early to check for existing iconPath
CONFIG_FILE=""
DETECTED_ROOT=""

# Check FLAKE_PATH environment variable
if [ -n "${FLAKE_PATH:-}" ] && [ -d "$FLAKE_PATH" ]; then
    DETECTED_ROOT="$FLAKE_PATH"
# Find git root with flake.nix
elif git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_ROOT=$(git rev-parse --show-toplevel)
    if [ -f "$GIT_ROOT/flake.nix" ]; then
        DETECTED_ROOT="$GIT_ROOT"
    fi
fi

# Fallback to common locations
if [ -z "$DETECTED_ROOT" ]; then
    if [ -d "$HOME/.config/nixos_config" ]; then
        DETECTED_ROOT="$HOME/.config/nixos_config"
    elif [ -d "$HOME/.dotfiles" ]; then
        DETECTED_ROOT="$HOME/.dotfiles"
    else
        DETECTED_ROOT="."
    fi
fi

# Try to find the specific config file (user.nix, home.nix, etc.)
if [ -n "$DETECTED_ROOT" ]; then
    FLAKE_FILE="$DETECTED_ROOT/flake.nix"
    
    # Strategy 1: Parse flake.nix for userModule definition
    if [ -f "$FLAKE_FILE" ]; then
        USER_MODULE=$(grep -oP 'userModule\s*=\s*self.outPath\s*\+\s*"\K[^"\n]+' "$FLAKE_FILE" | head -1 || true)
        if [ -z "$USER_MODULE" ]; then
            USER_MODULE=$(grep -oP 'userModule\s*=\s*\.\/\K[^;\n]+' "$FLAKE_FILE" | head -1 | tr -d ' "' || true)
        fi

        if [ -n "$USER_MODULE" ]; then
            USER_MODULE_FILE="${USER_MODULE#/}"
            if [ -f "$DETECTED_ROOT/$USER_MODULE_FILE" ]; then
                CONFIG_FILE="$DETECTED_ROOT/$USER_MODULE_FILE"
            fi
        fi
    fi

    # Strategy 2: Common naming patterns
    if [ -z "$CONFIG_FILE" ]; then
        if [ -f "$DETECTED_ROOT/home.nix" ]; then
            CONFIG_FILE="$DETECTED_ROOT/home.nix"
        elif [ -f "$DETECTED_ROOT/user.nix" ]; then
            CONFIG_FILE="$DETECTED_ROOT/user.nix"
        elif [ -f "$DETECTED_ROOT/${USER}.nix" ]; then
            CONFIG_FILE="$DETECTED_ROOT/${USER}.nix"
        elif [ -f "$DETECTED_ROOT/home-manager.nix" ]; then
            CONFIG_FILE="$DETECTED_ROOT/home-manager.nix"
        fi
    fi
fi

# --- 3. Determine Output Directory ---
OUTPUT_DIR=""
SKIP_DIR_PROMPT="no"

# Priority 1: Command line argument
if [ -n "$ARG_OUTPUT_DIR" ]; then
    OUTPUT_DIR="$ARG_OUTPUT_DIR"

# Priority 2: Extract from Config File
elif [ -n "$CONFIG_FILE" ]; then
    EXISTING_PATH=$(grep -oP 'iconPath\s*=\s*\.\/\K[^;\n]+' "$CONFIG_FILE" | head -1 | tr -d ' "' || true)
    if [ -n "$EXISTING_PATH" ]; then
        OUTPUT_DIR="$(dirname "$CONFIG_FILE")/$EXISTING_PATH"
        print_info "Detected existing iconPath in config: $EXISTING_PATH"
        SKIP_DIR_PROMPT="yes"
    fi
fi

# Priority 3: Fallback based on DETECTED_ROOT
if [ -z "$OUTPUT_DIR" ]; then
    if [ -n "$DETECTED_ROOT" ]; then
        OUTPUT_DIR="$DETECTED_ROOT/pwa-icons"
    else
        OUTPUT_DIR="./pwa-icons"
    fi
fi

print_header

echo "This helper will:"
echo "  1. Fetch a PWA icon from a website"
echo "  2. Generate the Nix configuration code"
echo "  3. Show you how to add it to your config"
echo ""

# Prompt for directory confirmation
if [ "$SKIP_DIR_PROMPT" = "yes" ]; then
    echo -e "Icons will be saved to: ${BLUE}$OUTPUT_DIR${NC} (from config)"
    echo ""
else
    echo -e "Icons will be saved to: ${BLUE}$OUTPUT_DIR${NC}"
    read -p "Press Enter to confirm, or type a different path: " CUSTOM_DIR
    if [ -n "$CUSTOM_DIR" ]; then
        OUTPUT_DIR="$CUSTOM_DIR"
        echo -e "Using custom path: ${BLUE}$OUTPUT_DIR${NC}"
    fi
    echo ""
fi

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

# Normalize URL: Ensure trailing slash for root domains to fix dock icons
# Brave generates startupWMClass differently for "https://x.com" vs "https://x.com/"
# If path is empty, append /
if [[ ! "$PWA_URL" =~ ^https?://[^/]+/.+ ]] && [[ ! "$PWA_URL" =~ /$ ]]; then
    PWA_URL="${PWA_URL}/"
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
MANIFEST_URL=$(grep -oP "rel=[\"']manifest[\"']\s+href=[\"']\K[^\"']+" "$HTML_FILE" | head -1 || true)

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
    
    # Sanitize and map categories to standard Freedesktop values
    MAPPED_CATS=""
    HAS_MAIN_CAT="no"
    
    for cat in $MANIFEST_CATEGORIES; do
        # Convert to lowercase for matching
        lcat=$(echo "$cat" | tr '[:upper:]' '[:lower:]')
        scat=""
        
        case "$lcat" in
            # Mapping common manifest categories to standard ones
            social|communication|chat) scat="Network;InstantMessaging"; HAS_MAIN_CAT="yes" ;;
            news|magazines) scat="News" ;;
            productivity|office|writing) scat="Office"; HAS_MAIN_CAT="yes" ;;
            video|movies|tv) scat="Video"; HAS_MAIN_CAT="yes" ;;
            audio|music|podcasts) scat="Audio"; HAS_MAIN_CAT="yes" ;;
            graphics|design|photo|photography) scat="Graphics"; HAS_MAIN_CAT="yes" ;;
            development|programming|code) scat="Development"; HAS_MAIN_CAT="yes" ;;
            education|learning|books) scat="Education"; HAS_MAIN_CAT="yes" ;;
            games) scat="Game"; HAS_MAIN_CAT="yes" ;;
            utilities|tools) scat="Utility"; HAS_MAIN_CAT="yes" ;;
            # Capitalize others as fallback (but they might still be invalid)
            *) scat="$(echo "${cat:0:1}" | tr '[:lower:]' '[:upper:]')${cat:1}" ;;
        esac
        
        if [ -n "$scat" ]; then
            if [ -n "$MAPPED_CATS" ]; then MAPPED_CATS="$MAPPED_CATS $scat"; else MAPPED_CATS="$scat"; fi
        fi
    done
    
    # Split by semicolon and spaces, unique them, and wrap in quotes
    FINAL_CATS=$(echo "$MAPPED_CATS" | tr ';' ' ' | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//')
    
    # Ensure at least one main category (Network is a safe default for PWAs)
    if [ "$HAS_MAIN_CAT" = "no" ]; then
        FINAL_CATS="Network $FINAL_CATS"
    fi
    
    CATEGORIES_ARRAY=$(echo "$FINAL_CATS" | sed 's/\([^ ]*\)/"\1"/g')
    CATEGORIES="[ $CATEGORIES_ARRAY ]"
    
    read -p "Press Enter to use standard categories $CATEGORIES or 'c' to customize: " CUSTOM_CHOICE
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
        ACTIONS_CODE="    actions = {"
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
        
                ACTIONS_CODE="    actions = {"
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

# Get relative path from config directory to icon directory
if [ -n "$CONFIG_FILE" ]; then
    REL_ICON_PATH=$(realpath --relative-to="$(dirname "$CONFIG_FILE")" "$OUTPUT_DIR" 2>/dev/null || echo "./pwa-icons")
    # Ensure relative paths start with ./ for Nix
    if [[ ! "$REL_ICON_PATH" =~ ^/ ]] && [[ ! "$REL_ICON_PATH" =~ ^\.\/ ]]; then
        REL_ICON_PATH="./$REL_ICON_PATH"
    fi
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
        categories = ${CATEGORIES};
${ACTIONS_CODE}
      };
    };
  };
}

${BLUE}Option 2: Create modular pwa.nix file${NC}
${YELLOW}Create: ${CONFIG_DIR:-.}/pwa.nix${NC}

{
  axios.pwa = {
    enable = true;
    iconPath = ${REL_ICON_PATH};
    extraApps = {
      ${PWA_ID} = {
        name = "${PWA_NAME}";
        url = "${PWA_URL}";
        icon = "${PWA_ID}";
        categories = ${CATEGORIES};
${ACTIONS_CODE}
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

# --- Auto-Update Feature ---
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Automatic Configuration Update${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Detect insertion point early for preview
    HAS_PWA_BLOCK=$(grep -q "axios\.pwa" "$CONFIG_FILE" && echo "yes" || echo "no")
    HAS_HM_BLOCK=$(grep -q "home-manager.users\." "$CONFIG_FILE" && echo "yes" || echo "no")
    
    TARGET_LINE=""
    # We used to try to be clever and insert after the last axios.pwa line, but that risks
    # inserting INSIDE a multi-line attribute set (e.g. inside extraApps.immich = { ... }).
    # Safe strategy: Always append to the end of the block.
    
    if [ "$HAS_HM_BLOCK" = "yes" ]; then
        TARGET_LINE=$(grep -n "};" "$CONFIG_FILE" | tail -n 1 | cut -d: -f1)
        INSERT_DESC="before the closing of your home-manager block (line $TARGET_LINE)"
    else
        TARGET_LINE=$(grep -n "}" "$CONFIG_FILE" | tail -n 1 | cut -d: -f1)
        INSERT_DESC="before the last closing brace (line $TARGET_LINE)"
    fi

    echo -e "I can attempt to automatically add this PWA to your config."
    echo -e "File: ${BLUE}$CONFIG_FILE${NC}"
    echo ""
    
    if [ -n "$TARGET_LINE" ]; then
        # Preview insertion point
        echo -e "${YELLOW}--- Preview of insertion point (around line $TARGET_LINE) ---${NC}"
        # Show 3 lines before target
        head -n $((TARGET_LINE - 1)) "$CONFIG_FILE" | tail -n 3
        echo -e "${GREEN}+ [ New PWA configuration will be inserted here ]${NC}"
        # Show the target line and one after
        sed -n "${TARGET_LINE},$((TARGET_LINE + 1))p" "$CONFIG_FILE"
        echo -e "${YELLOW}------------------------------------------------${NC}"
        echo -e "I will insert the configuration $INSERT_DESC."
    else
        echo -e "${RED}⚠️  Could not find a suitable insertion point in the file.${NC}"
    fi
    echo ""

    read -p "Would you like to update this file? [y/N]: " AUTO_UPDATE

    if [[ "$AUTO_UPDATE" =~ ^[Yy]$ ]]; then
        # Check if already exists
        if grep -q "extraApps.${PWA_ID}" "$CONFIG_FILE" || grep -q "\"${PWA_ID}\" =" "$CONFIG_FILE"; then
            print_info "PWA '${PWA_ID}' seems to already exist in the config. Skipping auto-update."
        else
            print_info "Updating configuration..."
            
            # Check for any axios.pwa definition (including dot notation like axios.pwa.enable)
            if grep -q "axios\.pwa" "$CONFIG_FILE"; then
                HAS_PWA_BLOCK="yes"
            else
                HAS_PWA_BLOCK="no"
            fi

            if [ "$HAS_PWA_BLOCK" = "yes" ]; then
                read -r -d '' INSERT_BLOCK << EOM || true
  axios.pwa.extraApps.${PWA_ID} = {
    name = "${PWA_NAME}";
    url = "${PWA_URL}";
    icon = "${PWA_ID}";
    categories = ${CATEGORIES};
${ACTIONS_CODE}
  };
EOM
            else
                read -r -d '' INSERT_BLOCK << EOM || true

  # Generated PWA: ${PWA_NAME}
  axios.pwa.enable = lib.mkDefault true;
  axios.pwa.iconPath = lib.mkDefault ${REL_ICON_PATH};
  axios.pwa.extraApps.${PWA_ID} = {
    name = "${PWA_NAME}";
    url = "${PWA_URL}";
    icon = "${PWA_ID}";
    categories = ${CATEGORIES};
${ACTIONS_CODE}
  };
EOM
            fi

            if [ -n "$TARGET_LINE" ]; then
                TEMP_CONF=$(mktemp)
                head -n $((TARGET_LINE - 1)) "$CONFIG_FILE" > "$TEMP_CONF"
                echo "$INSERT_BLOCK" >> "$TEMP_CONF"
                tail -n +$TARGET_LINE "$CONFIG_FILE" >> "$TEMP_CONF"
                cp "$TEMP_CONF" "$CONFIG_FILE"
                rm "$TEMP_CONF"
                print_success "Configuration updated successfully!"
                
                # Try to format the file if nix fmt is available
                if command -v nix &> /dev/null; then
                     print_info "Formatting configuration..."
                     if ! nix fmt "$CONFIG_FILE" >/dev/null 2>&1; then
                         # Fallback: Use standard nixfmt from nixpkgs
                         print_info "Local formatter not found, using nixpkgs#nixfmt-rfc-style..."
                         nix run nixpkgs#nixfmt-rfc-style -- "$CONFIG_FILE" >/dev/null 2>&1 || true
                     fi
                fi
                
                # Check if we are in a git repo and the file is untracked
                if git -C "$(dirname "$CONFIG_FILE")" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                    echo ""
                    print_info "IMPORTANT: You are in a Git repository."
                    print_info "You must add the new icon file for Nix to see it:"
                    echo -e "  ${BLUE}git add ${OUTPUT_DIR}/${PWA_ID}.png${NC}"
                    if [ "$HAS_PWA_BLOCK" != "yes" ]; then
                         # If we added a new directory reference (iconPath), remind to add that too if it's new
                         echo -e "  ${BLUE}git add ${OUTPUT_DIR}${NC}"
                    fi
                fi

                print_info "Don't forget to rebuild: ${BLUE}sudo nixos-rebuild switch --flake .${NC}"
            else
                print_error "Could not find a suitable insertion point in the file."
            fi
        fi
    fi
    echo ""
fi
# --- End Auto-Update ---