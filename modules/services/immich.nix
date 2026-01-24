# Immich Service Module
# Self-hosted photo and video backup solution with Tailscale Services HTTPS
# Uses axios.immich namespace to avoid conflict with nixpkgs services.immich
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.axios.immich;
  tailscaleDomain = config.networking.tailscale.domain;
  tsCfg = config.networking.tailscale;
  isServer = cfg.role == "server";
  isClient = cfg.role == "client";

  # Service domain: axios-immich.<tailnet>.ts.net
  serviceDomain = "axios-immich.${tailscaleDomain}";
in
{
  options.axios.immich = {
    enable = lib.mkEnableOption "Immich photo and video backup";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client"
      ];
      default = "server";
      description = ''
        Immich deployment role:
        - "server": Run Immich service locally
                    Auto-registers as axios-immich.<tailnet>.ts.net via Tailscale Services
        - "client": PWA desktop entry only (connects to axios-immich.<tailnet>.ts.net)
      '';
    };

    # Server-only options
    port = lib.mkOption {
      type = lib.types.port;
      default = 2283;
      description = "Internal port for Immich service (server role only).";
    };

    mediaLocation = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/immich";
      description = "Directory used to store uploaded media files (server role only).";
    };

    enableGpuAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable GPU acceleration for video transcoding (server role only).
        Grants Immich access to all GPU devices (/dev/dri/*).
      '';
    };

    gpuType = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "amd"
          "nvidia"
          "intel"
        ]
      );
      default = null;
      description = ''
        Type of GPU for acceleration. Used to configure appropriate user groups (server role only).
      '';
    };

    # PWA configuration (both roles)
    pwa = {
      enable = lib.mkEnableOption "Generate Immich PWA desktop entry";
      tailnetDomain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "taile0fb4.ts.net";
        description = "Tailscale tailnet domain for PWA URL";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Assertions for both roles
      {
        assertions = [
          # PWA requires tailnetDomain
          {
            assertion = !cfg.pwa.enable || cfg.pwa.tailnetDomain != null;
            message = ''
              axios.immich.pwa.enable requires pwa.tailnetDomain to be set.

              Example:
                axios.immich.pwa.tailnetDomain = "taile0fb4.ts.net";
            '';
          }
        ];
      }

      # Server role: Run Immich service
      (lib.mkIf isServer {
        assertions = [
          {
            assertion = cfg.enableGpuAcceleration -> (cfg.gpuType != null);
            message = ''
              axios.immich.gpuType must be set when enableGpuAcceleration is true.

              Add to your configuration:
                axios.immich.gpuType = "amd";  # or "nvidia" or "intel"
            '';
          }
          {
            assertion = tailscaleDomain != null;
            message = ''
              axios.immich requires networking.tailscale.domain to be set.

              Find your tailnet domain in the Tailscale admin console.
              Example: networking.tailscale.domain = "taile0fb4.ts.net";
            '';
          }
          {
            assertion = tsCfg.authMode == "authkey";
            message = ''
              axios.immich (server role) requires networking.tailscale.authMode = "authkey".

              Immich uses Tailscale Services for HTTPS, which requires tag-based identity.
              Set up an auth key in the Tailscale admin console with appropriate tags.
            '';
          }
        ];

        # Enable nixpkgs Immich service
        services.immich = {
          enable = true;
          host = "127.0.0.1"; # Only listen locally, Tailscale Services handles external access
          port = cfg.port;
          mediaLocation = cfg.mediaLocation;

          # GPU acceleration
          accelerationDevices = lib.mkIf cfg.enableGpuAcceleration null; # null = all devices

          settings = {
            newVersionCheck.enabled = false;
            server.externalDomain = "https://${serviceDomain}";
          };
        };

        # Tailscale Services registration
        # Provides unique DNS name: axios-immich.<tailnet>.ts.net
        networking.tailscale.services."axios-immich" = {
          enable = true;
          backend = "http://127.0.0.1:${toString cfg.port}";
        };

        # Local hostname for server PWA (hairpinning workaround)
        # Server can't access its own Tailscale Services VIPs, so we use a local domain
        # This gives unique app_id for PWA icons on the server
        networking.hosts = {
          "127.0.0.1" = [ "axios-immich.local" ];
        };

        # GPU user groups for hardware acceleration
        users.users.immich.extraGroups = lib.optionals cfg.enableGpuAcceleration [
          "video"
          "render"
        ];

        # Redis requires vm.overcommit_memory = 1
        boot.kernel.sysctl."vm.overcommit_memory" = lib.mkForce 1;
      })

      # Client role: No service configuration needed
      # PWA generation happens in home-manager module
    ]
  );
}
