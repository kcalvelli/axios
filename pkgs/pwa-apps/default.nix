{
  lib,
  stdenv,
  extraDefs ? { },
  extraIconPaths ? [ ],
}:

let
  baseDefs = import ./pwa-defs.nix;
  pwaDefs = baseDefs // extraDefs;
  baseIconPath = ../../home/resources/pwa-icons;
in
stdenv.mkDerivation {
  pname = "pwa-apps-icons";
  version = "1.0.0";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/hicolor/128x128/apps

    # Install icons from base path and extra paths
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (pwaId: pwa: ''
        icon_found=false
        # Check base icon path first
        if [ -f ${baseIconPath}/${pwa.icon}.png ]; then
          cp ${baseIconPath}/${pwa.icon}.png $out/share/icons/hicolor/128x128/apps/${pwaId}.png
          icon_found=true
        fi
        # Check extra icon paths if not found
        ${lib.concatStringsSep "\n" (
          map (extraPath: ''
            if [ "$icon_found" = false ] && [ -f ${extraPath}/${pwa.icon}.png ]; then
              cp ${extraPath}/${pwa.icon}.png $out/share/icons/hicolor/128x128/apps/${pwaId}.png
              icon_found=true
            fi
          '') extraIconPaths
        )}
      '') pwaDefs
    )}

    runHook postInstall
  '';

  meta = {
    description = "PWA icon collection for axiOS";
    platforms = lib.platforms.linux;
  };
}
