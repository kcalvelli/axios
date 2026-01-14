{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Get GPU type from hardware configuration
  gpuType = config.axios.hardware.gpuType or null;
  isAmd = gpuType == "amd";
  isNvidia = gpuType == "nvidia";

  braveExtensionIds = [
    "ghbmnnjooekpmoecnnnilnnbdlolhkhi" # Google Docs Offline
    "nimfmkdcckklbkhjjkmbjfcpaiifgamg" # Brave Talk
    "aomjjfmjlecjafonmbhlgochhaoplhmo" # 1Password
    "fcoeoabgfenejglbffodgkkbkcdhcgfn" # Claude
    "bkhaagjahfmjljalopjnoealnfndnagc" # Octotree - GitHub code tree
    "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader - dark mode
  ];

  chromeExtensionIds = [
    "ghbmnnjooekpmoecnnnilnnbdlolhkhi" # Google Docs Offline
  ];

  # Base arguments for all configurations
  baseArgs = [
    "--password-store=detect"
  ];

  # Common hardware acceleration flags for both AMD and NVIDIA
  commonAccelFlags = [
    "--ignore-gpu-blocklist"
    "--enable-gpu-rasterization"
    "--enable-zero-copy"
    "--enable-native-gpu-memory-buffers"
  ];

  # AMD-specific hardware acceleration flags
  # Note: Chrome 131+ renamed Vaapi* to Accelerated* but kept VaapiIgnoreDriverChecks
  amdAccelFlags = [
    "--enable-features=AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxGL,VaapiIgnoreDriverChecks,CanvasOopRasterization"
    # "--enable-unsafe-webgpu" # Commented out - produces warnings in Brave
  ];

  # NVIDIA-specific hardware acceleration flags
  # VaapiOnNvidiaGPUs enables VA-API on NVIDIA via nvidia-vaapi-driver
  nvidiaAccelFlags = [
    "--enable-features=AcceleratedVideoEncoder,AcceleratedVideoDecodeLinuxGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,CanvasOopRasterization"
  ];

  # Build final argument list based on GPU type
  braveArgs =
    baseArgs
    ++ lib.optionals isAmd (commonAccelFlags ++ amdAccelFlags)
    ++ lib.optionals isNvidia (commonAccelFlags ++ nvidiaAccelFlags);

  chromeArgs =
    baseArgs
    ++ lib.optionals isAmd (commonAccelFlags ++ amdAccelFlags)
    ++ lib.optionals isNvidia (commonAccelFlags ++ nvidiaAccelFlags);
in
{
  # Import NixOS module from flake
  imports = [ inputs.brave-browser-previews.nixosModules.default ];

  config = lib.mkIf config.desktop.enable {

    # === Brave Nightly Configuration (System) ===
    programs.brave-nightly = {
      enable = true;
      extensions = braveExtensionIds;
      commandLineArgs = braveArgs;
    };

    # === Brave Stable Configuration (Home Manager) ===
    home-manager.sharedModules = [
      (
        { pkgs, ... }:
        {
          programs.brave = {
            enable = true;
            extensions = map (id: { inherit id; }) braveExtensionIds;
            commandLineArgs = braveArgs;
          };

          programs.google-chrome = {
            enable = true;
            extensions = map (id: { inherit id; }) chromeExtensionIds;
            commandLineArgs = chromeArgs;
          };
        }
      )
    ];
  };
}
