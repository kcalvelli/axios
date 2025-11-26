{
  pkgs,
  lib,
  config,
  osConfig ? { },
  ...
}:
let
  userCfg = config.axios.user;
  # Get user's full name from system user description, fallback to username
  userName = osConfig.users.users.${config.home.username}.description or config.home.username;
  userEmail = userCfg.email;
in
{
  config = {
    programs = {
      git = {
        enable = true;
        # User name and email are automatically configured from:
        # - Full name: users.users.${username}.description (system account)
        # - Email: axios.user.email (home-manager)
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

          # Automatically configure git user from system account + axios.user.email
          (lib.mkIf (userEmail != "") {
            user = {
              name = userName;
              email = userEmail;
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
