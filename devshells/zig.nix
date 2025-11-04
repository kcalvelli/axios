# Zig development environment with latest compiler and language server
# Uses zig-overlay for up-to-date Zig versions
{ pkgs, inputs, system }:
let
  mkShell = inputs.devshell.legacyPackages.${system}.mkShell;
  zigPkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ inputs."zig-overlay".overlays.default ];
  };
in
mkShell {
  name = "zig";

  packages = [
    zigPkgs.zig
    pkgs.zls
    pkgs.cmake
    pkgs.pkg-config
  ];

  commands = [
    { name = "build"; command = "zig build"; help = "Build project"; }
    { name = "run"; command = "zig build run"; help = "Run default target"; }
    { name = "test"; command = "zig build test"; help = "Run tests"; }
    { name = "fmt"; command = "zig fmt ."; help = "Format code"; }
    {
      name = "zig-info";
      help = "Show information about this dev shell";
      command = ''
        echo "=== Zig Development Shell ==="
        echo "Purpose: Zig development with latest compiler"
        echo ""
        echo "Available commands:"
        echo "  build        - Build project"
        echo "  run          - Run default target"
        echo "  test         - Run tests"
        echo "  fmt          - Format code"
        echo "  zig-info     - Show this information"
        echo ""
        echo "Toolchain:"
        echo "  Zig: $(zig version)"
        echo "  ZLS: $(zls --version)"
      '';
    }
  ];
}
