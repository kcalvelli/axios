{ pkgs, lib, ... }:
let
  braveExe = lib.getExe pkgs.brave;
  pwaDefs = import ../../pkgs/pwa-apps/pwa-defs.nix;
  
  # Helper to convert URL to Brave's app-id format
  # Example: https://messages.google.com/web -> messages.google.com__web
  urlToAppId = url: 
    let
      # Remove https:// or http://
      withoutProtocol = lib.removePrefix "https://" (lib.removePrefix "http://" url);
      # Replace slashes with double underscores
      withUnderscores = lib.replaceStrings ["/"] ["__"] withoutProtocol;
    in
      withUnderscores;
  
  # Helper to create desktop entry for a PWA
  makePWAEntry = pwaId: pwa: {
    name = pwa.name;
    exec = "${braveExe} --app=${pwa.url}";
    icon = pwaId;
    terminal = false;
    type = "Application";
    categories = pwa.categories or [ "Network" ];
    mimeType = pwa.mimeTypes or [];
    settings = {
      # Set StartupWMClass to match what Brave actually uses
      StartupWMClass = "brave-${urlToAppId pwa.url}-Default";
    };
    actions = lib.mapAttrs (actionId: action: {
      name = action.name;
      exec = "${braveExe} --app=${action.url}";
    }) (pwa.actions or {});
  };
  
in
{
  # Progressive Web Apps
  # These PWAs work immediately without requiring manual installation in the browser.
  # Icons are bundled in the Nix store and desktop entries use direct URLs.
  
  # Install the PWA package with bundled icons
  home.packages = [ pkgs.pwa-apps ];
  
  # Generate desktop entries for all PWAs
  xdg.desktopEntries = lib.mapAttrs makePWAEntry pwaDefs;
}
