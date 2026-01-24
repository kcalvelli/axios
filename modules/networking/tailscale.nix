{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.tailscale;
  isAuthKey = cfg.authMode == "authkey";

  # Tailscale Service submodule
  serviceModule = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "this Tailscale service";

      backend = lib.mkOption {
        type = lib.types.str;
        description = "Backend URL (e.g., http://127.0.0.1:8080)";
        example = "http://127.0.0.1:8080";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 443;
        description = "HTTPS port for the service (default: 443)";
      };
    };
  };

  # Generate systemd service for each Tailscale Service
  mkTailscaleService = name: svc: {
    "tailscale-service-${name}" = lib.mkIf svc.enable {
      description = "Tailscale Service: ${name}";
      after = [
        "tailscaled.service"
        "network-online.target"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      # Wait for tailscaled to be fully ready
      preStart = ''
        # Wait for Tailscale to be connected
        for i in $(seq 1 30); do
          status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // "NoState"')
          if [ "$status" = "Running" ]; then
            break
          fi
          echo "Waiting for Tailscale to be ready (attempt $i/30, state: $status)..."
          sleep 2
        done
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.tailscale}/bin/tailscale serve --service=svc:${name} --https=${toString svc.port} ${svc.backend}";
        ExecStop = "${pkgs.tailscale}/bin/tailscale serve --service=svc:${name} --https=${toString svc.port} off";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };

  # Collect all enabled services
  enabledServices = lib.filterAttrs (_: svc: svc.enable) cfg.services;
in
{
  options.networking.tailscale = {
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "tail1234ab.ts.net";
      description = ''
        The Tailscale MagicDNS domain for this tailnet.
        Used for service routing and reverse proxy configuration.
        Find your tailnet domain in the Tailscale admin console under DNS settings.
      '';
    };

    operator = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "wheel";
      description = ''
        Group or user that can operate Tailscale without root privileges.
        Common values: "wheel" (admin group), username (single user), or null (root only).
        If null, only root can manage Tailscale.
      '';
    };

    # NEW: Authentication mode
    authMode = lib.mkOption {
      type = lib.types.enum [
        "interactive"
        "authkey"
      ];
      default = "interactive";
      description = ''
        Authentication mode for Tailscale:
        - "interactive": User logs in via browser (default, user-owned device)
        - "authkey": Use pre-provisioned auth key (tag-based, for servers)

        Use "authkey" for server machines that need to advertise Tailscale Services.
      '';
    };

    # NEW: Auth key file path (for authkey mode)
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/agenix/tailscale-server-key";
      description = ''
        Path to file containing Tailscale auth key.
        Required when authMode = "authkey".
        Typically points to an agenix-managed secret.
      '';
    };

    # NEW: Tailscale Services
    services = lib.mkOption {
      type = lib.types.attrsOf serviceModule;
      default = { };
      example = {
        "axios-mail" = {
          enable = true;
          backend = "http://127.0.0.1:8080";
        };
        "axios-chat" = {
          enable = true;
          backend = "http://127.0.0.1:8081";
        };
      };
      description = ''
        Tailscale Services to advertise. Each service gets a unique DNS name:
        <service-name>.<tailnet-domain>.ts.net

        Requires authMode = "authkey" with appropriate tags.
      '';
    };
  };

  config = {
    # Assertions
    assertions = [
      {
        assertion = isAuthKey -> cfg.authKeyFile != null;
        message = ''
          networking.tailscale.authMode = "authkey" requires authKeyFile to be set.

          Example using agenix:
            networking.tailscale.authKeyFile = config.age.secrets.tailscale-server-key.path;
        '';
      }
      {
        assertion = (enabledServices != { }) -> isAuthKey;
        message = ''
          networking.tailscale.services requires authMode = "authkey".

          Tailscale Services require tag-based device identity.
          Set authMode = "authkey" and provide an auth key with appropriate tags.
        '';
      }
    ];

    # Configure firewall settings for Tailscale
    networking = {
      firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ]; # Allow Tailscale interface through the firewall
        allowedUDPPorts = [ config.services.tailscale.port ]; # Allow UDP ports used by Tailscale
      };
    };

    # Enable and configure Tailscale service
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        extraSetFlags = lib.optional (cfg.operator != null) "--operator=${cfg.operator}";
        useRoutingFeatures = "both";

        # Auth key authentication (for server/tag-based identity)
        authKeyFile = lib.mkIf isAuthKey cfg.authKeyFile;
      };
    };

    # Generate systemd services for Tailscale Services
    systemd.services = lib.mkMerge (lib.mapAttrsToList mkTailscaleService cfg.services);

    environment = {
      systemPackages = with pkgs; [ trayscale ];
    };
  };
}
