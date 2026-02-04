-- Treesitter - Syntax highlighting and more

-- Get list of parsers to install
local function get_parsers()
  local parsers = {
    "bash", "diff", "html", "javascript", "jsdoc", "json", "jsonc",
    "lua", "luadoc", "luap", "markdown", "markdown_inline", "nix",
    "printf", "query", "regex", "toml", "tsx", "typescript",
    "vim", "vimdoc", "xml", "yaml",
  }

  -- Add language-specific parsers based on environment
  local ok, axios = pcall(require, "axios")
  if ok then
    local langs = axios.get_languages()
    local lang_parsers = {
      rust = { "rust" },
      zig = { "zig" },
      go = { "go", "gomod", "gosum", "gowork" },
      python = { "python" },
      c = { "c" },
      cpp = { "cpp" },
      cs = { "c_sharp" },
      qml = { "qmljs" },
    }

    for lang, _ in pairs(langs) do
      local extra = lang_parsers[lang]
      if extra then
        for _, parser in ipairs(extra) do
          if not vim.tbl_contains(parsers, parser) then
            table.insert(parsers, parser)
          end
        end
      end
    end
  end

  return parsers
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    config = function()
      -- Install parsers
      local parsers = get_parsers()
      vim.schedule(function()
        local install_ok, install = pcall(require, "nvim-treesitter.install")
        if install_ok then
          install.prefer_git = false
          install.ensure_installed(parsers)
        end
      end)

      -- Enable highlighting for all filetypes with parsers
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft and ft ~= "" then
            pcall(vim.treesitter.start, args.buf)
          end
        end,
      })
    end,
  },

  -- Show context of current function
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 20,
    },
  },
}
