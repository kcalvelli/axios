# GitHub Actions Configuration Guide

## Fixing "GitHub Actions is not permitted to create pull requests" Error

The flake-lock-updater workflow needs permission to create pull requests. There are two approaches:

### Option 1: Enable GitHub Actions to Create PRs (Recommended)

1. Go to your repository settings: https://github.com/kcalvelli/axios/settings/actions
2. Scroll to "Workflow permissions"
3. Check the box: **"Allow GitHub Actions to create and approve pull requests"**
4. Save changes

This is the simplest solution and uses the built-in `GITHUB_TOKEN`.

### Option 2: Use a Personal Access Token (Alternative)

If you need more control or Option 1 doesn't work:

1. Create a fine-grained PAT at https://github.com/settings/tokens?type=beta with:
   - Repository access: Only select repositories → axios
   - Permissions:
     - Contents: Read and write
     - Pull requests: Read and write
     - Metadata: Read-only (automatically included)

2. Add the PAT as a repository secret:
   - Go to https://github.com/kcalvelli/axios/settings/secrets/actions
   - Click "New repository secret"
   - Name: `FLAKE_UPDATE_TOKEN`
   - Value: Your PAT

3. Update `.github/workflows/flake-lock-updater.yml` line 29:
   ```yaml
   token: ${{ secrets.FLAKE_UPDATE_TOKEN }}
   ```

## Current Repository Settings

Already configured:
- ✓ Workflow permissions: `write`
- ✗ Allow GitHub Actions to create PRs: **Not enabled** (needs manual configuration via web UI)

## Testing the Workflow

After enabling the setting, test with:
```bash
gh workflow run flake-lock-updater.yml
```

Or wait for the scheduled Monday 6 AM UTC run.
