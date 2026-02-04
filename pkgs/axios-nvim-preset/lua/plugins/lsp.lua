-- LSP Configuration (using Neovim 0.11+ native API)

-- Check if a binary exists in PATH
local function executable(name)
  return vim.fn.executable(name) == 1
end

-- Language server configurations
local servers = {
  -- Always enabled
  nil_ls = {
    cmd = { "nil" },
    filetypes = { "nix" },
    settings = {
      ["nil"] = {
        formatting = { command = { "nixfmt" } },
      },
    },
  },

  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        completion = { callSnippet = "Replace" },
        telemetry = { enable = false },
        diagnostics = { globals = { "vim" } },
      },
    },
  },

  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true, loadOutDirsFromCheck = true, runBuildScripts = true },
        checkOnSave = { allFeatures = true, command = "clippy", extraArgs = { "--no-deps" } },
        procMacro = { enable = true },
      },
    },
  },

  zls = {
    cmd = { "zls" },
    filetypes = { "zig" },
  },

  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
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

  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    settings = {
      python = {
        analysis = { autoSearchPaths = true, diagnosticMode = "openFilesOnly", useLibraryCodeForTypes = true },
      },
    },
  },

  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },

  clangd = {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
  },
}

-- Map language to server name
local lang_to_server = {
  nix = "nil_ls",
  lua = "lua_ls",
  rust = "rust_analyzer",
  zig = "zls",
  go = "gopls",
  python = "pyright",
  typescript = "ts_ls",
  cpp = "clangd",
}

return {
  -- LSP using native Neovim 0.11+ API
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
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

      -- Get detected languages
      local detected_langs = { nix = true, lua = true } -- Always enabled
      local ok, axios = pcall(require, "axios")
      if ok then
        for lang, enabled in pairs(axios.get_languages()) do
          if enabled then
            detected_langs[lang] = true
          end
        end
      end

      -- Configure and enable servers for detected languages
      for lang, enabled in pairs(detected_langs) do
        if enabled then
          local server_name = lang_to_server[lang]
          if server_name then
            local server_config = servers[server_name]
            if server_config and server_config.cmd and executable(server_config.cmd[1]) then
              -- Configure the server using native API
              vim.lsp.config(server_name, {
                cmd = server_config.cmd,
                filetypes = server_config.filetypes,
                settings = server_config.settings or {},
                capabilities = capabilities,
              })
              -- Enable the server
              vim.lsp.enable(server_name)
            end
          end
        end
      end

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
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

          -- Inlay hints (if supported)
          if client and client.supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            map("n", "<leader>lh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
            end, "Toggle inlay hints")
          end
        end,
      })
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
