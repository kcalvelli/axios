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

  # PWA URL: always uses Tailscale Services DNS name
  tailnetDomain = pimCfg.pwa.tailnetDomain or "";
  pwaUrl = "https://axios-mail.${tailnetDomain}/";

  # Unique window class for this PWA
  # --class only works when combined with --user-data-dir (Chromium bug #118613)
  # Each PWA gets its own profile to enable unique window class
  wmClass = "axios-mail";
  pwaDataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/mail";
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
      exec = "${lib.getExe pkgs.brave} --user-data-dir=${pwaDataDir} --class=${wmClass} --app=${pwaUrl}";
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
