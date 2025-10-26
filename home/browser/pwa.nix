{ pkgs, lib, ... }:
let
  braveExe = lib.getExe pkgs.brave;
  pwaDefs = import ../../pkgs/pwa-apps/pwa-defs.nix;
  
  # Helper to create desktop entry for a PWA
  makePWAEntry = pwaId: pwa: {
    name = pwa.name;
    exec = "${braveExe} --app=${pwa.url}";
    icon = pwaId;
    terminal = false;
    type = "Application";
    categories = pwa.categories or [ "Network" ];
    mimeType = pwa.mimeTypes or [];
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
