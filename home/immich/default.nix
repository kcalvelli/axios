# Immich Home Module: PWA registration via central generator
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  immichCfg = osConfig.cairn.immich or { };
  isEnabled = immichCfg.enable or false;
  pwaEnabled = immichCfg.pwa.enable or false;
  tailnetDomain = immichCfg.pwa.tailnetDomain or "";
  pwaUrl = "https://cairn-immich.${tailnetDomain}/";
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    cairn.pwa.apps.cairn-immich = {
      name = "Cairn Photos";
      url = pwaUrl;
      icon = "cairn-immich";
      categories = [
        "Graphics"
        "Photography"
      ];
      isolated = true;
      description = "Photo and video backup powered by Immich";
    };
  };
}
