-- Language detection and LSP configuration
-- Configures LSP servers based on AXIOS_NVIM_LANGUAGES environment variable

local M = {}

-- Check if a binary exists in PATH
local function executable(name)
  return vim.fn.executable(name) == 1
end

-- Notify user about missing LSP (non-intrusive)
local function notify_missing_lsp(lang, lsp_name)
  vim.defer_fn(function()
    vim.notify(
      string.format("LSP '%s' for %s not found in PATH. Enter a devshell or install it.", lsp_name, lang),
      vim.log.levels.INFO,
      { title = "axios-nvim" }
    )
  end, 1000)
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
          workspace = {
            checkThirdParty = false,
          },
          completion = {
            callSnippet = "Replace",
          },
          telemetry = { enable = false },
          diagnostics = {
            globals = { "vim" },
          },
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
          cargo = {
            allFeatures = true,
            loadOutDirsFromCheck = true,
            runBuildScripts = true,
          },
          checkOnSave = {
            allFeatures = true,
            command = "clippy",
            extraArgs = { "--no-deps" },
          },
          procMacro = {
            enable = true,
            ignored = {
              ["async-trait"] = { "async_trait" },
              ["napi-derive"] = { "napi" },
              ["async-recursion"] = { "async_recursion" },
            },
          },
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
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
          analyses = {
            fieldalignment = true,
            nilness = true,
            unusedparams = true,
            unusedwrite = true,
            useany = true,
          },
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
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
          analysis = {
            autoSearchPaths = true,
            diagnosticMode = "openFilesOnly",
            useLibraryCodeForTypes = true,
          },
        },
      },
    },
  },

  typescript = {
    name = "ts_ls",
    binary = "typescript-language-server",
    config = {},
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },

  cpp = {
    name = "clangd",
    binary = "clangd",
    config = {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
    },
    filetypes = { "c", "cpp", "objc", "objcpp" },
  },

  cs = {
    name = "omnisharp",
    binary = "OmniSharp",
    config = {},
  },
}

-- Setup LSP servers
function M.setup(lspconfig, capabilities, on_attach)
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
        else
          -- Only notify for non-default languages (not nix/lua)
          if lang ~= "nix" and lang ~= "lua" then
            notify_missing_lsp(lang, binary)
          end
        end
      end
    end
  end
end

return M
