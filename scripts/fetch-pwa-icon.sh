#!/usr/bin/env bash
# Fetch PWA icon from a website and convert to 128x128 PNG
# Usage: ./fetch-pwa-icon.sh <url> <output-name>
# Example: ./fetch-pwa-icon.sh https://excalidraw.com excalidraw

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <url> <output-name>"
    echo "Example: $0 https://excalidraw.com excalidraw"
    exit 1
fi

URL="$1"
OUTPUT_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../home/resources/pwa-icons"
OUTPUT_FILE="$OUTPUT_DIR/${OUTPUT_NAME}.png"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "🔍 Fetching $URL..."

# Fetch the HTML
HTML_FILE="$TEMP_DIR/page.html"
curl -sL -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "$URL" > "$HTML_FILE"

# Extract base URL for resolving relative paths
BASE_URL=$(echo "$URL" | sed -E 's|(https?://[^/]+).*|\1|')

# Function to resolve relative URLs
resolve_url() {
    local url="$1"
    if [[ "$url" =~ ^https?:// ]]; then
        echo "$url"
    elif [[ "$url" =~ ^// ]]; then
        echo "https:$url"
    elif [[ "$url" =~ ^/ ]]; then
        echo "${BASE_URL}${url}"
    else
        echo "${URL%/*}/${url}"
    fi
}

# Function to download and convert icon
download_icon() {
    local icon_url="$1"
    local temp_icon="$TEMP_DIR/icon_temp"

    echo "  📥 Downloading: $icon_url"

    if ! curl -sL -A "Mozilla/5.0" -o "$temp_icon" "$icon_url"; then
        echo "  ❌ Failed to download"
        return 1
    fi

    # Check if file is empty or too small (< 100 bytes likely indicates error)
    if [ ! -s "$temp_icon" ] || [ $(wc -c < "$temp_icon") -lt 100 ]; then
        echo "  ❌ Downloaded file is empty or too small"
        return 1
    fi

    # Try to detect file type from content (first few bytes)
    read -r -n 10 file_header < "$temp_icon"

    # Try direct conversion - let ImageMagick detect the format
    echo "  🎨 Converting to 128x128 PNG..."
    if command -v magick &> /dev/null; then
        if magick "$temp_icon" -resize 128x128 -gravity center -background white -extent 128x128 "$OUTPUT_FILE" 2>/dev/null; then
            return 0
        else
            echo "  ⚠️  ImageMagick conversion failed"
            return 1
        fi
    else
        echo "  ⚠️  ImageMagick is required for image conversion"
        return 1
    fi
}

# Strategy 1: Check for manifest.json (best for PWAs)
echo "🔎 Looking for web app manifest..."
MANIFEST_URL=$(grep -oP 'rel=["\x27]manifest["\x27]\s+href=["\x27]\K[^"'\'']+' "$HTML_FILE" | head -1 || true)
if [ -n "$MANIFEST_URL" ]; then
    MANIFEST_URL=$(resolve_url "$MANIFEST_URL")
    echo "  Found manifest: $MANIFEST_URL"

    # Get manifest base URL for resolving icon paths
    MANIFEST_BASE=$(echo "$MANIFEST_URL" | sed -E 's|(/[^/]+)$||')

    MANIFEST_FILE="$TEMP_DIR/manifest.json"
    if curl -sL "$MANIFEST_URL" -o "$MANIFEST_FILE"; then
        # Look for icons in manifest (prefer larger sizes)
        ICON_URL=$(jq -r '.icons[] | select(.sizes | contains("512") or contains("192")) | .src' "$MANIFEST_FILE" 2>/dev/null | head -1 || true)
        if [ -z "$ICON_URL" ] || [ "$ICON_URL" = "null" ]; then
            ICON_URL=$(jq -r '.icons[0].src // empty' "$MANIFEST_FILE" 2>/dev/null || true)
        fi

        if [ -n "$ICON_URL" ]; then
            # Resolve icon URL relative to manifest location
            if [[ "$ICON_URL" =~ ^https?:// ]]; then
                FULL_ICON_URL="$ICON_URL"
            elif [[ "$ICON_URL" =~ ^/ ]]; then
                FULL_ICON_URL="${BASE_URL}${ICON_URL}"
            else
                FULL_ICON_URL="${MANIFEST_BASE}/${ICON_URL}"
            fi

            if download_icon "$FULL_ICON_URL"; then
                echo "✅ Success! Icon saved to $OUTPUT_FILE"
                exit 0
            fi
        fi
    fi
fi

# Strategy 2: Apple touch icons (high quality)
echo "🔎 Looking for apple-touch-icon..."
APPLE_ICON=$(grep -oP 'rel=["\x27]apple-touch-icon[^"'\'']*["\x27]\s+href=["\x27]\K[^"'\'']+' "$HTML_FILE" | head -1 || true)
if [ -n "$APPLE_ICON" ]; then
    APPLE_ICON=$(resolve_url "$APPLE_ICON")
    if download_icon "$APPLE_ICON"; then
        echo "✅ Success! Icon saved to $OUTPUT_FILE"
        exit 0
    fi
fi

# Strategy 3: Open Graph image
echo "🔎 Looking for Open Graph image..."
OG_IMAGE=$(grep -oP 'property=["\x27]og:image["\x27]\s+content=["\x27]\K[^"'\'']+' "$HTML_FILE" | head -1 || true)
if [ -n "$OG_IMAGE" ]; then
    OG_IMAGE=$(resolve_url "$OG_IMAGE")
    if download_icon "$OG_IMAGE"; then
        echo "✅ Success! Icon saved to $OUTPUT_FILE"
        exit 0
    fi
fi

# Strategy 4: Standard favicon
echo "🔎 Looking for favicon..."
FAVICON=$(grep -oP 'rel=["\x27]icon["\x27]\s+href=["\x27]\K[^"'\'']+' "$HTML_FILE" | head -1 || true)
if [ -z "$FAVICON" ]; then
    # Try default /favicon.ico
    FAVICON="/favicon.ico"
fi

if [ -n "$FAVICON" ]; then
    FAVICON=$(resolve_url "$FAVICON")
    if download_icon "$FAVICON"; then
        echo "✅ Success! Icon saved to $OUTPUT_FILE"
        exit 0
    fi
fi

echo "❌ Failed to find suitable icon for $URL"
exit 1
