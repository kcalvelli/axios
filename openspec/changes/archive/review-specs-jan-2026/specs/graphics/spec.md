# Hardware & Graphics Support

## Purpose
Ensures optimal hardware performance and driver support across different GPU vendors while maintaining a unified module interface.

## Components

### GPU Driver Engine
- **Interface**: `hardware.gpu` option in host configuration.
- **Nvidia**: Automatically sets video drivers, enables `nvidiaSettings`, and configures Beta packages if needed.
- **AMD**: Enables `amdgpu` kernel modules, provides `amdgpu_top`, and supports optional GPU recovery (`axios.hardware.enableGPURecovery`).
- **Intel**: VA-API acceleration and `intel-gpu-tools`.
- **Implementation**: `modules/graphics/default.nix`

### Hardware Profiles
- **Desktop**: Performance-oriented tuning (`hardware.desktop.cpuGovernor = "powersave"` by default for modern drivers).
- **Laptop**: Battery-aware tuning with TLP or similar profiles.
- **Implementation**: `modules/hardware/desktop.nix`, `modules/hardware/laptop.nix`

### Peripherals
- **Gaming**: Controller support (Udev rules) and binary compatibility layer (`nix-ld`) for native Linux games.
- **Logitech**: Solaar/Udev rules support for Unifying receivers.

## Constraints
- **Wayland Compatibility**: Kernels are configured with `nvidia_drm.modeset=1` automatically for Nvidia.
- **Library Reference**: Use `pkgs.stdenv.hostPlatform.system` for system-specific packages.
