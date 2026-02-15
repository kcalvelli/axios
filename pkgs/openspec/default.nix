{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "openspec";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "Fission-AI";
    repo = "OpenSpec";
    rev = "v${version}";
    hash = "sha256-XdE8WGXdBm9FQKZJIJtnPCqpD20ontpINlfmqFmts3U=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    hash = "sha256-FToFJ7TnChnKCVLreTd2zJyiuHt8gdEBsMKk6F+uoao=";
    fetcherVersion = 3;
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/openspec
    cp -r . $out/lib/node_modules/openspec
    mkdir -p $out/bin

    # Create the executable wrapper with telemetry disabled
    makeWrapper ${nodejs}/bin/node $out/bin/openspec \
      --add-flags "$out/lib/node_modules/openspec/bin/openspec.js" \
      --set OPENSPEC_TELEMETRY 0
    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source software for spec-driven development with AI coding assistants";
    homepage = "https://github.com/Fission-AI/OpenSpec";
    license = licenses.mit;
    mainProgram = "openspec";
    platforms = platforms.linux;
  };
}
