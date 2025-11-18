{ lib, stdenv, brave, makeDesktopItem, symlinkJoin
, extraDefs ? {}
, extraIconPaths ? []
}:

let
  baseDefs = import ./pwa-defs.nix;
  pwaDefs = baseDefs // extraDefs;
  baseIconPath = ../../home/resources/pwa-icons;

  # Helper to convert URL to Brave's app-id format for WM_CLASS matching
  # Brave's format: brave-{domain}{path}-Default where path uses __ for /
  urlToAppId = url:
    let
      withoutProtocol = lib.removePrefix "https://" (lib.removePrefix "http://" url);
      # Replace slashes with double underscores (including trailing slash)
      withUnderscores = lib.replaceStrings [ "/" ] [ "__" ] withoutProtocol;
    in
    "brave-${withUnderscores}-Default";

  # Helper to generate a PWA launcher script
  makePWALauncher = pwaId: pwa: ''
    cat > $out/bin/pwa-${pwaId} << 'LAUNCHER'
    #!/usr/bin/env bash
    # PWA Launcher for ${pwa.name}
    # Launches as a proper web app using Brave's app mode
    exec ${lib.getExe brave} --app=${pwa.url} "$@"
    LAUNCHER
    chmod +x $out/bin/pwa-${pwaId}
  '';

  # Create desktop entry for a PWA using makeDesktopItem
  makePWADesktopItem = pwaId: pwa: makeDesktopItem {
    name = pwaId;
    desktopName = pwa.name;
    comment = "Launch ${pwa.name} as a PWA";
    exec = "pwa-${pwaId}";
    icon = pwaId;
    terminal = false;
    type = "Application";
    categories = pwa.categories or [ "Network" ];
    mimeTypes = pwa.mimeTypes or [ ];
    startupWMClass = urlToAppId pwa.url;
    actions = lib.mapAttrs
      (_actionId: action: {
        name = action.name;
        exec = "${lib.getExe brave} --app=${action.url}";
      })
      (pwa.actions or { });
  };

  # Create launchers package
  launchers = stdenv.mkDerivation {
    pname = "pwa-apps-launchers";
    version = "1.0.0";

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # Create directories
      mkdir -p $out/bin
      mkdir -p $out/share/icons/hicolor/128x128/apps

      # Install icons from base path and extra paths
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (pwaId: pwa: ''
        icon_found=false
        # Check base icon path first
        if [ -f ${baseIconPath}/${pwa.icon}.png ]; then
          cp ${baseIconPath}/${pwa.icon}.png $out/share/icons/hicolor/128x128/apps/${pwaId}.png
          icon_found=true
        fi
        # Check extra icon paths if not found
        ${lib.concatStringsSep "\n" (map (extraPath: ''
          if [ "$icon_found" = false ] && [ -f ${extraPath}/${pwa.icon}.png ]; then
            cp ${extraPath}/${pwa.icon}.png $out/share/icons/hicolor/128x128/apps/${pwaId}.png
            icon_found=true
          fi
        '') extraIconPaths)}
      '') pwaDefs)}

      # Generate launcher scripts
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList makePWALauncher pwaDefs)}

      runHook postInstall
    '';
  };

  # Create list of desktop items
  desktopItems = lib.mapAttrsToList makePWADesktopItem pwaDefs;

in
symlinkJoin {
  name = "pwa-apps";
  paths = [ launchers ] ++ desktopItems;

  meta = with lib; {
    description = "Progressive Web App collection with bundled icons and launchers";
    platforms = platforms.linux;
  };
}
