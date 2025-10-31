{ config, lib, pkgs, ... }:

let
  cfg = config.services.ai;
  
  # Default models to pull on first run
  defaultModels = [
    "qwen2.5-coder:7b"  # Best for coding tasks
    "llama3.1:8b"       # General purpose
  ];
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
    
    # Systemd service to pull default models on first boot
    systemd.services.ollama-pull-models = {
      description = "Pull default Ollama models";
      after = [ "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "ollama";
        Group = "ollama";
      };
      
      script = ''
        # Wait for Ollama to be ready
        for i in {1..30}; do
          if ${pkgs.curl}/bin/curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            break
          fi
          echo "Waiting for Ollama to start... ($i/30)"
          sleep 2
        done
        
        # Pull each model if not already present
        ${lib.concatMapStringsSep "\n" (model: ''
          if ! ${pkgs.ollama}/bin/ollama list | grep -q "${model}"; then
            echo "Pulling model: ${model}"
            ${pkgs.ollama}/bin/ollama pull ${model}
          else
            echo "Model already present: ${model}"
          fi
        '') defaultModels}
      '';
    };
  };
}
