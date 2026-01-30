# PIM Home Module: axios-ai-mail user configuration and PWA registration
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
  pwaUrl = "https://axios-mail.${tailnetDomain}/";
in
{
  # Import axios-ai-mail home module for server role (provides account config options)
  imports = lib.optional (
    isServer && inputs ? axios-ai-mail
  ) inputs.axios-ai-mail.homeManagerModules.default;

  config = lib.mkIf isEnabled {
    # Register PWA via central generator
    axios.pwa.apps.axios-mail = lib.mkIf (pimCfg.pwa.enable or false) {
      name = "Axios Mail";
      url = pwaUrl;
      icon = "axios-mail";
      categories = [
        "Network"
        "Email"
      ];
      isolated = true;
      description = "AI-powered email management";
    };
  };
}
