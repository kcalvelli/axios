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

  # PWA URL differs based on role:
  # - Server: Uses local domain (hairpinning restriction prevents VIP access)
  # - Client: Uses Tailscale Services DNS name
  tailnetDomain = webuiCfg.pwa.tailnetDomain or "";
  localPort = webuiCfg.port or 8081;

  pwaUrl =
    if isServer then
      # Server uses local domain via /etc/hosts (unique domain for app_id)
      "http://axios-ai-chat.local:${toString localPort}/"
    else
      # Client uses Tailscale Services
      "https://axios-ai-chat.${tailnetDomain}/";

  # PWA data directory for isolated profile
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/chat";

  # Chromium/Brave on Wayland ignores --class and generates app_id from URL
  # Pattern: brave-{domain}__-Default (port is ignored, path / becomes -)
  # We must set StartupWMClass to match this generated app_id for dock icons to work
  pwaHost = if isServer then "axios-ai-chat.local" else "axios-ai-chat.${tailnetDomain}";
  wmClass = "brave-${pwaHost}__-Default";

  pwaEnabled = webuiCfg.pwa.enable or false;
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    # PWA desktop entry (both server and client roles)
    xdg.desktopEntries.axios-ai-chat = {
      name = "Axios AI Chat";
      comment = "AI chat interface powered by local LLMs";
      # --disable-features=BraveAdBlock needed for External Tools to connect to mcp-gateway
      exec = "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass} --disable-features=BraveAdBlock --app=${pwaUrl}";
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
