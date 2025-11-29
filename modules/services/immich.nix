# Immich Service Module
# Self-hosted photo and video backup solution with Tailscale HTTPS
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.selfHosted.immich;
  selfHostedCfg = config.selfHosted;
  tailscaleDomain = config.networking.tailscale.domain;
in
{
  options.selfHosted.immich = {
    enable = lib.mkEnableOption "Immich photo and video backup service";

    subdomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "immich";
      description = ''
        Subdomain for Immich service.
        If null, uses the system hostname.
        Full domain will be: {subdomain}.{tailscale.domain}
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 2283;
      description = "Internal port for Immich service.";
    };

    mediaLocation = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/immich";
      description = "Directory used to store uploaded media files.";
    };

    enableGpuAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable GPU acceleration for video transcoding.
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
        Type of GPU for acceleration. Used to configure appropriate user groups.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = selfHostedCfg.enable;
        message = ''
          selfHosted.immich requires selfHosted.enable = true.

          Add to your configuration:
            selfHosted.enable = true;
        '';
      }
      {
        assertion = cfg.enableGpuAcceleration -> (cfg.gpuType != null);
        message = ''
          selfHosted.immich.gpuType must be set when enableGpuAcceleration is true.

          Add to your configuration:
            selfHosted.immich.gpuType = "amd";  # or "nvidia" or "intel"
        '';
      }
    ];

    # Enable Immich service
    services.immich = {
      enable = true;
      host = "127.0.0.1"; # Only listen locally, Caddy handles external access
      port = cfg.port;
      mediaLocation = cfg.mediaLocation;

      # GPU acceleration
      accelerationDevices = lib.mkIf cfg.enableGpuAcceleration null; # null = all devices

      settings = {
        newVersionCheck.enabled = false;
        server.externalDomain =
          let
            domain =
              if cfg.subdomain != null then
                "${cfg.subdomain}.${tailscaleDomain}"
              else
                "${config.networking.hostName}.${tailscaleDomain}";
          in
          "https://${domain}";
      };
    };

    # Register Immich route in Caddy route registry
    selfHosted.caddy.routes.immich =
      let
        domain =
          if cfg.subdomain != null then
            "${cfg.subdomain}.${tailscaleDomain}"
          else
            "${config.networking.hostName}.${tailscaleDomain}";
      in
      {
        inherit domain;
        path = null; # Catch-all (will be ordered after path-specific routes)
        target = "http://127.0.0.1:${toString cfg.port}";
        priority = 1000; # Catch-all - evaluated last

        # reverse_proxy subdirectives
        extraConfig = ''
          # Prevent WebSocket timeout disconnects
          stream_timeout 0
          stream_close_delay 1h
        '';

        # handle-level directives
        handleConfig = ''
          # Immich requires large uploads for photos/videos
          request_body {
            max_size 50GB
          }
        '';
      };

    # GPU user groups for hardware acceleration
    users.users.immich.extraGroups = lib.optionals cfg.enableGpuAcceleration [
      "video"
      "render"
    ];

    # Redis requires vm.overcommit_memory = 1
    boot.kernel.sysctl."vm.overcommit_memory" = lib.mkForce 1;
  };
}
