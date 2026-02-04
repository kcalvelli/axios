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
    # === System Tuning for Development ===
    # Increase file watchers for IDEs, hot-reload, and file monitoring tools
    # Default Linux limit (8192) is too low for modern development workflows
    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = lib.mkDefault 524288; # VS Code, Rider, WebStorm, etc.
      # Note: max_user_instances already set to 524288 by NixOS default (as of recent versions)
    };

    # === Development Packages ===
    environment.systemPackages = with pkgs; [
      # === Editors & IDEs ===
      neovim
      vscode
      bun # Required for VSCode material theme updates

      # === API Development & Testing ===
      mitmproxy # Interactive HTTPS proxy
      k6 # Load testing tool

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
