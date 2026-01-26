# MCP Gateway Home Module: PWA desktop entry generation
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  # Get gateway config from NixOS system config
  gatewayCfg = osConfig.services.ai.mcpGateway or { };
  isEnabled = gatewayCfg.enable or false;
  isServer = (gatewayCfg.role or "server") == "server";

  # PWA URL differs based on role:
  # - Server: Uses local domain (hairpinning restriction prevents VIP access)
  # - Client: Uses Tailscale Services DNS name
  tailnetDomain = gatewayCfg.pwa.tailnetDomain or "";
  localPort = gatewayCfg.port or 8085;

  pwaUrl =
    if isServer then
      # Server uses local domain via /etc/hosts (unique domain for app_id)
      "http://axios-mcp-gateway.local:${toString localPort}/"
    else
      # Client uses Tailscale Services
      "https://axios-mcp-gateway.${tailnetDomain}/";

  # PWA data directory for isolated profile
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/mcp-gateway";

  # Chromium/Brave on Wayland ignores --class and generates app_id from URL
  # Pattern: brave-{domain}__-Default (port is ignored, path / becomes -)
  # We must set StartupWMClass to match this generated app_id for dock icons to work
  pwaHost = if isServer then "axios-mcp-gateway.local" else "axios-mcp-gateway.${tailnetDomain}";
  wmClass = "brave-${pwaHost}__-Default";

  pwaEnabled = gatewayCfg.pwa.enable or false;
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    # PWA desktop entry (both server and client roles)
    xdg.desktopEntries.axios-mcp-gateway = {
      name = "Axios MCP Gateway";
      comment = "REST API gateway for MCP servers with orchestrator UI";
      exec = "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass} --app=${pwaUrl}";
      icon = "axios-mcp-gateway";
      terminal = false;
      categories = [
        "Network"
        "Development"
        "ArtificialIntelligence"
      ];
      settings = {
        StartupWMClass = wmClass;
      };
    };

    # Install PWA icon
    # TODO: Create axios-mcp-gateway.png icon following axios pattern
    # For now, fall back to a generic icon
    # home.file.".local/share/icons/hicolor/128x128/apps/axios-mcp-gateway.png" = {
    #   source = ../resources/pwa-icons/axios-mcp-gateway.png;
    # };
  };
}
