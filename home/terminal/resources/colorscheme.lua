-- Load dankshell colorscheme with fallback to catppuccin
return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Override default colorscheme
      colorscheme = function()
        -- Try to load dankshell colorscheme
        local ok, _ = pcall(vim.cmd, "colorscheme dankshell")
        if not ok then
          vim.notify("dankshell colorscheme not found, using default theme", vim.log.levels.WARN)
          vim.notify("Theme will generate on first wallpaper change", vim.log.levels.INFO)
          -- Fall back to catppuccin (lazyvim default)
          vim.cmd("colorscheme catppuccin")
        end
      end,
    },
  },
}
