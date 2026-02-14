# System Configuration

## Purpose
Provides the foundational NixOS configuration for axiOS systems, including user management, bootloading, performance tuning, and localization.

## Components

### Boot & Kernel
- **Kernel**: Latest stable kernel (`pkgs.linuxPackages_latest`).
- **Quiet Boot**: systemd-based initrd with Plymouth splash and suppressed log messages.
- **Secure Boot**: Optional support via Lanzaboote (`boot.lanzaboote.enableSecureBoot`).
- **Options**: `boot.kernelPackages`, `boot.lanzaboote.enableSecureBoot`.
- **Implementation**: `modules/system/boot.nix`

### Performance & Memory Tuning
- **Zram**: Compressed swap in RAM using `zstd` algorithm (default: 25% of RAM).
- **Swappiness**: Optimized for development workloads (default: 10).
- **Network**: BBR congestion control and optimized buffers (1MB) enabled by default.
- **Tuning**: systemd-oomd enabled with tiered pressure limits (80% system, 50% user).
- **Inotify**: Increased to 524,288 watchers for modern IDE support.
- **Implementation**: `modules/system/boot.nix`, `modules/system/memory.nix`

### Timezone & Locale
- **No Regional Defaults**: Users must explicitly set `axios.system.timeZone`.
- **Locale**: Default `en_US.UTF-8`, configurable via `axios.system.locale`.
- **Implementation**: `modules/system/locale.nix`

### User Management
- **Implementation**: `modules/users.nix`
- **Multi-user interface**: `axios.users.users.<name>` (attrsOf submodule) with per-user options:
  - `fullName` (str) — user's display name
  - `email` (str, default "") — for git config and home-manager
  - `isAdmin` (bool, default false) — controls wheel group and trusted-users
  - `homeProfile` (enum "workstation"/"laptop"/"minimal"/null, default null) — per-user profile override (falls back to host homeProfile)
  - `extraGroups` (list of str) — additional groups for this user
- **Computed options**: `axios.users.firstAdminUser` — read-only, first user where `isAdmin = true` (used by greeter)
- **Automatic group membership**: Groups computed from enabled modules (networkmanager, video, audio, input, etc.) with `wheel` only for `isAdmin = true` users
- **Per-user home-manager wiring**: Each user gets `home-manager.users.<name>.axios.user.email` set automatically
- **Per-user XDG directories**: Created via `systemd.tmpfiles.rules` for all users
- **Trusted users**: `nix.settings.trusted-users` set to list of admin usernames
- **Host-user association**: Hosts declare `users = [ "name1" "name2" ]`; axiOS resolves `configDir + "/users/${name}.nix"` automatically

### System Branding
- **Distribution Identity**: Configures system to identify as "axiOS" instead of generic "NixOS".
- **Logo Integration**: Installs axiOS logo to system pixmaps directory for desktop environment usage.
- **os-release Configuration**: Sets `LOGO=axios` in `/etc/os-release` for desktop shell integration (e.g., DMS launcher).
- **Implementation**: `modules/system/branding.nix`
- **Assets**: `modules/system/resources/branding/axios.png`

### Systematic DMS Placeholder Generation
- **Implementation**: `home/desktop/niri-keybinds.nix` (home.activation.dmsPlaceholders)
- **Purpose**: The desktop module maintains an authoritative list of all DMS (dankMaterialShell) KDL configuration files that niri's config includes via `include` directives. For each file, the system creates an empty placeholder at `~/.config/niri/dms/<name>.kdl` via home-manager activation if it does not already exist.
- **Rationale**: On first boot, DMS hasn't run yet so these files don't exist, causing niri to fail with include errors.
- **Behavior**: Uses `home.activation` (not `xdg.configFile`) so files are real and writable — DMS overwrites them at runtime.

### Init Script Multi-user Support
- **Implementation**: `scripts/init-config.sh`, `scripts/templates/`
- **Purpose**: The init script (`nix run .#init`) supports creating configurations for multiple users. After gathering the primary user (marked as admin), it prompts for additional users with username, full name, email, and admin status.
- **Output**: Generates individual `users/<username>.nix` files using `axios.users.<name>` format and a `flake.nix` using the canonical `mkHost` pattern with `configDir`.

### Init Script Hardware Pre-flight Validation
- **Implementation**: `scripts/init-config.sh`
- **Purpose**: Performs hardware compatibility checks after gathering configuration and before generating files. Warns about known issues (e.g., NVIDIA GPU with kernel >= 6.19).
- **Behavior**: Warnings are informational (not blocking) and include suggested workarounds.

## Requirements
- **UEFI Only**: System must support UEFI boot; legacy BIOS/MBR is not supported.
- **Hardware Config**: Users must provide `hardwareConfigPath` (typically `/etc/nixos/hardware-configuration.nix`).
