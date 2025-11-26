# Self-Hosted Services Module
# Provides Caddy reverse proxy with Tailscale HTTPS and self-hosted services
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
    ./caddy.nix
    ./immich.nix
  ];

  options.selfHosted = {
    enable = lib.mkEnableOption "self-hosted services with Caddy reverse proxy and Tailscale HTTPS";
  };

  config = lib.mkIf cfg.enable {
    # Enable Caddy reverse proxy
    services.caddy.enable = true;

    # Grant Caddy access to Tailscale certificates
    services.tailscale.permitCertUid = "caddy";
  };
}
