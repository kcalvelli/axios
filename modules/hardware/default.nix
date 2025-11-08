{ ... }:
{
  # The hardware module provides a base for hardware-specific configurations
  # Individual vendor modules (msi.nix, system76.nix) should be imported separately
  # as they are exposed as standalone modules in modules/default.nix

  imports = [
    ./common.nix
  ];
}
