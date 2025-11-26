# Rust development environment with Fenix stable toolchain
# Includes common build dependencies and development tools
{
  pkgs,
  inputs,
  system,
}:
let
  mkShell = inputs.devshell.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mkShell;
  fenixPkgs = inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system};
  toolchain = fenixPkgs.stable.toolchain; # or .default.toolchain for nightly
in
mkShell {
  name = "rust";

  # IMPORTANT: do NOT add a separate rust-analyzer here if the toolchain includes it.
  packages = [
    toolchain
    pkgs.pkg-config
    pkgs.openssl
    pkgs.cmake
    pkgs.python3
    pkgs.cargo-watch
  ];

  commands = [
    {
      name = "check";
      command = "cargo check";
      help = "Type-check code";
    }
    {
      name = "test";
      command = "cargo test";
      help = "Run tests";
    }
    {
      name = "fmt";
      command = "cargo fmt";
      help = "Format code";
    }
    {
      name = "lint";
      command = "cargo clippy -- -D warnings";
      help = "Clippy (deny warnings)";
    }
    {
      name = "run";
      command = "cargo run";
      help = "Build and run";
    }
    {
      name = "watch";
      command = "cargo watch -x check -x test";
      help = "Watch mode (auto check and test)";
    }
    {
      name = "doc";
      command = "cargo doc --open";
      help = "Build and open docs";
    }
    {
      name = "rust-info";
      help = "Show information about this dev shell";
      command = ''
        echo "=== Rust Development Shell ==="
        echo "Purpose: Rust development with Fenix stable toolchain"
        echo ""
        echo "Available commands:"
        echo "  check        - Type-check code"
        echo "  test         - Run tests"
        echo "  fmt          - Format code"
        echo "  lint         - Run clippy with warnings as errors"
        echo "  run          - Build and run"
        echo "  watch        - Auto check and test on file changes"
        echo "  doc          - Build and open documentation"
        echo "  rust-info    - Show this information"
        echo ""
        echo "Toolchain:"
        echo "  Rust: $(rustc --version)"
        echo "  Cargo: $(cargo --version)"
        echo "  Clippy: $(cargo clippy --version | head -1)"
        echo "  rust-analyzer: $(rust-analyzer --version | head -1)"
      '';
    }
  ];
}
