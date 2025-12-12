{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Get GPU type from host configuration (passed through from lib/default.nix)
  # This will be set by the host module in lib/default.nix based on hostCfg.hardware.gpu
  gpuType = config.axios.hardware.gpuType or null;

  isAmd = gpuType == "amd";
  isNvidia = gpuType == "nvidia";
  isIntel = gpuType == "intel";
in
{
  # Option for GPU type (set by lib/default.nix hostModule)
  options.axios.hardware.gpuType = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.enum [
        "amd"
        "nvidia"
        "intel"
      ]
    );
    default = null;
    description = "GPU type for hardware-specific configuration";
  };

  config = {
    # === GPU / Graphics Hardware ===
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages =
          with pkgs;
          [
            # Common packages for all GPU types
            libva # VA-API
            vulkan-loader # Core Vulkan ICD loader
          ]
          ++ lib.optionals isAmd [
            mesa # OpenGL + RADV Vulkan for AMD
          ]
          ++ lib.optionals isNvidia [
            # Nvidia proprietary driver packages
            # Note: The driver itself is loaded via hardware.nvidia.package
            # These are additional libraries for Vulkan, CUDA, etc.
          ]
          ++ lib.optionals isIntel [
            mesa # OpenGL + Intel Vulkan
            intel-media-driver # VA-API for Intel
          ];
      };

      # AMD-specific hardware config
      amdgpu = lib.mkIf isAmd {
        initrd.enable = true;
        # overdrive.enable = true;   # enable only if you actually use it
      };

      # Nvidia-specific hardware config
      nvidia = lib.mkIf isNvidia {
        modesetting.enable = true;
        # Force proprietary driver (not nouveau)
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        open = false; # Use proprietary kernel module (required for pre-Turing GPUs)

        # Enable nvidia-settings menu
        nvidiaSettings = true;

        # Power management (disabled by default to avoid suspend/resume issues)
        # Enable only if experiencing corruption after sleep
        powerManagement.enable = false;
        # Fine-grained power management (experimental, Turing+ only)
        powerManagement.finegrained = false;
      };
    };

    # === Video Drivers ===
    # Set the appropriate video driver for X11/Wayland
    services.xserver.videoDrivers = lib.mkIf isNvidia [ "nvidia" ];

    # === Kernel Parameters ===
    boot.kernelParams = lib.optionals isAmd [
      "amdgpu.gpu_recovery=1" # good stability safety net
    ];

    # === Graphics Utilities ===
    environment.systemPackages =
      with pkgs;
      [
        # Common tools for all GPU types
        clinfo
        wayland-utils
        vulkan-tools # vulkaninfo, vkcube - useful for verifying GPU setup
      ]
      ++ lib.optionals isAmd [
        # AMD GPU tools
        radeontop
        corectrl
        amdgpu_top
      ]
      ++ lib.optionals isNvidia [
        # Nvidia GPU tools
        nvtopPackages.nvidia
        config.boot.kernelPackages.nvidiaPackages.stable # nvidia-settings and nvidia-smi
      ]
      ++ lib.optionals isIntel [
        # Intel GPU tools
        intel-gpu-tools
      ];

    # === Environment Variables ===
    environment.variables = lib.mkMerge [
      {
        GSK_RENDERER = "ngl"; # force GTK4 to OpenGL path (stable on wlroots)
      }
      (lib.mkIf isAmd { HIP_PLATFORM = "amd"; })
    ];

    # === Programs ===
    # AMD: CoreCtrl for fan/clock controls
    programs.corectrl.enable = lib.mkIf isAmd true;
  };
}
