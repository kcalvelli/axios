-- AI integration with avante.nvim
-- Only loaded when AXIOS_AI_ENABLED=1

return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false, -- Load on startup when AI is enabled
    version = false,
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      -- Optional: for image pasting
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
          },
        },
      },
      -- Optional: for markdown rendering
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
    keys = {
      { "<leader>aa", "<cmd>AvanteToggle<cr>", desc = "Toggle Avante" },
      { "<leader>ar", "<cmd>AvanteRefresh<cr>", desc = "Refresh Avante" },
      { "<leader>af", "<cmd>AvanteFocus<cr>", desc = "Focus Avante" },
      {
        "<leader>ae",
        function()
          require("avante.api").edit()
        end,
        desc = "Edit with AI",
        mode = { "n", "v" },
      },
      {
        "<leader>as",
        function()
          require("avante.api").ask()
        end,
        desc = "Ask AI",
        mode = { "n", "v" },
      },
    },
    opts = function()
      local axios = require("axios")
      local ai_config = axios.config.ai or {}
      local claude_config = ai_config.claude or {}
      local auth_type = claude_config.auth_type or "api"

      -- Base configuration
      local opts = {
        provider = "claude",
        auto_suggestions_provider = "claude",
        claude = {
          model = "claude-sonnet-4-20250514",
          max_tokens = 8192,
        },
        behaviour = {
          auto_suggestions = false, -- Disable auto-suggestions by default
          auto_set_highlight_group = true,
          auto_set_keymaps = true,
          auto_apply_diff_after_generation = false,
          support_paste_from_clipboard = true,
        },
        mappings = {
          diff = {
            ours = "co",
            theirs = "ct",
            all_theirs = "ca",
            both = "cb",
            cursor = "cc",
            next = "]x",
            prev = "[x",
          },
          suggestion = {
            accept = "<M-l>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
          jump = {
            next = "]]",
            prev = "[[",
          },
          submit = {
            normal = "<CR>",
            insert = "<C-s>",
          },
        },
        hints = { enabled = true },
        windows = {
          position = "right",
          wrap = true,
          width = 30,
          sidebar_header = {
            align = "center",
            rounded = true,
          },
        },
        highlights = {
          diff = {
            current = "DiffText",
            incoming = "DiffAdd",
          },
        },
        diff = {
          autojump = true,
          list_opener = "copen",
        },
      }

      -- Configure based on auth_type
      if auth_type == "api" then
        -- Use ANTHROPIC_API_KEY environment variable
        opts.claude.api_key_name = "ANTHROPIC_API_KEY"
      elseif auth_type == "pro" or auth_type == "max" then
        -- Use Claude web interface authentication
        -- This requires the user to have authenticated via browser
        opts.claude.api_key_name = "cmd:claude auth token"
      end

      return opts
    end,
  },
}
