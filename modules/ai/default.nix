{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.services.ai;
in
{
  imports = [
    ./ollama.nix
    ./open-webui.nix
  ];

  options = {
    services.ai = {
      enable = lib.mkEnableOption "AI tools and services (copilot-cli, claude-code, ollama, openwebui)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add users to systemd-journal group using userGroups
    # This avoids infinite recursion by not modifying users.users directly
    users.groups.systemd-journal = {
      members = lib.attrNames (lib.filterAttrs (_name: user: user.isNormalUser or false) config.users.users);
    };

    # AI tools and packages
    environment.systemPackages = with pkgs; [
      # AI assistant tools
      whisper-cpp
      nodejs # For npx MCP servers
      python3 # For mcpo venv
      mcp-chat # CLI for testing MCP servers with local Ollama models
      claude-monitor # Real-time Claude Code usage monitoring
    ] ++ (with inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}; [
      # Claude tools
      copilot-cli # GitHub Copilot CLI
      claude-code # Claude CLI with MCP support
      goose-cli
      code
      claude-code-router
      backlog-md
      crush
      forge
      codex
      catnip
      gemini-cli
    ]);

    # Enable both ollama and open-webui by default when AI is enabled
    # Can be individually disabled if needed
    services.ai.ollama.enable = lib.mkDefault true;
    services.ai.openWebUI.enable = lib.mkDefault true;
  };
}
