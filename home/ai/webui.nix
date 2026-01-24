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

  # Tailscale config for detecting Services mode
  tsCfg = osConfig.networking.tailscale or { };
  useServices = (tsCfg.authMode or "interactive") == "authkey";

  # PWA URL generation
  # When Tailscale Services enabled: use service DNS name (no port)
  # Legacy mode: use hostname:port format
  tailnetDomain = webuiCfg.pwa.tailnetDomain or "";

  pwaUrl =
    if useServices then
      # Tailscale Services: unique DNS name per service
      "https://axios-chat.${tailnetDomain}/"
    else
      # Legacy: hostname with port
      let
        effectiveHost =
          if isClient then
            webuiCfg.serverHost or "localhost"
          else
            osConfig.networking.hostName or "localhost";
        httpsPort =
          if isClient then
            toString (webuiCfg.serverPort or 8444)
          else
            toString (webuiCfg.tailscaleServe.httpsPort or 8444);
      in
      "https://${effectiveHost}.${tailnetDomain}:${httpsPort}/";

  # Unique window class for this PWA
  # --class only works when combined with --user-data-dir (Chromium bug #118613)
  # Each PWA gets its own profile to enable unique window class
  wmClass = "axios-ai-chat";
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/chat";

  pwaEnabled = webuiCfg.pwa.enable or false;
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    # PWA desktop entry (both server and client roles)
    xdg.desktopEntries.axios-ai-chat = {
      name = "Axios AI Chat";
      comment = "AI chat interface powered by local LLMs";
      exec = "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass} --app=${pwaUrl}";
      icon = "axios-ai-chat";
      terminal = false;
      categories = [
        "Network"
        "Chat"
        "ArtificialIntelligence"
      ];
      settings = {
        StartupWMClass = wmClass;
      };
    };

    # Install PWA icon
    home.file.".local/share/icons/hicolor/128x128/apps/axios-ai-chat.png" = {
      source = ../resources/pwa-icons/axios-ai-chat.png;
    };
  };
}
