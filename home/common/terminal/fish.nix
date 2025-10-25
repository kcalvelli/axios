{ config, lib, ... }:
let
  # Try to get flakePath from determinate module, fallback to /etc/nixos
  flakePath = if config ? determinate && config.determinate ? flakePath 
              then config.determinate.flakePath 
              else "/etc/nixos";
in
{
  programs.fish = {
    shellAliases = {
      rebuild-switch = "sudo nixos-rebuild switch --flake ${flakePath}#$(hostname)";
      rebuild-boot = "sudo nixos-rebuild boot --flake ${flakePath}#$(hostname)";
      rebuild-test = "sudo nixos-rebuild test --flake ${flakePath}#$(hostname)";
      pull-changes = "git -C ${flakePath} fetch origin && git -C ${flakePath} merge --allow-unrelated-histories -X theirs origin/master && git -C ${flakePath} push";
    };
    enable = true;
    interactiveShellInit = ''
      set fish_greeting

      # Colors for #080C12
      set -g fish_color_normal        e0e4e9
      set -g fish_color_command       86e8ef
      set -g fish_color_keyword       cba6f7
      set -g fish_color_param         b3d4ff
      set -g fish_color_quote         7fe0b4
      set -g fish_color_redirection   f5e38a
      set -g fish_color_end           9ca4ae
      set -g fish_color_error         ff9e9e
      set -g fish_color_comment       2a3a4e
      set -g fish_color_selection     --background=2a3a4e
      set -g fish_color_search_match  --background=2a3a4e
      set -g fish_color_operator      9ca4ae
      set -g fish_color_escape        f5e38a
      set -g fish_color_autosuggestion 2a3a4e
      set -g fish_pager_color_description 9ca4ae
      set -g fish_pager_color_completion  e0e4e9
      set -g fish_pager_color_prefix      b3d4ff --bold
      set -g fish_pager_color_progress    2a3a4e

      # direnv
      command -q direnv; and direnv hook fish | source

      # zoxide / fzf
      if type -q zoxide
        zoxide init fish | source
      end
      if type -q fzf
        function _fzf_file --description 'Fuzzy file insert'
          set -l file (fd . --hidden --follow --exclude .git | fzf)
          and commandline -it -- " $file"
        end
        bind \cf '_fzf_file'
      end

      # Git QoL
      abbr -a gs  'git status -sb'
      abbr -a ga  'git add -A'
      abbr -a gc  'git commit -m'
      abbr -a gco 'git checkout'
      abbr -a gb  'git switch -c'
      abbr -a gl  'git log --oneline --graph --decorate -20'
      abbr -a mkcd 'mkdir -p && cd'
    '';
    plugins = [
      # { name = "fzf"; src = pkgs.fishPlugins.fzf.src; }
      # { name = "z";   src = pkgs.fishPlugins.z.src; }
      # { name = "github-copilot-cli-fish"; src = pkgs.fishPlugins.github-copilot-cli-fish.src; }
    ];
  };
}
