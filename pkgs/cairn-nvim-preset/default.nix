{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "cairn-nvim-preset";
  version = "1.0.4";

  src = ./lua;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lua
    cp -r . $out/lua/cairn
    runHook postInstall
  '';

  meta = with lib; {
    description = "Cairn neovim IDE preset - full-featured development environment";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
