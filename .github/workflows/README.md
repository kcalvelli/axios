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
- **Requires manual testing** with `./scripts/test-pr.sh` before merging
- Labels PRs as `dependencies` and `automated`

**Note:** CI tests are basic. Always run `./scripts/test-pr.sh` to catch dependency conflicts.

### Flake Check
**File:** `flake-check.yml`  
**Triggers:** Push to master, pull requests  
**Purpose:** Validates flake structure and outputs across all systems.

- Runs `nix flake check` to verify flake validity
- Displays flake metadata for debugging
- Ensures no breaking changes to the flake interface

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
