# Self-Hosted Services Module
# Provides self-hosted services with Tailscale Services for HTTPS
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.selfHosted;
in
{
  imports = [
    ./immich.nix
  ];

  options.selfHosted = {
    enable = lib.mkEnableOption "self-hosted services with Tailscale Services HTTPS";
  };

  # No global config needed - services register with Tailscale Services individually
}
