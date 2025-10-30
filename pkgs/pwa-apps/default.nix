{ lib, stdenv, brave, makeDesktopItem, symlinkJoin }:

let
  pwaDefs = import ./pwa-defs.nix;
  iconPath = ../../home/resources/pwa-icons;
  
  # Helper to convert URL to Brave's app-id format for WM_CLASS matching
  # Brave's format: brave-{domain}{path}-Default where path uses __ for /
  urlToAppId = url: 
    let
      withoutProtocol = lib.removePrefix "https://" (lib.removePrefix "http://" url);
      # Replace slashes with double underscores (including trailing slash)
      withUnderscores = lib.replaceStrings ["/"] ["__"] withoutProtocol;
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
    mimeTypes = pwa.mimeTypes or [];
    startupWMClass = urlToAppId pwa.url;
    actions = lib.mapAttrs (actionId: action: {
      name = action.name;
      exec = "${lib.getExe brave} --app=${action.url}";
    }) (pwa.actions or {});
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

      # Install icons
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (pwaId: pwa: ''
        if [ -f ${iconPath}/${pwa.icon}.png ]; then
          cp ${iconPath}/${pwa.icon}.png $out/share/icons/hicolor/128x128/apps/${pwaId}.png
        fi
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
