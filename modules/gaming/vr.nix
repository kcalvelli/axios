{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gaming.vr;
  isNvidia = config.axios.hardware.gpuType or null == "nvidia";
in
{
  options.gaming.vr = {
    enable = lib.mkEnableOption "VR gaming support with Steam VR and OpenXR";

    wireless = {
      enable = lib.mkEnableOption "Wireless VR streaming support (WiVRn and/or ALVR)";

      backend = lib.mkOption {
        type = lib.types.enum [
          "wivrn"
          "alvr"
          "both"
        ];
        default = "wivrn";
        description = ''
          Wireless VR backend to use.
          - wivrn: Modern wireless VR solution with hardware encoding support
          - alvr: Alternative wireless VR streaming for Meta Quest
          - both: Install both backends
        '';
      };

      wivrn = {
        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open firewall ports for WiVRn";
        };

        defaultRuntime = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Set WiVRn as the default OpenXR runtime";
        };

        autoStart = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Automatically start WiVRn service on boot";
        };
      };
    };

    overlays = lib.mkEnableOption "VR overlay applications (wlx-overlay-s, wayvr-dashboard)";
  };

  config = lib.mkMerge [
    # Base VR support
    (lib.mkIf cfg.enable {
      # Steam hardware support for VR controllers and headsets
      hardware.steam-hardware.enable = true;

      # Core VR packages
      environment.systemPackages = with pkgs; [
        opencomposite # OpenXR compatibility layer for games
      ];
    })

    # Wireless VR support
    (lib.mkIf (cfg.enable && cfg.wireless.enable) {
      # WiVRn configuration
      services.wivrn = lib.mkIf (cfg.wireless.backend == "wivrn" || cfg.wireless.backend == "both") {
        enable = true;
        openFirewall = cfg.wireless.wivrn.openFirewall;
        defaultRuntime = cfg.wireless.wivrn.defaultRuntime;
        autoStart = cfg.wireless.wivrn.autoStart;

        # Enable CUDA support for Nvidia GPUs (hardware encoding)
        package = if isNvidia then (pkgs.wivrn.override { cudaSupport = true; }) else pkgs.wivrn;
      };

      # Wireless VR streaming packages
      environment.systemPackages =
        with pkgs;
        lib.optional (cfg.wireless.backend == "alvr" || cfg.wireless.backend == "both") alvr;
    })

    # VR overlay applications
    (lib.mkIf (cfg.enable && cfg.overlays) {
      environment.systemPackages = with pkgs; [
        wlx-overlay-s # VR overlay for Wayland
        wayvr-dashboard # Wayland VR dashboard
      ];
    })
  ];
}
