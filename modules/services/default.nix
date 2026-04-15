# Self-Hosted Services Module
# Provides self-hosted services with Tailscale Services for HTTPS
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./immich.nix
  ];

  # No options needed - individual services (like cairn.immich) define their own
}
