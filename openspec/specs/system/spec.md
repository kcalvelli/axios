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

## Requirements
- **UEFI Only**: System must support UEFI boot; legacy BIOS/MBR is not supported.
- **Hardware Config**: Users must provide `hardwareConfigPath` (typically `/etc/nixos/hardware-configuration.nix`).
