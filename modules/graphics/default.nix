{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Get GPU type and form factor from host configuration (passed through from lib/default.nix)
  gpuType = config.axios.hardware.gpuType or null;
  isLaptop = config.axios.hardware.isLaptop or false;

  isAmd = gpuType == "amd";
  isNvidia = gpuType == "nvidia";
  isIntel = gpuType == "intel";
  isDesktop = !isLaptop;
in
{
  # Options for GPU type and form factor (set by lib/default.nix hostModule)
  options.axios.hardware = {
    gpuType = lib.mkOption {
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

    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this is a laptop (affects PRIME configuration for Nvidia)";
    };
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
        # Use open-source kernel module (recommended for RTX 20-series/Turing and newer)
        # For pre-Turing GPUs (GTX 10-series and older), override with: hardware.nvidia.open = false;
        open = lib.mkDefault true;

        # Enable nvidia-settings menu
        nvidiaSettings = true;

        # Power management (disabled by default to avoid suspend/resume issues)
        # Enable only if experiencing corruption after sleep
        powerManagement.enable = false;
        # Fine-grained power management (experimental, Turing+ only)
        powerManagement.finegrained = false;

        # PRIME configuration (Optimus for laptops with hybrid graphics)
        # Disable PRIME on desktops with single discrete GPU
        # nixos-hardware.common-gpu-nvidia may enable PRIME by default, which breaks desktops
        prime = lib.mkIf isDesktop {
          offload.enable = lib.mkForce false;
          sync.enable = lib.mkForce false;
          reverseSync.enable = lib.mkForce false;
        };
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
