#!/usr/bin/env bash
# Axios PR Validation Script
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
echo -e "${BLUE}║   Axios PR Validation Test Suite      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
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
((TESTS_PASSED++))

# Test 2: Check git status
print_test "Test 2: Git Repository Status"
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not a git repository"
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" = "master" ]; then
    print_warning "On master branch - you may want to test a PR branch"
    ((TESTS_WARNED++))
else
    print_success "On branch: $CURRENT_BRANCH"
    ((TESTS_PASSED++))
fi

# Show recent commits
echo ""
echo "Recent commits:"
git log --oneline -3

# Test 3: Check for FlakeHub references
print_test "Test 3: FlakeHub Reference Check"
FLAKEHUB_COUNT=$(cat flake.lock | jq '[.nodes | to_entries[] | select(.value.locked.url != null and (.value.locked.url | contains("flakehub")))] | length')

if [ "$FLAKEHUB_COUNT" -gt 0 ]; then
    print_warning "Found $FLAKEHUB_COUNT FlakeHub references (not necessarily a problem)"
    echo "FlakeHub nodes:"
    cat flake.lock | jq -r '.nodes | to_entries[] | select(.value.locked.url != null and (.value.locked.url | contains("flakehub"))) | "  - " + .key'
    ((TESTS_WARNED++))
else
    print_success "No FlakeHub references"
    ((TESTS_PASSED++))
fi

# Test 4: Flake structure validation
print_test "Test 4: Flake Structure Validation"
echo "Running: nix flake check --all-systems --no-update-lock-file"
if nix flake check --all-systems --no-update-lock-file 2>&1 | tee "$LOG_DIR/flake-check.log"; then
    print_success "Flake check passed"
    ((TESTS_PASSED++))
else
    print_error "Flake check failed - see $LOG_DIR/flake-check.log"
    ((TESTS_FAILED++))
fi

# Test 5: Show flake metadata
print_test "Test 5: Flake Metadata"
nix flake metadata 2>&1 | tee "$LOG_DIR/flake-metadata.log"
print_success "Flake metadata retrieved"
((TESTS_PASSED++))

# Test 6: Check for major version changes
print_test "Test 6: Input Version Analysis"
if [ "$CURRENT_BRANCH" != "master" ]; then
    echo "Comparing flake.lock changes from master..."
    
    # Save current flake.lock
    cp flake.lock "$LOG_DIR/flake.lock.current"
    
    # Get master's flake.lock
    git show master:flake.lock > "$LOG_DIR/flake.lock.master" 2>/dev/null || {
        print_warning "Cannot compare with master (no master branch?)"
        ((TESTS_WARNED++))
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
            ((TESTS_WARNED++))
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
    ((TESTS_PASSED++))
else
    print_warning "On master branch, skipping version comparison"
    ((TESTS_WARNED++))
fi

# Test 7: Test build in client configuration
print_test "Test 7: Client Configuration Build Test"
if [ ! -d "$TEST_CLIENT_DIR" ]; then
    print_warning "Test client directory not found: $TEST_CLIENT_DIR"
    print_warning "Skipping client build test"
    ((TESTS_WARNED++))
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
        ((TESTS_FAILED++))
    }
    
    # Attempt build
    echo ""
    echo "Building client configuration..."
    echo "Command: nix build .#nixosConfigurations.$TEST_HOSTNAME.config.system.build.toplevel --print-out-paths"
    echo ""
    
    if timeout 600 nix build ".#nixosConfigurations.$TEST_HOSTNAME.config.system.build.toplevel" \
        --print-out-paths 2>&1 | tee "$LOG_DIR/build.log"; then
        print_success "Client configuration build SUCCEEDED"
        ((TESTS_PASSED++))
        
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  BUILD SUCCESS - SAFE TO MERGE!        ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    else
        print_error "Client configuration build FAILED"
        ((TESTS_FAILED++))
        
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
    echo -e "${GREEN}✅ VALIDATION PASSED - SAFE TO MERGE${NC}"
    echo ""
    if [ $TESTS_WARNED -gt 0 ]; then
        echo -e "${YELLOW}⚠️  There were $TESTS_WARNED warnings - review them before merging${NC}"
    fi
    echo ""
    echo "To merge this PR:"
    echo "  gh pr merge --squash"
    echo ""
    echo "After merging, update your system:"
    echo "  cd $TEST_CLIENT_DIR"
    echo "  nix flake update axios"
    echo "  sudo nixos-rebuild switch --flake .#$TEST_HOSTNAME"
    exit 0
fi
