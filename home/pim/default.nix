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
  pimCfg = osConfig.services.pim or { };
  isEnabled = pimCfg.enable or false;
  isServer = (pimCfg.role or "server") == "server";

  # PWA URL differs based on role:
  # - Server: Uses local domain (hairpinning restriction prevents VIP access)
  # - Client: Uses Tailscale Services DNS name
  tailnetDomain = pimCfg.pwa.tailnetDomain or "";
  localPort = pimCfg.port or 8080;

  pwaUrl =
    if isServer then
      # Server uses local domain via /etc/hosts (unique domain for app_id)
      "http://axios-mail.local:${toString localPort}/"
    else
      # Client uses Tailscale Services
      "https://axios-mail.${tailnetDomain}/";

  # PWA data directory for isolated profile
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/mail";

  # Chromium/Brave on Wayland ignores --class and generates app_id from URL
  # Pattern: brave-{domain}__-Default (port is ignored, path / becomes -)
  # We must set StartupWMClass to match this generated app_id for dock icons to work
  pwaHost = if isServer then "axios-mail.local" else "axios-mail.${tailnetDomain}";
  wmClass = "brave-${pwaHost}__-Default";
in
{
  # Import axios-ai-mail home module for server role (provides account config options)
  imports = lib.optional (
    isServer && inputs ? axios-ai-mail
  ) inputs.axios-ai-mail.homeManagerModules.default;

  config = lib.mkIf isEnabled {
    # PWA desktop entry (both server and client roles)
    xdg.desktopEntries.axios-mail = lib.mkIf (pimCfg.pwa.enable or false) {
      name = "Axios Mail";
      comment = "AI-powered email management";
      exec =
        "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass}"
        + lib.optionalString isServer " --test-type --unsafely-treat-insecure-origin-as-secure=http://axios-mail.local:${toString localPort}"
        + " --app=${pwaUrl}";
      icon = "axios-mail";
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
    home.file.".local/share/icons/hicolor/128x128/apps/axios-mail.png" =
      lib.mkIf (pimCfg.pwa.enable or false)
        {
          source = ../resources/pwa-icons/axios-mail.png;
        };
  };
}
