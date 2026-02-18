# GitHub Actions Workflows

This directory contains automated workflows for the axios flake library.

## Active Workflows

### Update flake.lock
**File:** `flake-lock-updater.yml`  
**Schedule:** Weekly on Mondays at 6 AM UTC  
**Purpose:** Creates PRs with updated flake.lock for manual review before merging.

- Runs `nix flake update` to update all inputs
- Validates flake structure with `nix flake check`
- **Tests basic builds** (formatter, devShell) to catch obvious breakage
- Creates PR only if validation passes
- Labels PRs as `dependencies` and `automated`

**Note:** CI tests are basic. Manual full build testing is recommended before merging dependency updates.

### Flake Check
**File:** `flake-check.yml`
**Triggers:** Push to master, pull requests
**Purpose:** Validates flake structure, builds examples, and tests validation logic.

- Runs `nix flake check` to verify flake validity
- **Builds example configurations** (example-config) to ensure library API works
- **Tests validation logic** to verify configuration errors are caught correctly
- Displays flake metadata for debugging
- Ensures no breaking changes to the flake interface

**Jobs:**
- `flake-check` - Validates flake structure (2-3 min)
- `build-examples` - Tests example configs in matrix (3-5 min per example)
- `test-validation` - Verifies validation catches invalid configs (1-2 min)

### Build Packages
**File:** `build-packages.yml`
**Schedule:** Weekly on Mondays at 2 AM UTC
**Triggers:** Changes to pkgs, flake files, push to master, pull requests, weekly
**Purpose:** Builds and caches all custom axios packages.

- Lists all available packages via `nix flake show`
- Builds each package and pushes to Cachix
- Keeps cache fresh with weekly rebuilds

### Build DevShells
**File:** `build-devshells.yml`
**Triggers:** Changes to devshells, push to master, pull requests
**Purpose:** Validates all development shells build successfully.

- Lists all available devShells
- Builds each devShell to catch build errors early
- Uses magic-nix-cache for faster builds

### Test Init Script
**File:** `test-init-script.yml`
**Triggers:** Changes to scripts, push to master, pull requests
**Purpose:** Ensures the `nix run github:kcalvelli/axios#init` command works.

- Tests that the init app can be invoked
- Validates script functionality for downstream users

### Code Formatting
**File:** `formatting.yml`
**Triggers:** Changes to .nix files, push to master, pull requests
**Purpose:** Ensures consistent code style across the project.

- Checks all .nix files are formatted with `nixfmt-rfc-style`
- Only runs when .nix files are modified (path-based trigger)
- Run `nix fmt` locally to fix formatting issues before pushing

## Permissions

The workflows use the built-in `GITHUB_TOKEN` with:
- `contents: write` - To push branches and commits
- `pull-requests: write` - To create PRs

These are configured at the workflow level. PR creation is now enabled for this repository.

## Manual Triggers

All workflows support `workflow_dispatch` for manual execution via:
```bash
gh workflow run <workflow-name>
```

Or through the GitHub Actions web interface.
