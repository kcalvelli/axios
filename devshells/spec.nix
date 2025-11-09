# Development shell for Spec-Driven Development using GitHub Spec Kit
# Spec Kit is a methodology toolkit for building software from executable specifications
# rather than a traditional tech stack shell. It works with AI coding agents.
{ pkgs, inputs, system }:
let
  mkShell = inputs.devshell.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mkShell;
in
mkShell {
  name = "spec-kit";

  packages = [
    # Core tools
    pkgs.python311
    pkgs.uv
    pkgs.git
    pkgs.gh
    pkgs.nodejs_20

    # AI Coding Agents
    pkgs.aider-chat # AI pair programming

    # Development utilities
    pkgs.jq # JSON processing
    pkgs.yq-go # YAML processing
    pkgs.ripgrep # Fast grep alternative
    pkgs.fd # Fast find alternative
    pkgs.fzf # Fuzzy finder
    pkgs.bat # Better cat with syntax highlighting
    pkgs.tree # Directory visualization

    # Testing & validation
    pkgs.shellcheck # Shell script linting
    pkgs.pre-commit # Git pre-commit hooks
  ];

  commands = [
    {
      name = "specify";
      help = "Run GitHub Spec Kit CLI via uvx";
      command = ''uvx --from git+https://github.com/github/spec-kit.git specify "$@"'';
    }
    {
      name = "spec-check";
      help = "Check Spec Kit prerequisites and detected AI agents";
      command = "specify check";
    }
    {
      name = "spec-init";
      help = "Initialize a new Spec-Driven Development project";
      command = "specify init \"$@\"";
    }
    {
      name = "spec-info";
      help = "Show information about this dev shell";
      command = ''
        echo "=== Spec-Kit Development Shell ==="
        echo "Purpose: Spec-Driven Development with GitHub Spec Kit"
        echo ""
        echo "Available commands:"
        echo "  specify      - Run Spec Kit CLI"
        echo "  spec-check   - Check prerequisites and AI agents"
        echo "  spec-init    - Initialize new project"
        echo "  spec-info    - Show this information"
        echo "  aider        - AI pair programming assistant"
        echo ""
        echo "Documentation: https://github.com/github/spec-kit"
        echo "Python: $(python --version)"
        echo "uv: $(uv --version)"
        echo "Node.js: $(node --version)"
      '';
    }
    {
      name = "spec-validate";
      help = "Validate spec files in current directory";
      command = ''
        echo "Validating spec files..."
        find . -name "*.spec.md" -o -name "*.spec.yaml" -o -name "*.spec.json" | while read f; do
          echo "  ✓ $f"
        done
      '';
    }
    {
      name = "spec-test";
      help = "Run tests specified in spec files";
      command = "specify test \"$@\"";
    }
  ];

  env = [
    { name = "PIP_DISABLE_PIP_VERSION_CHECK"; value = "1"; }
    { name = "UV_NO_SYNC"; value = "1"; }
    { name = "SPEC_KIT_SHELL"; value = "1"; }
  ];

  devshell.startup.spec_welcome = {
    text = ''
      echo "🔨 Welcome to spec-kit"
      echo ""
      echo "[[AI Coding Agents]]"
      echo ""
      echo "  aider      - AI pair programming (Aider installed)"
      echo "  gh copilot - GitHub Copilot CLI (requires: gh extension install github/gh-copilot)"
      echo ""
    '';
  };
}
