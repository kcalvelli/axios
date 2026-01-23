# Open WebUI Home Module: PWA desktop entry generation
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  # Get webui config from NixOS system config
  webuiCfg = osConfig.services.ai.webui or { };
  isEnabled = webuiCfg.enable or false;
  isServer = (webuiCfg.role or "server") == "server";
  isClient = (webuiCfg.role or "server") == "client";

  # PWA URL generation
  effectiveHost =
    if isClient then
      webuiCfg.serverHost or "localhost"
    else
      osConfig.networking.hostName or "localhost";

  tailnetDomain = webuiCfg.pwa.tailnetDomain or "";

  # Use serverPort for client, tailscaleServe.httpsPort for server
  httpsPort =
    if isClient then
      toString (webuiCfg.serverPort or 8444)
    else
      toString (webuiCfg.tailscaleServe.httpsPort or 8444);

  pwaUrl = "https://${effectiveHost}.${tailnetDomain}:${httpsPort}/";

  # Generate Brave app-id for StartupWMClass
  # Brave uses a specific format: brave-{domain}__-Default (port is stripped)
  urlToAppId =
    url:
    let
      withoutProtocol = lib.removePrefix "https://" url;
      parts = lib.splitString "/" withoutProtocol;
      domainWithPort = lib.head parts;
      # Strip port number if present (e.g., "host:8444" -> "host")
      domain = lib.head (lib.splitString ":" domainWithPort);
    in
    "brave-${domain}__-Default";

  pwaEnabled = webuiCfg.pwa.enable or false;
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    # PWA desktop entry (both server and client roles)
    xdg.desktopEntries.axios-ai-chat = {
      name = "Axios AI Chat";
      comment = "AI chat interface powered by local LLMs";
      exec = "${lib.getExe pkgs.brave} --app=${pwaUrl}";
      icon = "axios-ai-chat";
      terminal = false;
      categories = [
        "Network"
        "Chat"
        "ArtificialIntelligence"
      ];
      settings = {
        StartupWMClass = urlToAppId pwaUrl;
      };
    };

    # Install PWA icon
    home.file.".local/share/icons/hicolor/128x128/apps/axios-ai-chat.png" = {
      source = ../resources/pwa-icons/axios-ai-chat.png;
    };
  };
}
