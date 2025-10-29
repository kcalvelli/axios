# Troubleshooting Guide

## Build Failures: "getting attributes of path" Errors

### Symptoms
```
error: getting attributes of path '/nix/store/...-stdenv-linux': No such file or directory
error: getting attributes of path '/nix/store/...-gnu-config-...': No such file or directory
```

### Root Causes
1. **FlakeHub References** - Expired FlakeHub account causing corrupted flake.lock entries
2. **Nix Store Corruption** - Missing or inconsistent store paths
3. **Determinate Nix Issues** - Transitive dependencies pulling in FlakeHub

### Solutions (Try in Order)

#### 1. Remove FlakeHub References
Already done in axios as of commit `0728065`. Verify your client config:

```bash
cd ~/.config/nixos_config
cat flake.lock | jq '[.nodes | to_entries[] | select(.value.locked.url != null and (.value.locked.url | contains("flakehub")))] | length'
# Should output: 0
```

If not zero:
```bash
nix flake lock --override-input axios /path/to/axios
```

#### 2. Clean Nix Store
```bash
# Aggressive garbage collection
nix-collect-garbage -d

# Verify store integrity  
nix-store --verify --check-contents

# Delete specific problematic paths
nix-store --delete /nix/store/PROBLEMATIC-PATH
```

#### 3. Restart Nix Daemon
```bash
sudo systemctl restart nix-daemon.service
```

#### 4. Nuclear Option: Fresh Build Environment
If corruption persists:

```bash
# Backup your configuration
cd ~/.config/nixos_config
git commit -am "backup before store rebuild"

# Clear all build artifacts
nix-collect-garbage -d
sudo nix-collect-garbage -d

# Rebuild with fresh downloads
sudo nixos-rebuild switch --flake .#hostname --option tarball-ttl 0
```

#### 5. Downgrade from Determinate Nix (Last Resort)
If Determinate Nix itself is causing issues:

```bash
# Switch to standard Nix
# Remove determinate from your flake inputs
# Re-enable after the issue is resolved
```

## Prevention

### Use PR-Based Updates
- Review flake.lock changes before merging
- Test updates locally before deploying
- Check for FlakeHub references in PRs

### Pin Stable Versions
For critical systems:
```nix
inputs.axios.url = "github:kcalvelli/axios/KNOWN-GOOD-COMMIT";
```

### Monitor Store Health
Regular verification:
```bash
# Weekly check
nix-store --verify --check-contents

# Monthly cleanup
nix-collect-garbage --delete-older-than 30d
```

## Known Issues

### FlakeHub After Account Expiration
- **Status:** RESOLVED (removed from axios)
- **Commit:** 0728065
- **Date:** 2025-10-29

### Determinate Input
- **Status:** DISABLED (commented out)
- **Reason:** Pulls in FlakeHub transitive dependencies
- **Impact:** NixOS module not imported, daemon still works
- **Future:** Can re-enable when FlakeHub-free version available

## Getting Help

If issues persist after trying all solutions:

1. Check axios repository issues: https://github.com/kcalvelli/axios/issues
2. Document your error with:
   - Full error message
   - Output of `nix --version`
   - Output of `cat flake.lock | jq '.nodes | keys'`
   - Recent changes to your configuration

3. Consider rollback to last working generation:
   ```bash
   sudo nixos-rebuild switch --rollback
   ```
