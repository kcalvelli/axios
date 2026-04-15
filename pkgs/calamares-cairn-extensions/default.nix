{
  stdenv,
  lib,
  glibcLocales,
}:

stdenv.mkDerivation {
  pname = "calamares-cairn-extensions";
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

    runHook postInstall
  '';

  meta = {
    description = "Calamares modules for Cairn";
    homepage = "https://github.com/kcalvelli/cairn";
    license = with lib.licenses; [
      mit
      cc-by-40
      cc-by-sa-40
    ];
    platforms = lib.platforms.linux;
  };
}
