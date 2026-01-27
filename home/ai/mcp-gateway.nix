# MCP Gateway Home Module: PWA desktop entry generation
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  # Get gateway config from NixOS system config (standalone module path)
  gatewayCfg = osConfig.services.mcp-gateway or { };
  isEnabled = gatewayCfg.enable or false;
  pwaEnabled = gatewayCfg.pwa.enable or false;

  # Get Tailscale service name for URL construction
  serviceName = gatewayCfg.tailscaleServe.serviceName or "axios-mcp-gateway";
  tailnetDomain = gatewayCfg.pwa.tailnetDomain or "";
  localPort = gatewayCfg.port or 8085;

  # PWA URL:
  # - Server (tailscaleServe enabled): Uses local domain (hairpinning workaround)
  # - Client: Uses Tailscale Services DNS name
  isServer = gatewayCfg.tailscaleServe.enable or false;
  pwaUrl =
    if isServer then
      # Server uses local domain via /etc/hosts (unique domain for app_id)
      "http://${serviceName}.local:${toString localPort}/"
    else
      # Client uses Tailscale Services
      "https://${serviceName}.${tailnetDomain}/";

  # PWA data directory for isolated profile
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/mcp-gateway";

  # Chromium/Brave on Wayland ignores --class and generates app_id from URL
  # Pattern: brave-{domain}__-Default (port is ignored, path / becomes -)
  # We must set StartupWMClass to match this generated app_id for dock icons to work
  pwaHost = if isServer then "${serviceName}.local" else "${serviceName}.${tailnetDomain}";
  wmClass = "brave-${pwaHost}__-Default";
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    # PWA desktop entry (both server and client roles)
    xdg.desktopEntries.axios-mcp-gateway = {
      name = "MCP Gateway";
      comment = "REST API gateway for MCP servers with orchestrator UI";
      exec = "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass} --app=${pwaUrl}";
      icon = "axios-mcp-gateway";
      terminal = false;
      categories = [
        "Network"
        "Development"
        "Utility"
      ];
      settings = {
        StartupWMClass = wmClass;
      };
    };

    # Install PWA icon
    home.file.".local/share/icons/hicolor/128x128/apps/axios-mcp-gateway.png" = {
      source = ../resources/pwa-icons/axios-mcp-gateway.png;
    };
  };
}
