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

      loopbackProxy = {
        enable = lib.mkEnableOption "local nginx HTTPS proxy for secure context";
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
      wants = [
        "tailscaled.service"
        "network-online.target"
      ];
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

  # Collect services with loopback proxy enabled
  loopbackServices = lib.filterAttrs (_: svc: svc.enable && svc.loopbackProxy.enable) cfg.services;
  hasLoopbackServices = loopbackServices != { };

  # Certificate paths
  certDir = "/var/lib/tailscale/certs";
  mkFqdn = name: "${name}.${cfg.domain}";
  mkCertPath = name: "${certDir}/${mkFqdn name}.crt";
  mkKeyPath = name: "${certDir}/${mkFqdn name}.key";

  # Shared preStart script for waiting on Tailscale
  tailscaleWaitScript = ''
    for i in $(seq 1 30); do
      status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // "NoState"')
      if [ "$status" = "Running" ]; then
        break
      fi
      echo "Waiting for Tailscale to be ready (attempt $i/30, state: $status)..."
      sleep 2
    done
  '';

  # Generate cert sync systemd service for a loopback-proxied service
  mkCertSyncService = name: _svc: {
    "tailscale-cert-${name}" = {
      description = "Tailscale certificate sync for ${mkFqdn name}";
      before = [ "nginx.service" ];
      after = [
        "tailscaled.service"
        "network-online.target"
      ];
      wants = [
        "tailscaled.service"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];

      preStart = tailscaleWaitScript;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.tailscale}/bin/tailscale cert --cert-file ${mkCertPath name} --key-file ${mkKeyPath name} ${mkFqdn name}";
        ExecStartPost = [
          # tailscale cert creates files as root:root — fix ownership and
          # permissions so the nginx user (in the nginx group) can read them.
          "${pkgs.coreutils}/bin/chown root:nginx ${mkCertPath name} ${mkKeyPath name}"
          "${pkgs.coreutils}/bin/chmod 644 ${mkCertPath name}"
          "${pkgs.coreutils}/bin/chmod 640 ${mkKeyPath name}"
          # Reload nginx if running, restart if failed, skip if not yet started
          # (on initial boot nginx.service has an After= on this unit so it starts later)
          "+${pkgs.bash}/bin/bash -c 'if ${pkgs.systemd}/bin/systemctl is-active --quiet nginx.service; then ${pkgs.systemd}/bin/systemctl reload nginx.service; elif ${pkgs.systemd}/bin/systemctl is-failed --quiet nginx.service; then ${pkgs.systemd}/bin/systemctl restart nginx.service; fi'"
        ];
      };
    };
  };

  # Generate cert sync timer for a loopback-proxied service
  mkCertSyncTimer = name: _svc: {
    "tailscale-cert-${name}" = {
      description = "Daily certificate renewal for ${mkFqdn name}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };

  # Generate nginx virtualHost for a loopback-proxied service
  mkNginxVhost = name: svc: {
    "${mkFqdn name}" = {
      # onlySSL triggers ssl_certificate rendering in the generated nginx.conf.
      # The explicit listen directive below overrides onlySSL's default listeners,
      # ensuring nginx only binds to 127.0.0.1 (not 0.0.0.0).
      onlySSL = true;
      listen = [
        {
          addr = "127.0.0.1";
          port = 443;
          ssl = true;
        }
      ];
      sslCertificate = mkCertPath name;
      sslCertificateKey = mkKeyPath name;
      locations."/" = {
        proxyPass = svc.backend;
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };
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

    # Accept routes from other Tailscale nodes
    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Accept routes advertised by other Tailscale nodes.
        Required for clients to access Tailscale Services VIPs.

        Default is true to enable access to Tailscale Services.
        Set to false only if you have specific routing requirements.
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
        "axios-ai-chat" = {
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
      {
        assertion = !hasLoopbackServices || cfg.domain != null;
        message = ''
          Tailscale loopbackProxy requires networking.tailscale.domain to be set.

          At least one Tailscale service has loopbackProxy.enable = true, but
          networking.tailscale.domain is not configured.

          Example:
            networking.tailscale.domain = "example-tailnet.ts.net";
        '';
      }
    ];

    # Configure firewall settings for Tailscale
    networking = {
      firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ]; # Allow Tailscale interface through the firewall
        allowedUDPPorts = [ config.services.tailscale.port ]; # Allow UDP ports used by Tailscale
      };

      # Map loopback-proxied service FQDNs to 127.0.0.1
      hosts = lib.mkIf hasLoopbackServices {
        "127.0.0.1" = lib.mapAttrsToList (name: _: mkFqdn name) loopbackServices;
      };
    };

    # Enable and configure Tailscale service
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        extraSetFlags =
          lib.optional (cfg.operator != null) "--operator=${cfg.operator}"
          ++ lib.optional cfg.acceptRoutes "--accept-routes";
        useRoutingFeatures = "both";

        # Auth key authentication (for server/tag-based identity)
        authKeyFile = lib.mkIf isAuthKey cfg.authKeyFile;
      };

      # Enable nginx for loopback proxy (only if needed)
      nginx = lib.mkIf hasLoopbackServices {
        enable = true;
        virtualHosts = lib.mkMerge (lib.mapAttrsToList mkNginxVhost loopbackServices);
      };
    };

    # Certificate directory
    systemd.tmpfiles.rules = lib.mkIf hasLoopbackServices [
      "d ${certDir} 0750 root nginx - -"
    ];

    # Generate systemd services: Tailscale Services + cert sync services
    systemd.services = lib.mkMerge (
      (lib.mapAttrsToList mkTailscaleService cfg.services)
      ++ (lib.mapAttrsToList mkCertSyncService loopbackServices)
    );

    # Generate cert sync timers
    systemd.timers = lib.mkIf hasLoopbackServices (
      lib.mkMerge (lib.mapAttrsToList mkCertSyncTimer loopbackServices)
    );
  };
}
