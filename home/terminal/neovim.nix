{ inputs, ... }:
{
  imports = [
    inputs.lazyvim.homeManagerModules.default
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.lazyvim = {
    enable = true;
    extras = {
      coding = {
        blink.enable = true;
        mini-surround.enable = true;
        yanky.enable = true;
      };
      formatting = {
        prettier.enable = true;
      };
      dap = {
        core.enable = true;
      };
      util = {
        dot = {
          enable = true;
        };
      };
      lang = {
        nix.enable = true;
        markdown.enable = true;
        zig.enable = true;
      };
    };
  };
}
