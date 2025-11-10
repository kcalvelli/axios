{ lib
, python3
, makeWrapper
, substituteInPlace
}:

python3.pkgs.buildPythonApplication {
  pname = "mcp-chat";
  version = "1.0.0";

  src = ./.;

  format = "other";

  propagatedBuildInputs = with python3.pkgs; [
    requests
  ];

  nativeBuildInputs = [
    makeWrapper
    substituteInPlace
  ];

  dontBuild = true;

  postPatch = ''
    substituteInPlace mcp-chat.py \
      --replace "#!/usr/bin/env python3" "#!${python3.interpreter}"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m 755 mcp-chat.py $out/bin/mcp-chat

    # Wrap to ensure Python and dependencies are in PATH
    wrapProgram $out/bin/mcp-chat \
      --prefix PYTHONPATH : "$PYTHONPATH"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Simple CLI for chatting with Ollama models using MCP tools via mcpo";
    homepage = "https://github.com/yourusername/axios";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "mcp-chat";
  };
}
