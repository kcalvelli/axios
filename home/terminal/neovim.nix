{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Bootstrap lazy.nvim for neovim without managing the config file
  # This creates init.lua only if it doesn't exist, allowing user customization
  home.activation.neovimLazyBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        NVIM_CONFIG_DIR="${config.home.homeDirectory}/.config/nvim"
        INIT_LUA="$NVIM_CONFIG_DIR/init.lua"

        if [ ! -f "$INIT_LUA" ]; then
          run mkdir -p "$NVIM_CONFIG_DIR"
          run cat > "$INIT_LUA" << 'EOF'
    -- Bootstrap lazy.nvim
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
      })
    end
    vim.opt.rtp:prepend(lazypath)

    -- Leader key (set before lazy)
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- Setup plugins
    require("lazy").setup({
      -- Colorscheme
      {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
          vim.cmd.colorscheme("catppuccin-mocha")
        end,
      },

      -- Add your plugins here
    })

    -- Basic settings
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.expandtab = true
    vim.opt.shiftwidth = 2
    vim.opt.tabstop = 2
    vim.opt.termguicolors = true
    vim.opt.signcolumn = "yes"
    vim.opt.clipboard = "unnamedplus"
    EOF
          verbose "Created neovim config with lazy.nvim bootstrap"
        fi
  '';
}
