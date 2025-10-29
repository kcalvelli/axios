# GitHub Actions Workflows

This directory contains automated workflows for the axios flake library.

## Active Workflows

### Update flake.lock
**File:** `flake-lock-updater.yml`  
**Schedule:** Weekly on Mondays at 6 AM UTC  
**Purpose:** Creates PRs with updated flake.lock for manual review before merging.

- Creates a PR with updated flake.lock
- Labels PRs as `dependencies` and `automated`
- **Requires manual review and merge** - important for catching breaking changes in nixpkgs-unstable
- Can be manually triggered via workflow_dispatch

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
