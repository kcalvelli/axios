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

  # PWA URL: always HTTPS via Tailscale Services FQDN
  # Server uses loopback proxy (nginx on 127.0.0.1:443 with LE cert)
  # Client resolves via Tailscale DNS to the VIP
  tailnetDomain = pimCfg.pwa.tailnetDomain or "";
  pwaUrl = "https://axios-mail.${tailnetDomain}/";

  # PWA data directory for isolated profile
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/mail";

  # Chromium/Brave on Wayland ignores --class and generates app_id from URL
  # Pattern: brave-{domain}__-Default (port is ignored, path / becomes -)
  # We must set StartupWMClass to match this generated app_id for dock icons to work
  pwaHost = "axios-mail.${tailnetDomain}";
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
        "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass}" + " --app=${pwaUrl}";
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
