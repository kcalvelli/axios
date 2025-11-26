{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.development = {
    enable = lib.mkEnableOption "Development tools and environments";
  };

  config = lib.mkIf config.development.enable {
    # === Development Packages ===
    environment.systemPackages = with pkgs; [
      # === Editors & IDEs ===
      vim
      vscode
      code-nautilus # VSCode integration with Nautilus
      bun # Required for VSCode material theme updates

      # === Nix Tools ===
      devenv
      nil # Nix LSP

      # === Shell Utilities ===
      starship
      fish
      bat # Better cat
      eza # Better ls
      jq # JSON processor
      fzf # Fuzzy finder

      # === Version Control ===
      gh # GitHub CLI
    ];

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
  };
}
