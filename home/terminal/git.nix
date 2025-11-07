{ pkgs, lib, config, ... }:
let
  cfg = config.axios.git;
in
{
  options.axios.git = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Git user name for commits";
        example = "John Doe";
      };

      email = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Git user email for commits";
        example = "john@example.com";
      };
    };
  };

  config = {
    programs = {
      git = {
        enable = true;
        # User name and email can be set via axios.git.user for convenience
        # or directly via programs.git.settings.user for full control
        settings = lib.mkMerge [
          {
            core.pager = "${pkgs.delta}/bin/delta";
            init.defaultBranch = "main";
            pull.ff = "only";
            push.default = "current";
            rebase.autoStash = true;
            rerere.enabled = true;
            branch.sort = "-committerdate";
            status.showUntrackedFiles = "all";
            color.ui = true;
            diff.colorMoved = "default";
            merge.conflictStyle = "zdiff3";
            fetch.prune = true;
            help.autocorrect = 20;
            alias = {
              co = "checkout";
              cob = "!f(){ git checkout -b \"$1\"; }; f";
              sw = "switch";
              ci = "commit";
              cia = "commit -a";
              amend = "commit --amend --no-edit";
              st = "status -sb";
              last = "log -1 --stat";
              lg = "log --graph --decorate --oneline --abbrev-commit";
              lga = "log --graph --decorate --oneline --all --abbrev-commit";
              unstage = "reset HEAD --";
              fixup = "commit --fixup";
              wip = "commit -am 'wip'";
            };
          }

          # Merge in user config from axios.git.user
          (lib.mkIf (cfg.user.name != "" && cfg.user.email != "") {
            user = {
              name = cfg.user.name;
              email = cfg.user.email;
            };
          })
        ];
      };

      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          line-numbers = true;
          side-by-side = true;
          syntax-theme = "Monokai Extended";
          zero-style = "syntax";
          plus-style = "syntax #0c1a12";
          minus-style = "syntax #1a0c0f";
          plus-emph-style = "bold #7fe0b4";
          minus-emph-style = "bold #ff9e9e";
          commit-decoration-style = "bold yellow";
          file-decoration-style = "underline #b3d4ff";
          hunk-header-decoration-style = "blue box";
        };
      };
    };
  };
}
