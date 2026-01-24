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

  # PWA URL: always uses Tailscale Services DNS name
  tailnetDomain = webuiCfg.pwa.tailnetDomain or "";
  pwaUrl = "https://axios-ai-chat.${tailnetDomain}/";

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
