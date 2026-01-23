# PIM Home Module: axios-ai-mail user configuration and PWA desktop entry
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
  pimCfg = osConfig.pim or { };
  isEnabled = pimCfg.enable or false;
  isServer = (pimCfg.role or "server") == "server";

  # PWA URL generation
  effectiveHost =
    if pimCfg.pwa.serverHost or null != null then
      pimCfg.pwa.serverHost
    else
      osConfig.networking.hostName or "localhost";
  tailnetDomain = pimCfg.pwa.tailnetDomain or "";
  httpsPort = toString (pimCfg.pwa.httpsPort or 8443);
  pwaUrl = "https://${effectiveHost}.${tailnetDomain}:${httpsPort}/";

  # Unique window class for this PWA
  # Using --class flag to override Brave's default domain-based class
  wmClass = "axios-ai-mail";
in
{
  # Import axios-ai-mail home module for server role (provides account config options)
  imports = lib.optional (
    isServer && inputs ? axios-ai-mail
  ) inputs.axios-ai-mail.homeManagerModules.default;

  config = lib.mkIf isEnabled {
    # PWA desktop entry (both server and client roles)
    xdg.desktopEntries.axios-ai-mail = lib.mkIf (pimCfg.pwa.enable or false) {
      name = "Axios AI Mail";
      comment = "AI-powered email management";
      exec = "${lib.getExe pkgs.brave} --class=${wmClass} --app=${pwaUrl}";
      icon = "axios-ai-mail";
      terminal = false;
      categories = [
        "Network"
        "Email"
      ];
      settings = {
        StartupWMClass = wmClass;
      };
    };

    # Install PWA icon
    home.file.".local/share/icons/hicolor/128x128/apps/axios-ai-mail.png" =
      lib.mkIf (pimCfg.pwa.enable or false)
        {
          source = ../resources/pwa-icons/axios-ai-mail.png;
        };
  };
}
