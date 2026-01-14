# System Configuration

## Purpose
Provides the foundational NixOS configuration for axiOS systems, including user management, bootloading, and localization.

## Requirements
- **No Regional Defaults**: Users must explicitly set `axios.system.timeZone`.
- **UEFI Only**: System must support UEFI boot; BIOS/MBR is not supported.
- **Independence**: The system module must be independently importable.

## Components

### Module System
- **Implementation**: `modules/default.nix`, `modules/*/default.nix`
- **Registration**: All modules must be registered in `modules/default.nix` (flake output) and `lib/default.nix` (builder).

### Timezone & Locale
- **Options**: `axios.system.timeZone` (required), `axios.system.locale` (default: en_US.UTF-8)
- **Implementation**: `modules/system/default.nix`

### Boot Configuration
- **Bootloader**: `systemd-boot`
- **Features**: EFI variable support, optional Secure Boot via Lanzaboote.
- **Implementation**: `modules/system/boot.nix`

### User Management
- **Implementation**: `modules/users.nix`
- **Options**: `axios.user.name`, `axios.user.fullName`, `axios.user.email`
