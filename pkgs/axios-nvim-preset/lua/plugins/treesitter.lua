-- Treesitter - Syntax highlighting and more

return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment selection" },
      { "<bs>", desc = "Decrement selection", mode = "x" },
    },
    config = function()
      -- Base options
      local opts = {
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = {
          -- Always installed
          "bash",
          "diff",
          "html",
          "javascript",
          "jsdoc",
          "json",
          "jsonc",
          "lua",
          "luadoc",
          "luap",
          "markdown",
          "markdown_inline",
          "nix",
          "printf",
          "query",
          "regex",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "xml",
          "yaml",
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.inner",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.inner",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>cA"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>ca"] = "@parameter.inner",
            },
          },
        },
      }

      -- Add language-specific parsers based on environment
      local ok, axios = pcall(require, "axios")
      if ok then
        local langs = axios.get_languages()

        -- Map languages to treesitter parsers
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
          local parsers = lang_parsers[lang]
          if parsers then
            for _, parser in ipairs(parsers) do
              if not vim.tbl_contains(opts.ensure_installed, parser) then
                table.insert(opts.ensure_installed, parser)
              end
            end
          end
        end
      end

      require("nvim-treesitter.configs").setup(opts)
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
