#!/usr/bin/env bash
# Axios Build Validation Script
# Tests flake updates locally to catch breaking changes before merging

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AXIOS_DIR="${AXIOS_DIR:-$(pwd)}"
TEST_CLIENT_DIR="${TEST_CLIENT_DIR:-$HOME/.config/nixos_config}"
TEST_HOSTNAME="${TEST_HOSTNAME:-edge}"
LOG_DIR="/tmp/axios-test-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$LOG_DIR"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Axios Build Validation Test Suite   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in axios directory
cd "$AXIOS_DIR" 2>/dev/null || {
    echo -e "${RED}Error: Not in axios directory: $AXIOS_DIR${NC}"
    exit 1
}

if [ ! -f "flake.nix" ]; then
    echo -e "${RED}Error: flake.nix not found in $AXIOS_DIR${NC}"
    exit 1
fi

# Interactive mode: Choose what to test
echo -e "${BLUE}What would you like to test?${NC}"
echo ""
echo "  1) Current branch ($(git rev-parse --abbrev-ref HEAD))"
echo "  2) Open Pull Request"
echo "  3) Cancel"
echo ""
read -p "Enter choice [1-3]: " CHOICE

case $CHOICE in
    1)
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        echo ""
        echo -e "${GREEN}Testing current branch: $CURRENT_BRANCH${NC}"
        ;;
    2)
        echo ""
        echo -e "${BLUE}Fetching open pull requests...${NC}"
        
        # Check if gh is available
        if ! command -v gh &> /dev/null; then
            echo -e "${RED}Error: gh (GitHub CLI) not found${NC}"
            echo "Install with: nix-shell -p gh"
            exit 1
        fi
        
        # Get open PRs
        PR_LIST=$(gh pr list --repo kcalvelli/axios --json number,title,headRefName --limit 20 2>&1)
        
        if [ $? -ne 0 ] || [ -z "$PR_LIST" ] || [ "$PR_LIST" = "[]" ]; then
            echo -e "${YELLOW}No open pull requests found${NC}"
            exit 0
        fi
        
        # Display PRs
        echo ""
        echo -e "${BLUE}Open Pull Requests:${NC}"
        echo ""
        echo "$PR_LIST" | jq -r '.[] | "  \(.number)) #\(.number) - \(.title)"'
        echo ""
        read -p "Enter PR number to test: " PR_NUMBER
        
        if [ -z "$PR_NUMBER" ]; then
            echo -e "${YELLOW}No PR selected, exiting${NC}"
            exit 0
        fi
        
        # Checkout the PR
        echo ""
        echo -e "${BLUE}Checking out PR #$PR_NUMBER...${NC}"
        if ! gh pr checkout "$PR_NUMBER" 2>&1; then
            echo -e "${RED}Failed to checkout PR #$PR_NUMBER${NC}"
            exit 1
        fi
        
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        echo -e "${GREEN}✓ Checked out PR #$PR_NUMBER (branch: $CURRENT_BRANCH)${NC}"
        ;;
    3)
        echo ""
        echo -e "${YELLOW}Cancelled${NC}"
        exit 0
        ;;
    *)
        echo ""
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""

# Function to print test header
print_test() {
    echo ""
    echo -e "${BLUE}┌─────────────────────────────────────────${NC}"
    echo -e "${BLUE}│ $1${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

# Test 1: Verify we're in axios directory
print_test "Test 1: Verify Axios Repository"
cd "$AXIOS_DIR" 2>/dev/null || {
    print_error "Not in axios directory: $AXIOS_DIR"
    exit 1
}

if [ ! -f "flake.nix" ]; then
    print_error "flake.nix not found in $AXIOS_DIR"
    exit 1
fi

print_success "Found flake.nix in $AXIOS_DIR"
TESTS_PASSED=$((TESTS_PASSED + 1))

# Test 2: Check git status
print_test "Test 2: Git Repository Status"
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not a git repository"
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" = "master" ]; then
    echo -e "${BLUE}Testing master branch${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_success "On branch: $CURRENT_BRANCH"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# Show recent commits
echo ""
echo "Recent commits:"
git log --oneline -3

# Test 3: Flake structure validation
print_test "Test 3: Flake Structure Validation"
echo "Running: nix flake check --all-systems --no-update-lock-file"
if timeout 300 nix flake check --all-systems --no-update-lock-file 2>&1 | tee "$LOG_DIR/flake-check.log"; then
    print_success "Flake check passed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        print_error "Flake check timed out after 5 minutes"
    else
        print_error "Flake check failed - see $LOG_DIR/flake-check.log"
    fi
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 4: Show flake metadata
print_test "Test 4: Flake Metadata"
timeout 60 nix flake metadata 2>&1 | tee "$LOG_DIR/flake-metadata.log"
print_success "Flake metadata retrieved"
TESTS_PASSED=$((TESTS_PASSED + 1))

# Test 5: Check for major version changes
print_test "Test 5: Input Version Analysis"
if [ "$CURRENT_BRANCH" != "master" ]; then
    echo "Comparing flake.lock changes from master..."
    
    # Save current flake.lock
    cp flake.lock "$LOG_DIR/flake.lock.current"
    
    # Get master's flake.lock
    git show master:flake.lock > "$LOG_DIR/flake.lock.master" 2>/dev/null || {
        print_warning "Cannot compare with master (no master branch?)"
        TESTS_WARNED=$((TESTS_WARNED + 1))
    }
    
    if [ -f "$LOG_DIR/flake.lock.master" ]; then
        echo ""
        echo "Changed inputs:"
        
        # Check nixpkgs changes
        MASTER_NIXPKGS=$(jq -r '.nodes.nixpkgs.locked.rev // "unknown"' "$LOG_DIR/flake.lock.master")
        CURRENT_NIXPKGS=$(jq -r '.nodes.nixpkgs.locked.rev // "unknown"' "$LOG_DIR/flake.lock.current")
        
        if [ "$MASTER_NIXPKGS" != "$CURRENT_NIXPKGS" ]; then
            echo "  nixpkgs: ${MASTER_NIXPKGS:0:12} → ${CURRENT_NIXPKGS:0:12}"
            print_warning "Major input (nixpkgs) changed - test carefully"
            TESTS_WARNED=$((TESTS_WARNED + 1))
        fi
        
        # List all changed inputs
        echo ""
        echo "All input changes:"
        diff <(jq -r '.nodes | keys[]' "$LOG_DIR/flake.lock.master" | sort) \
             <(jq -r '.nodes | keys[]' "$LOG_DIR/flake.lock.current" | sort) \
             2>/dev/null | grep "^>" | sed 's/^> /  Added: /' || echo "  (none)"
        
        diff <(jq -r '.nodes | keys[]' "$LOG_DIR/flake.lock.master" | sort) \
             <(jq -r '.nodes | keys[]' "$LOG_DIR/flake.lock.current" | sort) \
             2>/dev/null | grep "^<" | sed 's/^< /  Removed: /' || echo ""
    fi
    
    print_success "Version analysis complete"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_warning "On master branch, skipping version comparison"
    TESTS_WARNED=$((TESTS_WARNED + 1))
fi

# Test 6: Test build in client configuration
print_test "Test 6: Client Configuration Build Test"
if [ ! -d "$TEST_CLIENT_DIR" ]; then
    print_warning "Test client directory not found: $TEST_CLIENT_DIR"
    print_warning "Skipping client build test"
    TESTS_WARNED=$((TESTS_WARNED + 1))
else
    echo "Testing with client config in: $TEST_CLIENT_DIR"
    
    cd "$TEST_CLIENT_DIR"
    
    # Backup current flake.lock
    if [ -f "flake.lock" ]; then
        cp flake.lock "$LOG_DIR/client-flake.lock.backup"
        echo "Backed up client flake.lock"
    fi
    
    # Update to use local axios
    echo ""
    echo "Updating client to use local axios: $AXIOS_DIR"
    nix flake lock --override-input axios "$AXIOS_DIR" 2>&1 | tee "$LOG_DIR/flake-lock-update.log" || {
        print_error "Failed to update flake.lock"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    }
    
    # Attempt build
    echo ""
    echo "Building client configuration..."
    echo "Command: nix build .#nixosConfigurations.$TEST_HOSTNAME.config.system.build.toplevel --print-out-paths"
    echo ""
    
    if timeout 600 nix build ".#nixosConfigurations.$TEST_HOSTNAME.config.system.build.toplevel" \
        --print-out-paths 2>&1 | tee "$LOG_DIR/build.log"; then
        print_success "Client configuration build SUCCEEDED"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  BUILD SUCCESS - SAFE TO MERGE!        ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    else
        print_error "Client configuration build FAILED"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        
        echo ""
        echo -e "${RED}╔════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  BUILD FAILED - DO NOT MERGE!          ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "Common issues to check:"
        echo "  1. Dependency version conflicts (check build.log for version mismatches)"
        echo "  2. Missing dependencies (look for 'not found' errors)"
        echo "  3. Upstream package breakage (check GitHub issues for affected packages)"
        echo ""
        echo "Build log saved to: $LOG_DIR/build.log"
        echo ""
        echo "To debug:"
        echo "  tail -50 $LOG_DIR/build.log"
        echo "  grep -i 'error\\|failed' $LOG_DIR/build.log"
    fi
    
    # Restore original flake.lock
    if [ -f "$LOG_DIR/client-flake.lock.backup" ]; then
        echo ""
        echo "Restoring original client flake.lock..."
        cp "$LOG_DIR/client-flake.lock.backup" flake.lock
        print_success "Restored client flake.lock"
    fi
    
    cd "$AXIOS_DIR"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          TEST SUMMARY                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "Tests Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Warnings:      ${YELLOW}$TESTS_WARNED${NC}"
echo ""
echo "Logs saved to: $LOG_DIR"
echo ""

# Exit code
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}❌ VALIDATION FAILED - DO NOT MERGE${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review build logs in $LOG_DIR"
    echo "  2. Check for upstream issues in affected packages"
    echo "  3. Consider waiting for upstream fixes"
    echo "  4. Test again after fixes are available"
    exit 1
else
    echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
    echo ""
    if [ $TESTS_WARNED -gt 0 ]; then
        echo -e "${YELLOW}⚠️  There were $TESTS_WARNED warnings - review them before merging${NC}"
        echo ""
    fi
    
    if [ "$CURRENT_BRANCH" = "master" ]; then
        echo "Master branch is working correctly."
        echo ""
        echo "To update your system with this version:"
        echo "  cd $TEST_CLIENT_DIR"
        echo "  nix flake update axios"
        echo "  sudo nixos-rebuild switch --flake .#$TEST_HOSTNAME"
    else
        echo "This PR is safe to merge!"
        echo ""
        echo "To merge:"
        echo "  gh pr merge --squash"
        echo ""
        echo "After merging, update your system:"
        echo "  cd $TEST_CLIENT_DIR"
        echo "  nix flake update axios"
        echo "  sudo nixos-rebuild switch --flake .#$TEST_HOSTNAME"
    fi
    exit 0
fi
