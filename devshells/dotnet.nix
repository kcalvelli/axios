# .NET development environment with .NET SDK, Mono, and common dependencies
# Includes runtime libraries and development tools for .NET/Avalonia development
{
  pkgs,
  inputs,
}:
let
  mkShell = inputs.devshell.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mkShell;
in
mkShell {
  name = "dotnet";

  packages = with pkgs; [
    # .NET SDK and Mono runtime
    dotnet-sdk_9
    mono

    # Runtime dependencies required by .NET on NixOS
    icu
    fontconfig
    freetype
    libGL

    # Development tools
    ilspycmd # .NET decompiler CLI
    avalonia-ilspy # Avalonia-based .NET decompiler GUI
  ];

  commands = [
    {
      name = "build";
      command = "dotnet build";
      help = "Build the project";
    }
    {
      name = "run";
      command = "dotnet run";
      help = "Run the project";
    }
    {
      name = "test";
      command = "dotnet test";
      help = "Run tests";
    }
    {
      name = "publish";
      command = "dotnet publish -c Release";
      help = "Publish release build";
    }
    {
      name = "clean";
      command = "dotnet clean";
      help = "Clean build artifacts";
    }
    {
      name = "restore";
      command = "dotnet restore";
      help = "Restore NuGet packages";
    }
    {
      name = "watch";
      command = "dotnet watch run";
      help = "Run with file watching (auto-restart)";
    }
    {
      name = "dotnet-info";
      help = "Show information about this dev shell";
      command = ''
        echo "=== .NET Development Shell ==="
        echo "Purpose: .NET and Avalonia application development"
        echo ""
        echo "Available commands:"
        echo "  build        - Build the project"
        echo "  run          - Run the project"
        echo "  test         - Run tests"
        echo "  publish      - Publish release build"
        echo "  clean        - Clean build artifacts"
        echo "  restore      - Restore NuGet packages"
        echo "  watch        - Run with auto-restart on file changes"
        echo "  dotnet-info  - Show this information"
        echo ""
        echo "Toolchain:"
        echo "  .NET: $(dotnet --version)"
        echo "  Mono: $(mono --version | head -1)"
        echo ""
        echo "Environment:"
        echo "  DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 (NixOS compatibility)"
      '';
    }
  ];

  env = [
    # Set globalization to invariant mode for NixOS compatibility
    # This fixes common .NET globalization issues on NixOS
    {
      name = "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT";
      value = "1";
    }
  ];
}
