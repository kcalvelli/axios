-- LSP Configuration

-- Check if a binary exists in PATH
local function executable(name)
  return vim.fn.executable(name) == 1
end

-- Language server configurations
local servers = {
  -- Always enabled
  nix = {
    name = "nil_ls",
    binary = "nil",
    config = {
      settings = {
        ["nil"] = {
          formatting = {
            command = { "nixfmt" },
          },
        },
      },
    },
  },

  lua = {
    name = "lua_ls",
    binary = "lua-language-server",
    config = {
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          completion = { callSnippet = "Replace" },
          telemetry = { enable = false },
          diagnostics = { globals = { "vim" } },
        },
      },
    },
  },

  -- Devshell languages
  rust = {
    name = "rust_analyzer",
    binary = "rust-analyzer",
    config = {
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true, loadOutDirsFromCheck = true, runBuildScripts = true },
          checkOnSave = { allFeatures = true, command = "clippy", extraArgs = { "--no-deps" } },
          procMacro = { enable = true },
        },
      },
    },
  },

  zig = {
    name = "zls",
    binary = "zls",
    config = {},
  },

  go = {
    name = "gopls",
    binary = "gopls",
    config = {
      settings = {
        gopls = {
          gofumpt = true,
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          semanticTokens = true,
        },
      },
    },
  },

  python = {
    name = "pyright",
    binary = "pyright-langserver",
    config = {
      settings = {
        python = {
          analysis = { autoSearchPaths = true, diagnosticMode = "openFilesOnly", useLibraryCodeForTypes = true },
        },
      },
    },
  },

  typescript = {
    name = "ts_ls",
    binary = "typescript-language-server",
    config = {},
  },

  cpp = {
    name = "clangd",
    binary = "clangd",
    config = {
      cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
    },
  },

  cs = {
    name = "omnisharp",
    binary = "OmniSharp",
    config = {},
  },
}

-- Setup LSP servers based on detected languages
local function setup_servers(lspconfig, capabilities, on_attach)
  local axios = require("axios")
  local detected_langs = axios.get_languages()
  local user_overrides = axios.config.lsp.servers or {}

  for lang, enabled in pairs(detected_langs) do
    if enabled then
      local server_config = servers[lang]

      if server_config then
        local lsp_name = server_config.name
        local binary = server_config.binary

        -- Check if LSP binary exists
        if executable(binary) then
          -- Merge default config with user overrides
          local config = vim.tbl_deep_extend("force", {}, server_config.config or {})

          -- Apply user overrides
          if user_overrides[lsp_name] then
            config = vim.tbl_deep_extend("force", config, user_overrides[lsp_name])
          end

          -- Add capabilities and on_attach
          config.capabilities = capabilities
          config.on_attach = on_attach

          -- Setup the server
          lspconfig[lsp_name].setup(config)
        end
      end
    end
  end
end

return {
  -- LSP Config
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Diagnostic configuration
      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      -- On attach function for LSP keymaps
      local on_attach = function(client, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Navigation
        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gr", vim.lsp.buf.references, "Go to references")
        map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
        map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")

        -- Hover/signature
        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        map("n", "gK", vim.lsp.buf.signature_help, "Signature help")
        map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")

        -- Actions
        map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
        map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format buffer")

        -- Workspace
        map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
        map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
        map("n", "<leader>lwl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "List workspace folders")

        -- Inlay hints (if supported)
        if client.supports_method("textDocument/inlayHint") then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          map("n", "<leader>lh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, "Toggle inlay hints")
        end
      end

      -- Setup all detected language servers
      setup_servers(lspconfig, capabilities, on_attach)
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        nix = { "nixfmt" },
        python = { "ruff_format" },
        rust = { "rustfmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        go = { "gofmt" },
        zig = { "zigfmt" },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    },
    init = function()
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, { desc = "Disable autoformat-on-save", bang = true })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = "Enable autoformat-on-save" })
    end,
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        python = { "ruff" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
