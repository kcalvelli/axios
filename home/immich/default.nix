# Immich Home Module: PWA desktop entry generation
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  # Get immich config from NixOS system config
  immichCfg = osConfig.selfHosted.immich or { };
  isEnabled = immichCfg.enable or false;
  pwaEnabled = immichCfg.pwa.enable or false;

  # Server role uses local domain (hairpinning workaround)
  # Immich is server-only, so we always use local domain when service is enabled
  tailnetDomain = immichCfg.pwa.tailnetDomain or "";
  localPort = immichCfg.port or 2283;

  pwaUrl =
    if isEnabled then
      # Server uses local domain via /etc/hosts
      "http://axios-immich.local:${toString localPort}/"
    else
      # Client uses Tailscale Services (if configured for client-only PWA)
      "https://axios-immich.${tailnetDomain}/";

  # PWA data directory for isolated profile
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/immich";

  # Chromium/Brave on Wayland ignores --class and generates app_id from URL
  # Pattern: brave-{domain}__-Default (port is ignored, path / becomes -)
  # We must set StartupWMClass to match this generated app_id for dock icons to work
  pwaHost = if isEnabled then "axios-immich.local" else "axios-immich.${tailnetDomain}";
  wmClass = "brave-${pwaHost}__-Default";
in
{
  config = lib.mkIf pwaEnabled {
    # PWA desktop entry
    xdg.desktopEntries.axios-immich = {
      name = "Axios Photos";
      comment = "Photo and video backup powered by Immich";
      exec = "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass} --app=${pwaUrl}";
      icon = "axios-immich";
      terminal = false;
      categories = [
        "Graphics"
        "Photography"
      ];
      settings = {
        StartupWMClass = wmClass;
      };
    };

    # Install PWA icon
    home.file.".local/share/icons/hicolor/128x128/apps/axios-immich.png" = {
      source = ../resources/pwa-icons/axios-immich.png;
    };
  };
}
