{ ... }:
{
  # Normie profile: ChromeOS-like mouse-driven desktop with window controls
  imports = [
    ./base.nix
    ../desktop/normie.nix
  ];
}
