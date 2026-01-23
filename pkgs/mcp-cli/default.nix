{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  cacert,
}:

let
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "philschmid";
    repo = "mcp-cli";
    rev = "v${version}";
    hash = "sha256-S924rqlVKzUFD63NDyK5bbXnonra+/UoH6j78AAj3d0=";
  };

  # Fixed-output derivation to fetch npm dependencies
  # This runs with network access and produces a reproducible output
  node_modules = stdenv.mkDerivation {
    pname = "mcp-cli-node-modules";
    inherit version src;

    nativeBuildInputs = [ bun cacert ];

    # This is a fixed-output derivation - it has network access
    # but must produce the same output given the same inputs
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-EaOeDJsVNtsCvRzAs5BveanDlnh2Wm6tr5GkyQS23cM=";

    buildPhase = ''
      runHook preBuild

      # Bun stores cache in home directory
      export HOME=$TMPDIR

      # Install dependencies
      bun install --frozen-lockfile

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r node_modules $out
      runHook postInstall
    '';

    # Don't try to strip or patch the node_modules
    dontStrip = true;
    dontPatchELF = true;
    dontFixup = true;
  };

in
stdenv.mkDerivation {
  pname = "mcp-cli";
  inherit version src;

  nativeBuildInputs = [ bun ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    # Copy pre-fetched node_modules (can't symlink - bun needs to resolve deps)
    cp -r ${node_modules} node_modules
    chmod -R u+w node_modules

    # Build the standalone binary
    bun build --compile --minify src/index.ts --outfile dist/mcp-cli

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 dist/mcp-cli $out/bin/mcp-cli
    runHook postInstall
  '';

  # CRITICAL: Don't strip the binary - Bun embeds JavaScript at the end of the ELF
  # Stripping removes the embedded code, leaving only the Bun runtime
  dontStrip = true;

  meta = with lib; {
    description = "Lightweight CLI to interact with MCP servers for dynamic tool discovery";
    homepage = "https://github.com/philschmid/mcp-cli";
    changelog = "https://github.com/philschmid/mcp-cli/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = [ ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "mcp-cli";
  };
}
