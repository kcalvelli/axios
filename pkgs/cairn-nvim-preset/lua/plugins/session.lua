-- Session management

return {
  {
    "rmagatti/auto-session",
    lazy = false,
    keys = {
      { "<leader>ss", "<cmd>SessionSave<cr>", desc = "Save session" },
      { "<leader>sr", "<cmd>SessionRestore<cr>", desc = "Restore session" },
      { "<leader>sd", "<cmd>SessionDelete<cr>", desc = "Delete session" },
      { "<leader>sf", "<cmd>SessionSearch<cr>", desc = "Search sessions" },
    },
    opts = {
      log_level = "error",
      auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      auto_session_use_git_branch = true,
      auto_save_enabled = true,
      auto_restore_enabled = true,
      session_lens = {
        load_on_setup = true,
        theme_conf = {
          border = true,
        },
        previewer = false,
      },
    },
    config = function(_, opts)
      require("auto-session").setup(opts)

      -- Telescope integration
      vim.keymap.set("n", "<leader>sf", function()
        require("auto-session.session-lens").search_session()
      end, { desc = "Search sessions" })
    end,
  },
}
