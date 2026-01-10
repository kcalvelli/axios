{
  lib,
  stdenv,
  fetchurl,
  ...
}:

stdenv.mkDerivation rec {
  pname = "mcp-cli";
  version = "0.1.3";

  src = fetchurl {
    url = "https://github.com/philschmid/mcp-cli/releases/download/v${version}/mcp-cli-linux-x64";
    hash = "sha256-J13r3KU5Si32K3FUak5k4P9UdGnQyT+kHko29+IVek4=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontPatchELF = true;  # Don't modify the binary
  dontStrip = true;     # Don't strip the binary

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/mcp-cli
    runHook postInstall
  '';

  meta = with lib; {
    description = "Lightweight CLI to interact with MCP servers for dynamic tool discovery";
    homepage = "https://github.com/philschmid/mcp-cli";
    license = licenses.mit;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "mcp-cli";
  };
}
