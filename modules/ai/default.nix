{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.services.ai;
  domain = config.networking.hostName;
  tailnet = "taile0fb4.ts.net";
in
{
  imports = [
    ./ollama.nix
    ./packages.nix
  ];

  options = {
    services.ai = {
      enable = lib.mkEnableOption "AI tools and services (copilot-cli, claude-code, ollama, openwebui)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add all users with home-manager config to systemd-journal group
    # This allows mcp-journal to read system logs
    users.users = lib.mapAttrs (name: user: {
      extraGroups = (user.extraGroups or []) ++ [ "systemd-journal" ];
    }) (lib.filterAttrs (name: user: user.isNormalUser or false) config.users.users);

    # Caddy reverse proxy for OpenWebUI
    services.caddy.virtualHosts."${domain}.${tailnet}" = {
      extraConfig = ''
        handle_path /ai/* {
          reverse_proxy http://127.0.0.1:8080
        }
      '';
    };
  };
}
