-- axios neovim preset
-- Full-featured IDE configuration with sensible defaults and easy customization

local M = {}

M.version = "1.0.0"

-- Default configuration
M.defaults = {
  colorscheme = "dankshell",

  -- Plugin toggles
  plugins = {
    disabled = {}, -- List of plugin names to disable
  },

  -- LSP configuration
  lsp = {
    servers = {}, -- Override server settings
  },
}

-- Merge user config with defaults (deep merge)
local function merge_config(defaults, user)
  if not user then
    return defaults
  end

  local result = vim.tbl_deep_extend("force", {}, defaults)
  for k, v in pairs(user) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = merge_config(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

-- Check if a plugin is disabled
function M.is_disabled(plugin_name)
  return vim.tbl_contains(M.config.plugins.disabled, plugin_name)
end

-- Get detected languages from environment
function M.get_languages()
  local langs_str = os.getenv("AXIOS_NVIM_LANGUAGES") or ""
  local langs = {}

  -- Always include nix and lua
  langs["nix"] = true
  langs["lua"] = true

  -- Parse comma-separated languages from env
  for lang in langs_str:gmatch("[^,]+") do
    langs[vim.trim(lang)] = true
  end

  return langs
end

-- Bootstrap lazy.nvim if not already installed
local function bootstrap_lazy()
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
end

-- Main setup function
function M.setup(opts)
  -- Merge user options with defaults
  M.config = merge_config(M.defaults, opts)

  -- Bootstrap lazy.nvim
  bootstrap_lazy()

  -- Load core configuration
  require("axios.config.options")
  require("axios.config.keymaps")
  require("axios.config.autocmds")

  -- Collect plugin specs
  local plugins = require("axios.plugins")

  -- Setup lazy.nvim with collected plugins
  require("lazy").setup(plugins, {
    defaults = {
      lazy = true, -- Lazy-load by default
    },
    install = {
      colorscheme = { M.config.colorscheme, "habamax" },
    },
    checker = {
      enabled = false, -- Don't auto-check for updates
    },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
  })

  -- Apply colorscheme
  vim.cmd.colorscheme(M.config.colorscheme)
end

return M
