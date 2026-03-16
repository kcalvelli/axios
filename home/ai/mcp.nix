# MCP Configuration for axios
# This module imports mcp-gateway's home-manager module and configures
# the MCP servers using axios's flake inputs.
#
# mcp-gateway owns the declarative config module and generates all config files.
# axios provides server definitions, prompts, commands, and aliases.
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? { },
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # PIM configuration for calendar paths
  pimCfg = osConfig.services.pim or { };
  calendarAccounts = pimCfg.calendar.accounts or { };

  # Extract unique parent directories from calendar account localPaths
  # Default to ~/.calendars, plus any custom paths like ~/.calendars-external/...
  calendarPaths =
    let
      defaultPath = "~/.calendars";
      # Collect non-null external paths
      externalPaths = lib.unique (
        lib.filter (p: p != null) (
          lib.mapAttrsToList (
            name: account:
            let
              path = account.localPath or null;
              cleanPath = if path != null then lib.removeSuffix "/" path else null;
            in
            # Check for external calendar directories
            if cleanPath != null && lib.hasPrefix "~/.calendars-external" cleanPath then
              "~/.calendars-external"
            else
              null
          ) calendarAccounts
        )
      );
    in
    lib.concatStringsSep ":" ([ defaultPath ] ++ externalPaths);

in
{
  # Import mcp-gateway's home-manager module
  imports = [
    inputs.mcp-gateway.homeManagerModules.default
  ];

  config = lib.mkIf (osConfig.services.ai.mcp.enable or false) {
    # Configure mcp-gateway with axios's server definitions
    services.mcp-gateway = {
      enable = true;

      # Let NixOS manage the systemd service when mcp-gateway NixOS module is enabled
      # (NixOS module handles OAuth secrets via agenix)
      manageService = !(osConfig.services.mcp-gateway.enable or false);

      # Pass through gateway settings from NixOS config (if using NixOS module)
      # Otherwise use defaults
      port = osConfig.services.mcp-gateway.port or 8085;
      autoEnable =
        osConfig.services.mcp-gateway.autoEnable or [
          "github"
          "mcp-dav"
          "axios-ai-mail"
        ];

      # MCP Server Definitions
      # All servers with fully resolved paths from axios inputs
      servers = {
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # CORE TOOLS (No setup required)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        github = {
          enable = true;
          command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
          args = [ "stdio" ];
          passwordCommand = {
            GITHUB_PERSONAL_ACCESS_TOKEN = [
              (lib.getExe config.programs.gh.package)
              "auth"
              "token"
            ];
          };
        };

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # PIM TOOLS (Require services.pim.enable)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        axios-ai-mail = {
          enable = true;
          command = "${inputs.axios-ai-mail.packages.${system}.default}/bin/axios-ai-mail";
          args = [ "mcp" ];
        };

        mcp-dav = {
          enable = true;
          command = "${inputs.axios-dav.packages.${system}.mcp-dav}/bin/mcp-dav";
          env = {
            # Dynamic calendar paths from services.pim.calendar.accounts
            # Supports multiple paths separated by colons (e.g., ~/.calendars:~/.calendars-external)
            MCP_DAV_CALENDARS = calendarPaths;
            MCP_DAV_CONTACTS = "~/.contacts";
          };
        };
      };
    };

    # Install MCP server packages
    home.packages = [
      inputs.axios-ai-mail.packages.${system}.default
      inputs.axios-dav.packages.${system}.mcp-dav
    ];
  };
}
