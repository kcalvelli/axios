# Binary Cache

Axios provides a binary cache to speed up builds for downstream users.

## For Users: Using the Axios Cache

Add the axios binary cache to your NixOS configuration:

```nix
# In your configuration.nix or flake-based config
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://axios.cachix.org"  # Add axios cache
    ];
    
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431kS1gBOk6429S9g0f1NXtv+FIsf8Xma0="
      "axios.cachix.org-1:REPLACE_WITH_PUBLIC_KEY"  # Add axios public key
    ];
  };
}
```

**Get the public key from:** https://app.cachix.org/cache/axios

### What Gets Cached?

The binary cache includes:
- ✅ All devShells (default, rust, qml, zig, spec)
- ✅ Packages (pwa-apps)
- ✅ Apps (init)
- ✅ Formatter
- ✅ Dependencies built during CI

### What Doesn't Get Cached?

- ❌ NixOS modules (these are Nix code, not built artifacts)
- ❌ Your specific system configuration
- ❌ Packages from other flakes you're using

### Benefits

Without cache:
- First build: **30-60 minutes** (building everything from source)
- Subsequent builds: 5-30 minutes (depending on changes)

With cache:
- First build: **2-5 minutes** (downloading pre-built binaries)
- Subsequent builds: 1-2 minutes (minimal changes)

### Troubleshooting

**Cache not being used?**

Check that substituters are configured:
```bash
nix show-config | grep substituters
```

**Verify cache is accessible:**
```bash
curl -I https://axios.cachix.org/
# Should return: HTTP/2 200
```

**Force using the cache:**
```bash
nix build --option substitute true --option substituters "https://axios.cachix.org https://cache.nixos.org"
```

## For Maintainers: Cache Management

### Cache Statistics

View cache usage at: https://app.cachix.org/cache/axios

### What Gets Pushed

The `cachix-action` automatically pushes:
- All builds from GitHub Actions workflows
- Everything built during `nix flake check`
- Any explicit builds in CI

### Storage Limits

**Free tier:**
- 5 GB storage
- Unlimited downloads
- Public caches only

**If you hit limits:**
1. Clean old store paths from cache
2. Upgrade to paid plan ($20/month for 50GB)
3. Set up cache retention policies

### Manual Push

To manually push builds to cache:

```bash
# Build something
nix build .#packages.x86_64-linux.pwa-apps

# Push to cache
cachix push axios ./result

# Push all builds from a flake
nix flake check --all-systems
cachix push axios $(nix flake check --all-systems --json 2>/dev/null | jq -r '.[] | .drvPath' 2>/dev/null)
```

### Revoking Access

If the signing key is compromised:

1. Generate new keypair: `cachix generate-keypair axios`
2. Update GitHub secret `CACHIX_AUTH_TOKEN`
3. Notify users to update their trusted public keys

### Cache Retention

Cachix retains:
- Recent builds indefinitely (within storage limit)
- Old builds until storage limit reached
- LRU (least recently used) eviction policy

## Alternative: Self-Hosted Cache

If you outgrow Cachix free tier, consider:

### Option 1: Attic + S3
- Use Backblaze B2, AWS S3, or Cloudflare R2
- Cost: ~$1-2/month for typical usage
- More control, more setup

### Option 2: nix-serve
- Self-hosted HTTP binary cache
- Requires server with public IP
- More DevOps work

See `docs/BINARY_CACHE_ALTERNATIVES.md` for details (TODO).

## Resources

- [Cachix Documentation](https://docs.cachix.org/)
- [Nix Binary Cache Docs](https://nixos.org/manual/nix/stable/package-management/binary-cache-substituter.html)
- [cachix-action GitHub](https://github.com/cachix/cachix-action)
