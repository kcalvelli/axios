{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.services.ai;
in
{
  config = lib.mkIf cfg.enable {
    # AI tools from various sources
    environment.systemPackages = with pkgs; [
      # AI assistant tools
      whisper-cpp
      lmstudio
      nodejs # For npx MCP servers
      python3 # For mcpo venv
      mcp-chat # Custom CLI for using MCP tools with local Ollama models      
    ] ++ (with inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}; [
      copilot-cli
      claude-code
    ]);
  };
}
