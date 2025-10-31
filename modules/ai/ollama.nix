{ config, lib, pkgs, ... }:

let
  cfg = config.services.ai;
in
{
  config = lib.mkIf cfg.enable {
    # AMD GPU ROCm and OpenCL support for AI workloads
    hardware.amdgpu.opencl.enable = true;
    hardware.graphics.extraPackages = with pkgs; [ rocmPackages.clr.icd ];

    # Symlink for ROCm HIP
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    # Ollama service with ROCm acceleration
    services.ollama = {
      enable = true;
      acceleration = "rocm";
      rocmOverrideGfx = "10.3.0";
      port = 11434;
      host = "0.0.0.0";
      openFirewall = true;
    };

    # Open WebUI for Ollama
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = 8080;
      openFirewall = true;
      environment = {
        STATIC_DIR = "${config.services.open-webui.stateDir}/static";
        DATA_DIR = "${config.services.open-webui.stateDir}/data";
        HF_HOME = "${config.services.open-webui.stateDir}/hf_home";
        SENTENCE_TRANSFORMERS_HOME = "${config.services.open-webui.stateDir}/transformers_home";
        # WEBUI_URL is set in default.nix to avoid duplicate variable definitions
      };
    };
  };
}
