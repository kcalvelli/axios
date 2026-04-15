## Why

Cairn has no graphical installer. Users must run `nix run .#init` from a terminal on an existing NixOS system, then manually `nixos-install --flake`. This works for power users but creates a barrier for anyone expecting a standard OS installation experience. NixOS ships a Calamares-based graphical installer that generates a traditional `configuration.nix` — we can replace its config generation module with one that produces an Cairn flake structure, giving users a familiar install wizard that bootstraps a fully functional Cairn system.

The upstream `NixOS/calamares-nixos-extensions` repository was archived (Aug 2025) and all source is now vendored in nixpkgs. This means Cairn can vendor its own extensions package without tracking an upstream repo.

## What Changes

Replace the Calamares `nixos` job module (which generates `configuration.nix`) with an `cairn` job module that generates a complete Cairn flake structure (`flake.nix`, `hosts/<hostname>.nix`, `users/<username>.nix`). Ship this as a `calamares-cairn-extensions` package used in an Cairn ISO build.

### Installer Pipeline

The Calamares sequence becomes:

```
show:  welcome → locale → keyboard → users → unfree → cairnconfig → partition → summary
exec:  partition → mount → cairn → users → umount
show:  finished
```

Key differences from upstream NixOS installer:
- **Remove `packagechooser`** — Cairn always uses Niri, no DE selection needed
- **Add `notesqml@cairnconfig`** — Cairn profile and feature selection page
- **Replace `nixos` exec job with `cairn`** — generates flake structure instead of `configuration.nix`

### Profile-Gated UX

The cairnconfig page presents a profile choice (standard vs normie) that gates the rest of the UI:

- **Normie**: Simple ChromeOS-like experience. No feature toggles shown — skips to partitioning with sane defaults (all optional modules disabled).
- **Standard**: Full feature selection matching what `init-config.sh` offers — gaming, PIM (with server/client role), Immich, Local LLM, Secure Boot, Secrets, Virtualization (libvirt/containers), and tailnet domain when needed.

Hardware (CPU vendor, GPU vendor, form factor, SSD) is auto-detected by a lightweight `cairndetect` Python job that pre-populates globalstorage before the show phase. The cairnconfig page displays detected values with a "Change" option for overrides.

### Config Generation

The `cairn` job module (Python) reads globalstorage and templates out:

```
<rootMountPoint>/etc/nixos/
├── flake.nix                    # imports Cairn, calls mkHost
├── flake.lock                   # pre-baked, pinned to ISO's Cairn revision
├── hosts/
│   ├── <hostname>.nix           # hostConfig with hardware + feature toggles
│   └── <hostname>/
│       └── hardware.nix         # from nixos-generate-config
└── users/
    └── <username>.nix           # cairn.users.users.<name> config
```

Then runs: `nixos-install --no-root-passwd --root <mountpoint> --flake <mountpoint>/etc/nixos#<hostname>`

### flake.lock Strategy

The `flake.lock` is pre-generated at ISO build time, pinning `cairn` to the exact revision (`self.rev` / `self.narHash`) that built the ISO. Since the ISO's nix store already contains the full Cairn closure used to build it, `nixos-install` resolves everything locally — no network fetch required for the Cairn input.

### Template Independence

The Calamares templates are independent from `scripts/templates/*.template` used by `init-config.sh`. Both produce the same `hostConfig` structure (dictated by the `mkSystem` API), but their execution contexts are fundamentally different:

- `init-config.sh`: bash + gum TUI, writes to `~/.config/nixos_config/`, includes git init, supports Mode B (add host)
- `cairn/main.py`: Python + Calamares globalstorage, writes to mountpoint, runs `nixos-install`, single-use fresh install

The real source of truth is the `mkSystem` API — as long as both produce valid `hostConfig` shapes, they stay in sync.

## Capabilities

### New Capabilities
- `calamares-installer`: Graphical Cairn installer via Calamares with profile-gated feature selection and flake-based config generation
- `cairn-iso`: Bootable ISO image containing the Cairn graphical installer, pinned to a specific Cairn release

### Modified Capabilities
- None — this is entirely additive. `init-config.sh` remains the CLI installation path.

## Impact

- **New package**: `calamares-cairn-extensions` in `pkgs/` — vendored Calamares modules, config, and branding
- **New NixOS module**: `modules/installer/` — ISO configuration importing Calamares with Cairn extensions
- **New flake output**: ISO image build (`nixosConfigurations.iso` or similar)
- **Files added**:
  - `pkgs/calamares-cairn-extensions/` — package derivation + vendored source
  - `pkgs/calamares-cairn-extensions/src/modules/cairn/main.py` — flake config generator
  - `pkgs/calamares-cairn-extensions/src/modules/cairndetect/main.py` — hardware auto-detection
  - `pkgs/calamares-cairn-extensions/src/branding/cairn/` — branding, QML pages, slideshow
  - `pkgs/calamares-cairn-extensions/src/config/` — settings.conf + module configs
  - `modules/installer/default.nix` — ISO NixOS module
- **No breaking changes**: Purely additive, no existing functionality modified
- **Dependencies**: `calamares-nixos` package from nixpkgs (the patched Calamares binary)

## Implementation Phases

### Phase 1: MVP Job Module
- Fork `nixos/main.py` → `cairn/main.py` with flake structure templating
- Use only existing Calamares globalstorage keys (hostname, timezone, locale, keyboard, username, partitions)
- Hardcode sensible defaults for Cairn features not yet collected via UI
- Pre-bake `flake.lock` at ISO build time
- ISO module + build, testable in VM

### Phase 2: Cairn Config QML Page
- `cairndetect` job for hardware auto-detection (CPU, GPU, form factor, SSD)
- `notesqml@cairnconfig` QML page with profile gate and feature toggles
- Wire new globalstorage keys into `cairn/main.py`

### Phase 3: Polish
- Cairn-branded Calamares theme (replace NixOS branding)
- Install slideshow
- Offline install validation
