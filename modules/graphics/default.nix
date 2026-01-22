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

    nvidiaDriver = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "beta"
        "production"
      ];
      default = "stable";
      description = ''
        Nvidia driver version to use.
        - stable: Conservative choice, tested and reliable
        - beta: Required for RTX 50-series (Blackwell) and newest features
        - production: Latest stable release (newer than stable branch)
      '';
    };

    enableGPURecovery = lib.mkOption {
      type = lib.types.bool;
      default = isAmd;
      description = ''
        Enable automatic GPU hang recovery (AMD GPUs only).
        Adds kernel parameters amdgpu.gpu_recovery=1 and amdgpu.lockup_timeout=5000.
        This allows the kernel to reset the GPU on hang instead of freezing the system.
        Enabled by default for AMD GPUs. Disable only if experiencing issues with GPU resets.
        This option only works when gpuType is "amd".
      '';
    };
  };

  config = {
    # Assertion: enableGPURecovery requires AMD GPU
    assertions = [
      {
        assertion = !config.axios.hardware.enableGPURecovery || isAmd;
        message = "axios.hardware.enableGPURecovery can only be enabled with AMD GPUs (gpuType must be 'amd')";
      }
    ];

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
            nvidia-vaapi-driver # VA-API support for NVIDIA (for browser video acceleration)
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
        # Driver package selection based on axios.hardware.nvidiaDriver option
        package =
          let
            nvidiaPackages = config.boot.kernelPackages.nvidiaPackages;
          in
          {
            stable = nvidiaPackages.stable;
            beta = nvidiaPackages.beta;
            production = nvidiaPackages.production;
          }
          .${config.axios.hardware.nvidiaDriver};

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
        # Default to disabled on desktops with single discrete GPU
        # For dual-GPU desktops (e.g., nvidia dGPU + AMD/Intel iGPU), configure manually:
        #   hardware.nvidia.prime.sync.enable = true;
        #   hardware.nvidia.prime.nvidiaBusId = "PCI:X:Y:Z";
        #   hardware.nvidia.prime.amdgpuBusId = "PCI:A:B:C";  # or intelBusId
        prime = lib.mkIf isDesktop {
          offload.enable = lib.mkDefault false;
          sync.enable = lib.mkDefault false;
          reverseSync.enable = lib.mkDefault false;
        };
      };
    };

    # === Video Drivers ===
    # Set the appropriate video driver for X11/Wayland
    services.xserver.videoDrivers = lib.mkIf isNvidia [ "nvidia" ];

    # === Kernel Parameters ===
    boot.kernelParams =
      lib.optionals (isAmd && config.axios.hardware.enableGPURecovery) [
        "amdgpu.gpu_recovery=1" # Enable GPU reset on hang
        "amdgpu.lockup_timeout=5000" # Detect GPU hangs within 5 seconds
      ]
      ++ lib.optionals isNvidia [
        "nvidia_drm.modeset=1" # Enable modesetting (required for Wayland)
      ];

    # === Graphics Utilities ===
    environment.systemPackages =
      with pkgs;
      [
        # Common tools for all GPU types
        clinfo
        wayland-utils
        vulkan-tools # vulkaninfo, vkcube - useful for verifying GPU setup
        renderdoc # Graphics debugging and frame capture
      ]
      ++ lib.optionals isAmd [
        # AMD GPU tools
        radeontop
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
      (lib.mkIf isNvidia {
        # Backend for nvidia-vaapi-driver (direct = faster, egl = more compatible)
        NVD_BACKEND = "direct";
        # Workaround for Chromium/Electron apps to use correct VA-API driver
        LIBVA_DRIVER_NAME = "nvidia";
      })
    ];
  };
}
