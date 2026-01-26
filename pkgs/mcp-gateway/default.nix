{
  lib,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "mcp-gateway";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    fastapi
    uvicorn
    jinja2
    pydantic
    httpx
    mcp
  ];

  # Copy templates to the package
  postInstall = ''
    # Templates are included in the wheel via hatch
    # Ensure they're accessible at runtime
    templates_src="$out/lib/python*/site-packages/mcp_gateway/templates"
    if [ -d $templates_src ]; then
      echo "Templates already installed"
    else
      mkdir -p $out/lib/python*/site-packages/mcp_gateway/templates
      cp -r src/mcp_gateway/templates/* $out/lib/python*/site-packages/mcp_gateway/templates/
    fi
  '';

  meta = with lib; {
    description = "REST API gateway for Model Context Protocol servers";
    homepage = "https://github.com/kcalvelli/axios";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "mcp-gateway";
    platforms = platforms.linux;
  };
}
