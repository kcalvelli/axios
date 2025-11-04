{ pkgs, ... }:
{
  # Progressive Web Apps
  # These PWAs work immediately without requiring manual installation in the browser.
  # Icons are bundled in the Nix store and desktop entries are generated with correct
  # StartupWMClass matching Brave's app-id format.

  # Install the PWA package with bundled icons, launchers, and desktop entries
  home.packages = [ pkgs.pwa-apps ];
}
