# Immich Home Module: PWA registration via central generator
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  immichCfg = osConfig.axios.immich or { };
  isEnabled = immichCfg.enable or false;
  pwaEnabled = immichCfg.pwa.enable or false;
  tailnetDomain = immichCfg.pwa.tailnetDomain or "";
  pwaUrl = "https://axios-immich.${tailnetDomain}/";
in
{
  config = lib.mkIf (isEnabled && pwaEnabled) {
    axios.pwa.apps.axios-immich = {
      name = "Axios Photos";
      url = pwaUrl;
      icon = "axios-immich";
      categories = [
        "Graphics"
        "Photography"
      ];
      isolated = true;
      description = "Photo and video backup powered by Immich";
    };
  };
}
