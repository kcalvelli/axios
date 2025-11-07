# Flake Update Issue - October 29, 2025

## Problem
The automated flake.lock update (commit f4ca8d7 and PR #3) introduced breaking changes from upstream nixpkgs-unstable that cause build failures:

```
error: getting attributes of path '/nix/store/...-stdenv-linux': No such file or directory
```

## Root Cause
This is a known issue with nixpkgs-unstable occasionally having breaking changes that affect the stdenv (standard environment). The automated update pulled in these changes without manual review.

## Resolution

### For Axios Repository (Maintainer - Done)
✅ Reverted to previous working flake.lock
✅ Repository is now stable again

### For Downstream Users (Clients)

If you're seeing this error after updating your flake inputs:

**Option 1: Update axios input to use working commit**
```nix
# In your flake.nix
inputs.axios.url = "github:kcalvelli/axios/1ae9947";  # Known working commit
```

**Option 2: Update axios and regenerate flake.lock**
```bash
cd ~/my-nixos-config
nix flake update axios
sudo nixos-rebuild switch --flake .#your-hostname
```

**Option 3: Pin to a specific working date**
```nix
# In your flake.nix
inputs.axios.url = "github:kcalvelli/axios?rev=1ae9947";
```

## Prevention Going Forward

This incident validates the PR-based review workflow we just implemented:

### What We Changed
1. ✅ **Manual Review Required** - All flake.lock updates now create PRs
2. ✅ **No Auto-Merge** - Maintainer must review and test before merging
3. ✅ **CI Validation** - flake-check.yml validates structure on every update

### Weekly Workflow (Starting Next Monday)
1. GitHub Actions creates PR with flake.lock updates
2. Maintainer reviews changes in nixpkgs-unstable
3. Optional: Test locally before merging
4. Merge only when confirmed stable
5. Downstream users can then safely update

## Testing Before Merge

When reviewing flake.lock PRs, test with:

```bash
# Clone the PR branch
gh pr checkout <pr-number>

# Test build
nix flake check

# Test in a downstream config (optional)
cd /path/to/client/config
nix flake lock --update-input axios --override-input axios /path/to/axios
sudo nixos-rebuild test --flake .#hostname
```

## Current Status
- ✅ Axios repository: STABLE (commit 1ae9947)
- ✅ Automated PR workflow: ENABLED with manual review
- ⏸️  Next scheduled update: Monday, November 3, 2025 @ 6:00 AM UTC

## Lessons Learned
1. nixpkgs-unstable can have breaking changes
2. Manual review is essential for library flakes
3. PR-based workflow prevents these issues from reaching users
4. The error validates our decision to require manual review

## Related Files
- `.github/workflows/flake-lock-updater.yml` - PR-based updater
- `.github/workflows/README.md` - Workflow documentation
- `.github/ACTIONS_SETUP.md` - Setup guide
