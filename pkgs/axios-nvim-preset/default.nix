{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "axios-nvim-preset";
  version = "1.0.3";

  src = ./lua;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lua
    cp -r . $out/lua/axios
    runHook postInstall
  '';

  meta = with lib; {
    description = "axiOS neovim IDE preset - full-featured development environment";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
