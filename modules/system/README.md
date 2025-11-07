# System Module

Core system-level configuration and utilities that form the foundation of the OS.

## Purpose

Contains essential system utilities, filesystem tools, monitoring tools, and base system configuration needed by all machines.

## Package Organization

System packages are organized inline by category:
- **Core utilities**: Essential utilities (curl, wget, killall)
- **Filesystem**: Mount and filesystem tools (sshfs, fuse, ntfs3g)
- **Monitoring**: System information and monitoring (htop, lm_sensors)
- **Archives**: Archive and compression tools (p7zip, unzip, unrar)
- **Security**: Secret management and encryption (libsecret, openssl)
- **Nix tools**: Nix ecosystem tools (fh)

## What Goes Here

**System-level packages:**
- Core utilities needed by the system or multiple users
- Filesystem and hardware tools
- System monitoring and diagnostics
- Base security tools

**User-specific alternatives go to:** `home/common/`

## Sub-modules

- `locale.nix`: Timezone and locale configuration (axios.system.timeZone required)
- `nix.nix`: Nix and Flakes configuration
- `boot.nix`: Boot loader and kernel configuration
- `memory.nix`: Memory management and OOM protection
- `printing.nix`: Printing services
- `sound.nix`: Audio configuration
- `bluetooth.nix`: Bluetooth configuration
