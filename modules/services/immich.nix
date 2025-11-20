# Immich Service Module
# Self-hosted photo and video backup solution with Tailscale HTTPS
{ config, lib, pkgs, ... }:

let
  cfg = config.selfHosted.immich;
  selfHostedCfg = config.selfHosted;
  tailscaleDomain = config.networking.tailscale.domain;

  # Generate external library mount paths
  externalLibraryMounts = lib.mapAttrs'
    (name: path: {
      name = "/mnt/immich-external/${name}";
      value = {
        device = path;
        options = [ "bind" ];
      };
    })
    cfg.externalLibraries;

  # Generate tmpfiles rules for mount points
  externalLibraryTmpfiles = lib.mapAttrsToList
    (name: _path:
      "d /mnt/immich-external/${name} 0755 immich immich -"
    )
    cfg.externalLibraries;

  # Generate ReadWritePaths for systemd hardening
  externalLibraryPaths = lib.mapAttrsToList
    (name: _path:
      "/mnt/immich-external/${name}"
    )
    cfg.externalLibraries;
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

    externalLibraries = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      example = {
        pictures = "/home/user/Pictures";
        videos = "/home/user/Videos";
      };
      description = ''
        External libraries to make available to Immich via bind mounts.
        Each entry creates a bind mount at /mnt/immich-external/{name}.

        In the Immich web UI, add these as external library paths:
        /mnt/immich-external/{name}
      '';
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
      type = lib.types.nullOr (lib.types.enum [ "amd" "nvidia" "intel" ]);
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

      # Disable new version check to work around frontend bug in v2.2.3
      settings = {
        newVersionCheck.enabled = false;
      };
    };

    # Configure Caddy reverse proxy for Immich
    selfHosted.caddy.extraConfig =
      let
        domain =
          if cfg.subdomain != null
          then "${cfg.subdomain}.${tailscaleDomain}"
          else "${config.networking.hostName}.${tailscaleDomain}";
      in
      ''
        ${domain} {
          reverse_proxy http://127.0.0.1:${toString cfg.port} {
            header_up Connection {http.request.header.Connection}
            header_up Upgrade {http.request.header.Upgrade}
          }

          # Immich requires large uploads for photos/videos
          request_body {
            max_size 50GB
          }
        }
      '';

    # GPU user groups for hardware acceleration
    users.users.immich.extraGroups = lib.optionals cfg.enableGpuAcceleration [
      "video"
      "render"
    ];

    # Redis requires vm.overcommit_memory = 1
    boot.kernel.sysctl."vm.overcommit_memory" = lib.mkForce 1;

    # External library configuration
    systemd.tmpfiles.rules = lib.mkIf (cfg.externalLibraries != { }) (
      [ "d /mnt/immich-external 0755 immich immich -" ] ++ externalLibraryTmpfiles
    );

    # Bind mounts for external libraries
    fileSystems = lib.mkIf (cfg.externalLibraries != { }) externalLibraryMounts;

    # Override systemd hardening to allow access to bind-mounted external libraries
    systemd.services.immich-server.serviceConfig = lib.mkIf (cfg.externalLibraries != { }) {
      ReadWritePaths = externalLibraryPaths;
    };
  };
}
