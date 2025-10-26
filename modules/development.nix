{ pkgs, inputs, ... }:
{
  # === Development Packages ===
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    vscode
    # Nix tools
    devenv
    nil # Nix LSP
    # Shell utilities
    starship
    fish
    bat # Better cat
    eza # Better ls
    jq # JSON processor
    fzf # Fuzzy finder
    # Version control
    gh # GitHub CLI
    # AI tools
    whisper-cpp
  ] ++ (with inputs.nix-ai-tools.packages.${pkgs.system}; [
    copilot-cli
  ]);

  # === Development Services ===
  services = {
    lorri.enable = true;
    vscode-server.enable = true;
  };

  # === Development Programs ===
  programs = {
    direnv.enable = true;

    # Launch Fish when interactive shell is detected
    bash = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
  };
}
