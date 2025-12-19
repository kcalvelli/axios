#!/usr/bin/env nix-shell
#! nix-shell -i bash -p librsvg
#
# Extract Papirus icons for PWA apps
# Converts SVG to PNG at 128x128 resolution
# Only replaces icons where Papirus has a direct equivalent

set -uo pipefail

PAPIRUS_PATH=$(nix-build '<nixpkgs>' -A papirus-icon-theme --no-out-link 2>/dev/null)
PWA_ICONS_DIR="home/resources/pwa-icons"

# Icon mapping: PWA icon name -> Papirus icon name
# Only includes icons where Papirus has a direct, high-quality equivalent
declare -A ICON_MAP=(
    ["gmail"]="gmail"
    ["google-chat"]="google-chat"
    ["google-contacts"]="google-contacts"
    ["google-docs"]="google-docs"
    ["google-drive"]="google-drive"
    ["google-maps"]="google-maps"
    ["google-meet"]="google-meet"
    ["google-photos"]="google-photos"
    ["google-slides"]="google-slides"
    ["google-calendar"]="google-agenda"
    ["google-keep"]="keep"
    ["google-search"]="google"
    ["youtube"]="youtube"
    ["youtube-music"]="youtube-music"
    ["element"]="element-desktop"
    ["telegram"]="telegram"
    ["outlook"]="ms-outlook"
    ["teams"]="teams-for-linux"
    ["google-sheets"]="sheets"
    ["google-messages"]="android-messages-desktop"
)

echo "Extracting Papirus icons for PWA apps..."
echo "Papirus path: $PAPIRUS_PATH"
echo "Output directory: $PWA_ICONS_DIR"
echo

extracted_count=0
skipped_count=0

for pwa_name in "${!ICON_MAP[@]}"; do
    papirus_name="${ICON_MAP[$pwa_name]}"
    output_file="$PWA_ICONS_DIR/${pwa_name}.png"

    # Try to find the icon in different sizes (prefer larger for better quality)
    found=false
    for size in 128 96 64 48; do
        icon_path="$PAPIRUS_PATH/share/icons/Papirus/${size}x${size}/apps/${papirus_name}.svg"

        if [ -f "$icon_path" ]; then
            echo "Converting $pwa_name ($papirus_name) from ${size}x${size}..."

            # Convert SVG to PNG at 128x128
            if rsvg-convert -w 128 -h 128 "$icon_path" -o "$output_file" 2>&1; then
                if [ -f "$output_file" ]; then
                    echo "  ✓ Created $output_file"
                    ((extracted_count++))
                    found=true
                    break
                fi
            else
                echo "  ✗ Conversion failed for $pwa_name"
            fi
        fi
    done

    if [ "$found" = false ]; then
        echo "  ⚠ Icon not found for $pwa_name (searched for $papirus_name)"
        ((skipped_count++))
    fi
done

echo
echo "Done!"
echo "  Extracted: $extracted_count icons"
echo "  Skipped: $skipped_count icons (Papirus icon not found)"
echo
echo "Icons not in this script (keeping existing custom icons):"
echo "  - google-forms"
echo "  - google-classroom"
echo "  - google-voice"
echo "  - google-news"
echo "  - gemini"
echo "  - google-ai-studio"
echo "  - notebooklm"
echo "  - sonos"
