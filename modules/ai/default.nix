{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.services.ai;

in
{
  options = {
    services.ai = {
      enable = lib.mkEnableOption "AI tools and services (copilot-cli, claude-code)";
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
      claude-monitor # Real-time Claude Code usage monitoring
      (pkgs.writeShellScriptBin "jules" ''
        exec ${pkgs.nodejs_20}/bin/npx @google/jules@latest "$@"
      '')
    ] ++ (
      let
        ai-tools = inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system};
      in
      [
        # AI tools
        ai-tools.copilot-cli # GitHub Copilot CLI
        ai-tools.claude-code # Claude CLI with MCP support
        ai-tools.goose-cli
        ai-tools.claude-code-router
        ai-tools.backlog-md
        ai-tools.crush
        ai-tools.forge
        ai-tools.codex
        ai-tools.catnip
        ai-tools.gemini-cli
        ai-tools.claude-desktop
      ]
    );
  };
}
