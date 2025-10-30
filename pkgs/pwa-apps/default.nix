{ lib, stdenv, brave }:

let
  pwaDefs = import ./pwa-defs.nix;
  iconPath = ../../home/resources/pwa-icons;
  
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

  # Helper to generate a desktop entry
  makeDesktopEntry = pwaId: pwa: 
    let
      categories = if builtins.hasAttr "categories" pwa 
                   then lib.concatStringsSep ";" (pwa.categories ++ [""])
                   else "Network;WebBrowser;";
    in ''
    cat > $out/share/applications/${pwaId}.desktop << 'DESKTOP'
    [Desktop Entry]
    Type=Application
    Name=${pwa.name}
    Comment=Launch ${pwa.name} as a PWA
    Exec=pwa-${pwaId}
    Icon=${pwaId}
    Terminal=false
    Categories=${categories}
    StartupNotify=true
    StartupWMClass=${pwa.name}
    DESKTOP
  '';

in
stdenv.mkDerivation {
  pname = "pwa-apps";
  version = "1.0.0";

  src = iconPath;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Create directories
    mkdir -p $out/bin
    mkdir -p $out/share/icons/hicolor/128x128/apps
    mkdir -p $out/share/applications

    # Install icons
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (pwaId: pwa: ''
      if [ -f ${iconPath}/${pwa.icon}.png ]; then
        cp ${iconPath}/${pwa.icon}.png $out/share/icons/hicolor/128x128/apps/${pwaId}.png
      fi
    '') pwaDefs)}

    # Generate launcher scripts
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList makePWALauncher pwaDefs)}

    # Generate desktop entries
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList makeDesktopEntry pwaDefs)}

    runHook postInstall
  '';

  # No postInstall needed - icons will be found in standard hicolor location
  # Desktop environments merge all icon directories automatically

  meta = with lib; {
    description = "Progressive Web App collection with bundled icons and launchers";
    platforms = platforms.linux;
  };
}
