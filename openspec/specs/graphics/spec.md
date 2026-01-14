# Hardware & Graphics Support

## Purpose
Ensures optimal hardware performance and driver support across different GPU vendors.

## Components

### GPU Driver Engine
- **Support**: NVIDIA, AMD, Intel.
- **NVIDIA**: Stable/Beta versions, open kernel modules, PRIME support.
- **AMD**: ROCm for AI, hardware hang recovery options.
- **Intel**: VA-API acceleration.
- **Implementation**: `modules/graphics/default.nix`

### Hardware Profiles
- **Profiles**: Desktop (performance), Laptop (power management/TLP).
- **Implementation**: `modules/hardware/desktop.nix`, `modules/hardware/laptop.nix`

## Constraints
- **Wayland Compatibility**: Kernels must be configured with `nvidia_drm.modeset=1` for Nvidia Wayland support.
- **Architecture**: Use `pkgs.stdenv.hostPlatform.system` for system-specific package references.
