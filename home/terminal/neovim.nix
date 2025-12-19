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

  # Deploy base16 template to matugen templates directory
  xdg.configFile."matugen/templates/base16-vim.mustache" = {
    source = ./resources/base16-vim.mustache;
  };

  # Ensure nvim colors directory exists
  # Note: Matugen template registration is handled in home/desktop/theming.nix
  home.activation.createNvimColorsDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/nvim/colors
  '';

  programs.neovim = {
    enable = true;
    # Aliases removed - keeping vim separate from nvim
  };

  programs.lazyvim = {
    enable = true;

    # Configure colorscheme with fallback handling
    pluginsFile."colorscheme.lua".source = ./resources/colorscheme.lua;

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
