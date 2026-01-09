# Binary Cache

Axios uses multiple binary caches to speed up builds and avoid compiling from source.

## For Users: Binary Cache Configuration

### Automatic Configuration (Recommended)

**If you enable `modules.desktop = true`**, binary caches are automatically configured for you! The desktop module sets up:

- ✅ **niri.cachix.org** - Niri compositor (avoids 10-15 min Rust compilation)
- ✅ **brave-previews.cachix.org** - Brave Nightly/Beta browsers

No manual configuration needed - just enable the desktop module.

### Manual Configuration

If you want to add the axios cache manually (for custom packages), or if you're not using the desktop module:

```nix
# In your configuration.nix or flake-based config
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://axios.cachix.org"           # Axios custom packages
      "https://niri.cachix.org"            # Niri compositor
      "https://brave-previews.cachix.org"  # Brave browsers
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431kS1gBOk6429S9g0f1NXtv+FIsf8Xma0="
      "axios.cachix.org-1:8c7nj72raLM0Q4Fie799J/70D2/5oDd7rxqnOuxObh4="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "brave-previews.cachix.org-1:9bLSYtgro1rYD4hUzFVASMpsNjWjHvEz11HGB2trAq4="
    ];
  };
}
```

**Get public keys from:**
- https://app.cachix.org/cache/axios
- https://app.cachix.org/cache/niri
- https://app.cachix.org/cache/brave-previews

## What Gets Cached?

### axios.cachix.org
- ✅ Custom packages (pwa-apps)
- ✅ App dependencies (init, add-pwa, fetch-pwa-icon, download-llama-models)

### niri.cachix.org (External)
- ✅ Niri compositor (Rust application, ~10-15 min build time saved)

### brave-previews.cachix.org
- ✅ Brave Nightly browser
- ✅ Brave Beta browser

## What Doesn't Get Cached?

- ❌ **Full NixOS system builds** (too large, mostly standard nixpkgs anyway)
- ❌ **DevShells** (not worth the cache space)
- ❌ **DankMaterialShell (DMS)** (still compiles from source - may add later)
- ❌ **NixOS modules** (these are Nix code, not built artifacts)
- ❌ **Your specific system configuration**

## Benefits

### Time Savings

**Without binary caches:**
- First build with desktop module: **40-60 minutes**
  - Niri compilation: 10-15 min
  - DMS compilation: 5-10 min
  - Brave Nightly: 10-20 min (if using previews)
  - Everything else: 15-25 min

**With binary caches (auto-configured):**
- First build with desktop module: **10-20 minutes**
  - Niri: ✅ Downloaded (~30 sec)
  - DMS: ❌ Still compiles (5-10 min)
  - Brave Nightly: ✅ Downloaded (~1 min)
  - Everything else: 5-10 min

**Estimated savings: 30-40 minutes on first build**, even more on subsequent builds.

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

View cache usage at:
- **axios**: https://app.cachix.org/cache/axios
- **brave-previews**: https://app.cachix.org/cache/brave-previews

### What Gets Pushed to axios.cachix.org

The `build-packages.yml` workflow pushes:
- ✅ Custom packages from `pkgs/` (pwa-apps)
- ✅ App dependencies (init, add-pwa, fetch-pwa-icon, download-llama-models)
- ❌ **NOT** full system builds (kept as dry-run validation)
- ❌ **NOT** devShells (not worth the space)

**Weekly cron** (Mondays 2 AM UTC) rebuilds to keep cache fresh with input updates.

### What Gets Pushed to brave-previews.cachix.org

The `brave-browser-previews-flake` repo workflows push:
- ✅ brave-nightly (daily updates via `update.yml`)
- ✅ brave-beta (daily updates via `update.yml`)
- ✅ On-demand builds via `build-and-cache.yml`

### Storage Strategy

**Free tier per cache:**
- 5 GB storage per cache
- Unlimited downloads
- Public caches only

**Current usage strategy:**
- **axios.cachix.org**: ~500MB-1GB (custom packages only, selective caching)
- **brave-previews.cachix.org**: ~500MB-1GB (brave builds, automatic updates)
- **Total**: Well under combined 10GB limit ✅

**Why this works:**
- We **don't cache** full NixOS systems (would be 2-5GB per config)
- We **don't cache** devShells (low value, moderate size)
- We **rely on** external caches (niri.cachix.org) where available
- We **only cache** what's unique to axios and not available elsewhere

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
