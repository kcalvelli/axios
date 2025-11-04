{ lib
, python3
, makeWrapper
}:

python3.pkgs.buildPythonApplication {
  pname = "mcp-chat";
  version = "1.0.0";

  src = ./.;

  format = "other";

  propagatedBuildInputs = with python3.pkgs; [
    requests
  ];

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp mcp-chat.py $out/bin/mcp-chat
    chmod +x $out/bin/mcp-chat

    # Add shebang and make executable
    sed -i '1i#!/usr/bin/env python3' $out/bin/mcp-chat

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
