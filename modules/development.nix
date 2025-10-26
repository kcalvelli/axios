{ pkgs, inputs, ... }:
let
  # Import categorized package lists
  packages = import ./packages.nix { inherit pkgs inputs; };
in
{
  # === Development Packages ===
  # Organized by category in packages.nix for easier management
  environment.systemPackages =
    packages.editors
    ++ packages.nix
    ++ packages.shell
    ++ packages.vcs
    ++ packages.ai;

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
