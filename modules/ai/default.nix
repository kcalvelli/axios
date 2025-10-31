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
    # Add users to systemd-journal group using userGroups
    # This avoids infinite recursion by not modifying users.users directly
    users.groups.systemd-journal = {
      members = lib.attrNames (lib.filterAttrs (name: user: user.isNormalUser or false) config.users.users);
    };

    # Caddy reverse proxy for OpenWebUI
    # Serve OpenWebUI from root since it doesn't support base paths
    services.caddy.virtualHosts."${domain}.${tailnet}" = {
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8080
      '';
    };
    
    # Pass domain and tailnet to ollama module
    services.open-webui.environment.WEBUI_URL = "http://${domain}.${tailnet}/ai";
  };
}
