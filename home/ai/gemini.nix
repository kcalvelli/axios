{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.ai;

  # Wrapper script for spec-aware architecture queries
  geminiArchitect = pkgs.writeShellScriptBin "gemini-architect" ''
    if [ -z "$GEMINI_API_KEY" ]; then
      echo "Error: GEMINI_API_KEY is not set."
      exit 1
    fi

    SPEC_DIR=$(git rev-parse --show-toplevel)/spec-kit-baseline

    if [ ! -d "$SPEC_DIR" ]; then
      echo "Error: spec-kit-baseline directory not found."
      exit 1
    fi

    # Construct prompt with context
    CONTEXT="You are the Lead Architect for axios. Answer the following question based strictly on these specs:"

    # Use gemini-cli to process
    ${inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli}/bin/gemini \
      --system "$CONTEXT" \
      --context "$SPEC_DIR/constitution.md" \
      --context "$SPEC_DIR/spec.md" \
      --context "$SPEC_DIR/plan.md" \
      "$@"
  '';

  # Wrapper script for spec compliance review
  geminiReview = pkgs.writeShellScriptBin "gemini-review" ''
    if [ -z "$GEMINI_API_KEY" ]; then
      echo "Error: GEMINI_API_KEY is not set."
      exit 1
    fi

    SPEC_DIR=$(git rev-parse --show-toplevel)/spec-kit-baseline

    if [ ! -d "$SPEC_DIR" ]; then
      echo "Error: spec-kit-baseline directory not found."
      exit 1
    fi

    DIFF=$(git diff --cached)
    if [ -z "$DIFF" ]; then
       DIFF=$(git diff HEAD)
    fi

    if [ -z "$DIFF" ]; then
      echo "No changes to review."
      exit 0
    fi

    CONTEXT="Review this code change against the project Constitution. Flag ANY violations of non-negotiable rules. Be concise."

    echo "$DIFF" | ${
      inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli
    }/bin/gemini \
      --system "$CONTEXT" \
      --context "$SPEC_DIR/constitution.md" \
      --context "$SPEC_DIR/spec.md"
  '';

in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      geminiArchitect
      geminiReview
    ];
  };
}
