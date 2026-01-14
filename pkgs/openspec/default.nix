{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
}:

stdenv.mkDerivation rec {
  pname = "openspec";
  version = "0.18.0";

  src = fetchFromGitHub {
    owner = "Fission-AI";
    repo = "OpenSpec";
    rev = "v${version}";
    hash = "sha256-OvD9i1MN5U9YqL+JmLETessvatI8Eu2Rwze3ONJqZXc=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    hash = "sha256-vAlqVFaBN7KMlyP4HKbsMkaYrA5Yf2l5a+PLCZ6KOzs=";
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

    # Create the executable wrapper
    cat > $out/bin/openspec <<EOF
    #!${nodejs}/bin/node
    require('$out/lib/node_modules/openspec/bin/openspec.js')
    EOF

    chmod +x $out/bin/openspec
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
