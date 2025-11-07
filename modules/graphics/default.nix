{ pkgs, ... }:
{
  # === GPU / Graphics Hardware ===
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa # OpenGL + RADV Vulkan for AMD
        libva # VA-API
        vulkan-loader # Core Vulkan ICD loader (harmless to keep)
      ];
    };

    amdgpu = {
      initrd.enable = true;
      # overdrive.enable = true;   # enable only if you actually use it
    };
  };

  # === Kernel Parameters ===
  boot.kernelParams = [
    "amdgpu.gpu_recovery=1" # good stability safety net
  ];

  # === Graphics Utilities ===
  environment.systemPackages = with pkgs; [
    # AMD GPU tools
    radeontop
    corectrl
    amdgpu_top
    clinfo
    # Wayland utilities
    wayland-utils
  ];

  # === Environment Variables ===
  environment.variables = {
    HIP_PLATFORM = "amd";
    GSK_RENDERER = "ngl"; # force GTK4 to OpenGL path (stable on wlroots/Hyprland)
  };

  # === Programs ===
  # Gives CoreCtrl polkit integration (fan/clock controls without sudo)
  programs.corectrl.enable = true;
}
