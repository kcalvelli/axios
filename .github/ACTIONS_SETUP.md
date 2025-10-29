# GitHub Actions Configuration

## ✅ Configuration Complete

The repository is now configured for PR-based flake.lock updates with manual review.

### Current Setup
- ✓ Workflow permissions: `write`
- ✓ GitHub Actions can create PRs: **Enabled**
- ✓ Weekly PR creation: Every Monday at 6 AM UTC
- ✓ Manual review required before merge

## Weekly Workflow

Every Monday, GitHub Actions will:
1. Update flake.lock with latest inputs
2. Create a PR with the changes
3. Label it as `dependencies` and `automated`
4. **Wait for your review**

You can then:
- Review the changes in the PR
- Check for breaking changes in nixpkgs-unstable
- Test the updates if needed
- Merge when ready or close if problematic

## Manual Trigger

To trigger an update immediately:
```bash
gh workflow run flake-lock-updater.yml
```

Or via GitHub web interface: Actions → Update flake.lock → Run workflow

## Alternative: Direct Commit (Disabled)

The `flake-lock-updater-direct.yml` workflow is available but disabled. It commits directly to master without PR review. Only use if you want fully automated updates without review.
