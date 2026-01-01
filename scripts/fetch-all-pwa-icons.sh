#!/usr/bin/env bash
# Fetch icons for all PWAs defined in pwa-defs.nix
# Usage: ./fetch-all-pwa-icons.sh [pwa-names...]
# If no PWA names provided, prompts for which ones to fetch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PWA_DEFS="$SCRIPT_DIR/../pkgs/pwa-apps/pwa-defs.nix"
FETCH_SCRIPT="$SCRIPT_DIR/fetch-pwa-icon.sh"

# Make fetch script executable
chmod +x "$FETCH_SCRIPT"

# Function to extract PWA list from pwa-defs.nix
get_pwa_list() {
    grep -E '^\s+[a-z-]+ = \{' "$PWA_DEFS" | sed -E 's/^\s+([a-z-]+) = \{/\1/'
}

# Function to extract URL for a PWA
get_pwa_url() {
    local pwa_name="$1"
    awk "/^  ${pwa_name} = \{/,/^  \}/" "$PWA_DEFS" | \
        grep 'url =' | \
        sed -E 's/.*url = "([^"]+)".*/\1/'
}

# If specific PWAs provided as arguments, use those
if [ $# -gt 0 ]; then
    PWAS_TO_FETCH=("$@")
else
    # Otherwise, show interactive selection
    echo "Available PWAs:"
    echo "==============="
    mapfile -t ALL_PWAS < <(get_pwa_list)

    for i in "${!ALL_PWAS[@]}"; do
        printf "%2d) %s\n" $((i+1)) "${ALL_PWAS[$i]}"
    done

    echo ""
    echo "Enter PWA names (space-separated) or 'all' for all PWAs:"
    read -r selection

    if [ "$selection" = "all" ]; then
        PWAS_TO_FETCH=("${ALL_PWAS[@]}")
    else
        read -ra PWAS_TO_FETCH <<< "$selection"
    fi
fi

# Fetch icons
echo ""
echo "Fetching icons for ${#PWAS_TO_FETCH[@]} PWA(s)..."
echo "================================================"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FAILED_PWAS=()
ICON_DIR="$SCRIPT_DIR/../home/resources/pwa-icons"

for pwa in "${PWAS_TO_FETCH[@]}"; do
    # Check if icon already exists
    if [ -f "$ICON_DIR/${pwa}.png" ]; then
        echo "⏭️  Skipping $pwa (icon already exists)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    URL=$(get_pwa_url "$pwa")

    if [ -z "$URL" ]; then
        echo "⚠️  PWA '$pwa' not found in pwa-defs.nix"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_PWAS+=("$pwa (not found)")
        continue
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Processing: $pwa"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if "$FETCH_SCRIPT" "$URL" "$pwa"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo ""
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_PWAS+=("$pwa")
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Success: $SUCCESS_COUNT"
echo "⏭️  Skipped: $SKIP_COUNT (already exist)"
echo "❌ Failed:  $FAIL_COUNT"

if [ $FAIL_COUNT -gt 0 ]; then
    echo ""
    echo "Failed PWAs:"
    for failed in "${FAILED_PWAS[@]}"; do
        echo "  - $failed"
    done
fi

exit 0
