{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.lazyvim.homeManagerModules.default
  ];

  # LEGACY: axios custom neovim template (DISABLED by default)
  # DMS now provides neovim theming via its control panel checkbox
  # DMS generates: ~/.config/nvim/lua/plugins/dankcolors.lua (RRethy/base16-nvim)
  #
  # To revert to axios custom template:
  # 1. Add to your home-manager config: axios.theming.useAxiosTemplates = true;
  # 2. Uncomment the lines below
  # 3. Run home-manager switch
  #
  # xdg.configFile."matugen/templates/base16-vim.mustache" = {
  #   source = ./resources/base16-vim.mustache;
  # };
  #
  # home.activation.createNvimColorsDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
  #   $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/nvim/colors
  # '';

  programs.neovim = {
    enable = true;
    # Aliases removed - keeping vim separate from nvim
  };

  programs.lazyvim = {
    enable = true;

    # DMS provides colorscheme via dankcolors.lua plugin
    # DMS generates: ~/.config/nvim/lua/plugins/dankcolors.lua
    # Plugin requirement is installed below (base16-nvim)
    #
    # LEGACY: To revert to axios custom colorscheme loader, uncomment:
    # pluginsFile."colorscheme.lua".source = ./resources/colorscheme.lua;

    # Install base16-nvim plugin for DMS theming
    pluginsFile."base16.lua".text = ''
      return {
        {
          "RRethy/base16-nvim",
          priority = 1000,
        },
      }
    '';

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
