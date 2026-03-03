{
  stdenv,
  lib,
  glibcLocales,
  axiosRev ? null,
  axiosNarHash ? null,
}:

let
  rev = if axiosRev != null then axiosRev else "unknown";
  narHash = if axiosNarHash != null then axiosNarHash else "";

  # Minimal flake.lock pinning the axios input to the ISO build revision
  flakeLock = builtins.toJSON {
    version = 7;
    nodes = {
      root = {
        inputs = {
          axios = "axios";
        };
      };
      axios = {
        locked = {
          type = "github";
          owner = "kcalvelli";
          repo = "axios";
          inherit rev narHash;
        };
        original = {
          type = "github";
          owner = "kcalvelli";
          repo = "axios";
        };
      };
    };
  };
in
stdenv.mkDerivation {
  pname = "calamares-axios-extensions";
  version = "0.1.0";

  src = ./src;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{etc,lib,share}/calamares
    cp -r modules $out/lib/calamares/
    cp -r config/* $out/etc/calamares/
    cp -r branding $out/share/calamares/

    substituteInPlace $out/etc/calamares/settings.conf --replace-fail @out@ $out
    substituteInPlace $out/etc/calamares/modules/locale.conf --replace-fail @glibcLocales@ ${glibcLocales}

    # Write pre-baked flake.lock for the axios job module
    cp ${builtins.toFile "flake.lock" flakeLock} $out/lib/calamares/modules/axios/flake.lock

    runHook postInstall
  '';

  meta = {
    description = "Calamares modules for axiOS";
    homepage = "https://github.com/kcalvelli/axios";
    license = with lib.licenses; [
      mit
      cc-by-40
      cc-by-sa-40
    ];
    platforms = lib.platforms.linux;
  };
}
