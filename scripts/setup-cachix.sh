#!/usr/bin/env bash
# Cachix Setup Helper Script

set -euo pipefail

echo "╔════════════════════════════════════════╗"
echo "║   Axios Cachix Setup Instructions     ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo "This script will guide you through setting up Cachix for axios."
echo ""

# Check if cachix is installed
if ! command -v cachix &> /dev/null; then
    echo "❌ Cachix CLI not found"
    echo ""
    echo "Install cachix:"
    echo "  nix-env -iA cachix -f https://cachix.org/api/v1/install"
    echo ""
    exit 1
fi

echo "✓ Cachix CLI found"
echo ""

# Step 1: Account
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Create Cachix Account"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Go to: https://cachix.org"
echo "2. Sign up (GitHub OAuth recommended)"
echo "3. Get your auth token from: https://app.cachix.org/personal-auth-token"
echo ""
read -p "Press Enter when you have your auth token..."
echo ""

# Step 2: Login
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Login to Cachix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Paste your auth token: " CACHIX_TOKEN
echo ""

if cachix authtoken "$CACHIX_TOKEN"; then
    echo "✓ Logged in successfully"
else
    echo "❌ Login failed"
    exit 1
fi
echo ""

# Step 3: Create cache
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Create 'axios' Cache"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will:"
echo "  - Create a public cache named 'axios'"
echo "  - Generate signing keypair"
echo "  - Show you the public key"
echo ""
read -p "Press Enter to continue..."
echo ""

if cachix generate-keypair axios; then
    echo ""
    echo "✓ Cache 'axios' created successfully"
else
    echo ""
    echo "⚠️  Cache might already exist, continuing..."
fi
echo ""

# Step 4: Get public key
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Get Public Key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Get your public key from:"
echo "  https://app.cachix.org/cache/axios"
echo ""
echo "Look for:"
echo "  Public Key: axios.cachix.org-1:XXXX..."
echo ""
read -p "Paste the FULL public key here: " PUBLIC_KEY
echo ""

# Save to file for later
echo "$PUBLIC_KEY" > /tmp/axios-cachix-public-key.txt
echo "✓ Public key saved to: /tmp/axios-cachix-public-key.txt"
echo ""

# Step 5: GitHub Secret
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Add GitHub Secret"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Add your auth token to GitHub:"
echo ""
echo "1. Go to: https://github.com/kcalvelli/axios/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Name: CACHIX_AUTH_TOKEN"
echo "4. Value: $CACHIX_TOKEN"
echo "5. Click 'Add secret'"
echo ""
read -p "Press Enter when done..."
echo ""

# Step 6: Update documentation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Update Configuration Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Update these files with your public key:"
echo ""
echo "1. docs/BINARY_CACHE.md"
echo "   Replace: axios.cachix.org-1:REPLACE_WITH_PUBLIC_KEY"
echo "   With: $PUBLIC_KEY"
echo ""
echo "2. modules/system/nix.nix"
echo "   Replace: axios.cachix.org-1:REPLACE_WITH_PUBLIC_KEY"
echo "   With: $PUBLIC_KEY"
echo ""
read -p "Press Enter when done..."
echo ""

# Step 7: Test
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 7: Test Push (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Want to test pushing to cache now? (y/n)"
read -p "> " TEST_PUSH

if [ "$TEST_PUSH" = "y" ] || [ "$TEST_PUSH" = "Y" ]; then
    echo ""
    echo "Building formatter to test..."
    nix build .#formatter
    
    echo ""
    echo "Pushing to cache..."
    cachix push axios ./result
    
    echo ""
    echo "✓ Test push successful!"
else
    echo ""
    echo "⚠️  Skipping test push"
    echo "   GitHub Actions will push automatically on next workflow run"
fi
echo ""

# Summary
echo "╔════════════════════════════════════════╗"
echo "║          SETUP COMPLETE!               ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "✓ Cache 'axios' created"
echo "✓ Public key: (saved to /tmp/axios-cachix-public-key.txt)"
echo "✓ GitHub secret ready"
echo ""
echo "Next steps:"
echo "  1. Commit and push the workflow changes"
echo "  2. Trigger a workflow run to populate cache"
echo "  3. Update README.md with cache usage instructions"
echo "  4. Tell users to add to their configs:"
echo ""
echo "     nix.settings.substituters = ["
echo "       \"https://cache.nixos.org\""
echo "       \"https://axios.cachix.org\""
echo "     ];"
echo "     nix.settings.trusted-public-keys = ["
echo "       \"cache.nixos.org-1:6NCHdD59X431kS1gBOk6429S9g0f1NXtv+FIsf8Xma0=\""
echo "       \"$PUBLIC_KEY\""
echo "     ];"
echo ""
echo "Cache dashboard: https://app.cachix.org/cache/axios"
echo ""
