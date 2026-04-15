## Context

Cairn provides a CLI-based installer (`nix run .#init`) that uses gum TUI prompts to collect system configuration and generate a flake-based NixOS config. There is no graphical installer. NixOS ships a Calamares-based graphical installer whose config-generation job module (`nixos/main.py`) templates out a traditional `configuration.nix`. The upstream `calamares-nixos-extensions` repo was archived in Aug 2025 and all source is vendored in nixpkgs.

We are building a `calamares-cairn-extensions` package that replaces the `nixos` job module with an `cairn` job module, producing an Cairn flake structure instead of `configuration.nix`. This is shipped in a bootable ISO pinned to a specific Cairn release.

## Goals / Non-Goals

**Goals:**
- Graphical installer that produces a working Cairn flake structure
- Profile-gated UX: normie users get a simple path, standard users get full feature selection
- Hardware auto-detection with user override capability
- ISO pinned to a specific Cairn release via pre-baked `flake.lock`
- Offline-capable install (Cairn closure cached in ISO's nix store)

**Non-Goals:**
- Replacing `init-config.sh` (CLI path remains for power users and Mode B add-host)
- Multi-user setup during install (Calamares creates one user; additional users added post-install)
- Disko integration (Calamares handles partitioning natively)
- Custom Calamares C++ modules (use only Python jobs and `notesqml` QML instances)

## Decisions

### 1. Independent templates from init-config.sh

The Calamares Python job maintains its own template strings, separate from `scripts/templates/*.template`. Both produce the same `hostConfig` shape dictated by the `mkSystem` API, but their execution contexts are too different to share:

- `init-config.sh`: bash + gum, writes to user directory, git init, supports add-host mode
- `cairn/main.py`: Python + globalstorage, writes to mountpoint, runs nixos-install, fresh install only

The `mkSystem` API is the source of truth. Template sync is low-cost since templates are thin wrappers around `hostConfig` fields.

**Alternative considered:** Shared template files or shelling out to `init-config.sh` from Python. Rejected — the surrounding logic (git init, gum prompts, Mode B) is irrelevant in the Calamares context, and coupling to a bash script adds fragility.

### 2. Pre-baked flake.lock pinned to ISO build revision

The `calamares-cairn-extensions` package generates a `flake.lock` at build time, pinning the `cairn` input to `self.rev` and `self.narHash`. The downstream flake has only one input (`cairn`), so the lock file is minimal. Transitive inputs (nixpkgs, home-manager, etc.) are locked by Cairn's own `flake.lock`.

Since the ISO is built by this same Cairn revision, the full closure is already in the ISO's nix store. `nixos-install` resolves everything locally.

```
ISO nix store contains:
  Cairn @ abc123 (full closure)
     └── nixpkgs @ def456 (locked by Cairn)
     └── home-manager @ ghi789 (locked by Cairn)
     └── ... all transitive inputs

Generated flake.lock contains:
  cairn → { rev: "abc123", narHash: "sha256-..." }
  (that's it — one entry)

nixos-install resolves:
  cairn → abc123 → found in /nix/store ✓
  nixpkgs → def456 → locked by Cairn's flake.lock → found in /nix/store ✓
```

**Alternative considered:** Running `nix flake lock` at install time. Rejected — requires network, and we want the installer to work offline. Also means the installed system could get a different Cairn version than what built the ISO.

### 3. Profile choice gates feature selection UI

The cairnconfig QML page presents standard vs normie as the first choice. This controls visibility of all subsequent options:

- **Normie selected**: Feature toggles hidden. All optional modules default to disabled. Globalstorage gets `cairn_homeProfile = "normie"` and sensible defaults for everything else.
- **Standard selected**: Full feature selection revealed — gaming, PIM (server/client), Immich, Local LLM, Secure Boot, Secrets, Virtualization (libvirt/containers), tailnet domain.

QML handles this with conditional `visible` bindings. No need for separate pages or multiple `notesqml` instances for the feature section.

**Alternative considered:** Multiple QML pages (hardware, features, advanced). Rejected — one page with conditional visibility is simpler and avoids the overhead of multiple `notesqml` instances and config files.

### 4. Hardware auto-detection via cairndetect Python job

A lightweight Python job module (`cairndetect`) runs in the `show` phase before any UI pages. It reads:

| Detection | Source | GlobalStorage Key |
|-----------|--------|-------------------|
| CPU vendor | `/proc/cpuinfo` (vendor_id) | `cairn_cpuVendor` ("amd" / "intel") |
| GPU vendor | `lspci` output | `cairn_gpuVendor` ("amd" / "nvidia" / "intel") |
| Form factor | `/sys/class/power_supply/` battery presence | `cairn_formFactor` ("desktop" / "laptop") |
| SSD | `/sys/block/*/queue/rotational` | `cairn_hasSSD` (true / false) |

The QML page reads these as defaults. User can override via radio buttons / dropdown.

**Alternative considered:** Detection in QML via Qt `Process` type. Rejected — Python has cleaner access to system files, and the detection logic mirrors what `init-config.sh` already does in bash. Keeping it in a separate job also means it runs once, before any UI rendering.

### 5. Vendored extensions package in pkgs/

`calamares-cairn-extensions` is a `stdenv.mkDerivation` in `pkgs/calamares-cairn-extensions/` with vendored source under `src/`. This follows the same pattern as the upstream nixpkgs package. The package includes:

- `modules/cairn/` — flake config generation job
- `modules/cairndetect/` — hardware detection job
- `config/` — `settings.conf` + module configs
- `branding/cairn/` — QML pages, branding descriptor, slideshow

The `settings.conf` uses `@out@` substitution for module search paths, same as upstream.

### 6. ISO module in modules/installer/

A NixOS module at `modules/installer/default.nix` provides the ISO configuration. It imports NixOS's `installation-cd-graphical-base.nix` and adds:

- `calamares-nixos` (patched Calamares binary from nixpkgs)
- `calamares-cairn-extensions` (our package)
- Autostart desktop entry
- `glibcLocales` for locale selection

The ISO runs a live Niri session (Cairn's own compositor) with Calamares auto-starting. This means the live environment itself demonstrates Cairn.

### 7. nixos-install invocation

The `cairn` job module runs:

```
nixos-install --no-root-passwd --root <mountpoint> \
  --flake <mountpoint>/etc/nixos#<hostname> \
  --option build-dir /nix/var/nix/builds
```

- `--no-root-passwd`: Calamares `users` job handles passwords separately
- `--flake`: Points at the generated flake structure
- `--option build-dir`: Required because mountpoint is under `/tmp` (world-writable)

## Risks / Trade-offs

**[self.rev unavailable in dirty builds]** → During development with uncommitted changes, `self.rev` is null. The extensions package must handle this — either fall back to `self.dirtyRev`, or fail the build with a clear message requiring a clean checkout for ISO builds. Production ISOs should always be built from tagged releases.

**[ISO size]** → Including the full Cairn closure makes the ISO larger than a stock NixOS ISO. Mitigation: the ISO already needs Niri + desktop for the live environment, which overlaps significantly with the installed system. The marginal cost of bundling the full closure for offline install may be acceptable. Measure during Phase 1.

**[Single user limitation]** → Calamares collects one user. Cairn supports multi-user via `cairn.users.users`. The installer creates the primary user; additional users are added post-install by editing the flake config or running `init-config.sh --add-host`. This is acceptable — most graphical OS installers create one user.

**[Template drift]** → When `mkSystem` gains new `hostConfig` fields, both `init-config.sh` templates and `cairn/main.py` templates need updating. Mitigation: `mkSystem` changes are infrequent, and the templates are thin. Add a note to the module registration checklist in CLAUDE.md.

**[Calamares QML widget limitations]** → The unfree checkbox example proves `CheckBox` works. `RadioButton`, `ComboBox`, `TextField`, and `Switch` are all standard QtQuick.Controls and should work in `notesqml`. Verify during Phase 2 with a QML prototype.

**[NVIDIA kernel version constraints]** → `init-config.sh` has a `nvidia_preflight` check for kernel >= 6.19. The Calamares flow doesn't need this — Cairn's `mkSystem` handles NVIDIA kernel pinning at the module level based on `hardware.gpu = "nvidia"`. The installer just sets the flag.
