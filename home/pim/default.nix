# PIM Home Module: cairn-mail user configuration and PWA registration
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:
let
  # Get PIM config from NixOS system config
  pimCfg = osConfig.services.pim or { };
  isEnabled = pimCfg.enable or false;
  isServer = (pimCfg.role or "server") == "server";

  # PWA URL: always HTTPS via Tailscale Services FQDN
  # Server uses loopback proxy (nginx on 127.0.0.1:443 with LE cert)
  # Client resolves via Tailscale DNS to the VIP
  tailnetDomain = pimCfg.pwa.tailnetDomain or "";
  pwaUrl = "https://cairn-mail.${tailnetDomain}/";
in
{
  # Import cairn-mail home module for server role (provides account config options)
  imports = lib.optional (
    isServer && inputs ? cairn-mail
  ) inputs.cairn-mail.homeManagerModules.default;

  config = lib.mkIf isEnabled {
    # Register PWA via central generator
    cairn.pwa.apps.cairn-mail = lib.mkIf (pimCfg.pwa.enable or false) {
      name = "Cairn Mail";
      url = pwaUrl;
      icon = "cairn-mail";
      categories = [
        "Network"
        "Email"
      ];
      isolated = true;
      description = "AI-powered email management";
    };
  };
}
