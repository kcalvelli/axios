{ config, lib, pkgs, ... }:

let
  cfg = config.services.ai;
  domain = config.networking.hostName;
  tailnet = config.networking.tailscale.domain;
  hasTailscaleDomain = tailnet != null;
in
{
  options = {
    services.ai.openWebUI = {
      enable = lib.mkEnableOption "Open WebUI for Ollama";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.openWebUI.enable) {
    # Open WebUI service
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = 8080;
      openFirewall = true;
      environment = {
        STATIC_DIR = "${config.services.open-webui.stateDir}/static";
        DATA_DIR = "${config.services.open-webui.stateDir}/data";
        HF_HOME = "${config.services.open-webui.stateDir}/hf_home";
        SENTENCE_TRANSFORMERS_HOME = "${config.services.open-webui.stateDir}/transformers_home";
        # WEBUI_URL is conditionally set below if Tailscale domain exists
      } // lib.optionalAttrs hasTailscaleDomain {
        WEBUI_URL = "http://${domain}.${tailnet}";
      };
    };

    # Caddy reverse proxy (only if Tailscale domain is configured)
    services.caddy = lib.mkIf hasTailscaleDomain {
      enable = true;
      globalConfig = ''
        servers {
          metrics
        }
      '';
      
      virtualHosts."${domain}.${tailnet}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:8080
        '';
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf hasTailscaleDomain [ 80 443 ];

    # Integrate with Tailscale for TLS certificates
    services.tailscale.permitCertUid = lib.mkIf hasTailscaleDomain config.services.caddy.user;
  };
}
