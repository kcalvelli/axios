# QML/Qt6 development environment for Quickshell development
# Includes Qt6, QML tools, and all dependencies needed for building Quickshell
{
  pkgs,
  inputs,
}:
let
  mkShell = inputs.devshell.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mkShell;
in
mkShell {
  name = "qml";

  packages = with pkgs; [
    # Build system
    cmake
    ninja
    pkg-config
    just # Quickshell uses just for dev commands

    # Qt6 packages (qt6.full was removed, use individual packages)
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtwayland
    qt6.qtshadertools
    spirv-tools

    # Quickshell dependencies
    cli11
    breakpad
    jemalloc

    # Wayland support
    wayland
    wayland-protocols
    wayland-scanner

    # Additional features
    libxcb # X11 support
    pipewire # Pipewire support
    pam # PAM authentication
    libdrm # Screencopy
    libgbm # Screencopy

    # Development tools
    clang-tools # clang-format for code formatting
    clang # C/C++ compiler
    gdb # Debugging
    valgrind # Memory profiling
  ];

  commands = [
    {
      name = "configure";
      command = "cmake -GNinja -B build -DCMAKE_BUILD_TYPE=\${1:-RelWithDebInfo} \${@:2}";
      help = "Configure build (usage: configure [debug|release] [extra cmake args])";
    }
    {
      name = "build";
      command = "cmake --build build";
      help = "Build the project";
    }
    {
      name = "clean";
      command = "rm -rf build";
      help = "Clean build directory";
    }
    {
      name = "install";
      command = "cmake --install build";
      help = "Install the built project";
    }
    {
      name = "fmt";
      command = "just fmt";
      help = "Format code with clang-format";
    }
    {
      name = "qml-info";
      help = "Show information about this dev shell";
      command = ''
        echo "=== QML/Qt6 Development Shell ==="
        echo "Purpose: Quickshell and QML application development"
        echo ""
        echo "Available commands:"
        echo "  configure    - Configure build with CMake"
        echo "  build        - Build the project"
        echo "  clean        - Clean build directory"
        echo "  install      - Install built project"
        echo "  fmt          - Format code (requires justfile)"
        echo "  qml-info     - Show this information"
        echo ""
        echo "If in a Quickshell project, you can also use 'just' commands:"
        echo "  just configure [debug|release]"
        echo "  just build"
        echo "  just run [args]"
        echo "  just clean"
        echo "  just fmt"
        echo ""
        echo "Toolchain:"
        echo "  Qt: $(qmake -query QT_VERSION)"
        echo "  CMake: $(cmake --version | head -1)"
        echo "  Ninja: $(ninja --version)"
        echo "  Clang: $(clang --version | head -1)"
      '';
    }
  ];

  env = [
    # Set Qt6 to use Wayland by default
    {
      name = "QT_QPA_PLATFORM";
      value = "wayland";
    }
    # Enable QML debugging
    {
      name = "QML_IMPORT_TRACE";
      value = "1";
    }
  ];
}
