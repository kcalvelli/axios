{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  ...
}:

stdenv.mkDerivation rec {
  pname = "mcp-cli";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "philschmid";
    repo = "mcp-cli";
    rev = "v${version}";
    hash = "sha256-xEiTWvlOZY51v4diIIAcVSt5MyHQY2Q+wFJMzHtjip8=";
  };

  nativeBuildInputs = [ bun ];

  buildPhase = ''
    runHook preBuild

    # Install dependencies
    bun install --frozen-lockfile

    # Build standalone executable
    bun build --compile --minify --target=bun-linux-x64 src/index.ts --outfile mcp-cli

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 mcp-cli $out/bin/mcp-cli
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
