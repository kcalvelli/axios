-- Plugin specifications aggregator
-- Collects all plugin specs from individual files

local axios = require("axios")

local plugins = {}

-- Helper to add plugins from a module if not disabled
local function add_plugins(module_name)
  local ok, module = pcall(require, "axios.plugins." .. module_name)
  if ok and type(module) == "table" then
    for _, plugin in ipairs(module) do
      -- Check if plugin is disabled
      local plugin_name = type(plugin) == "string" and plugin or plugin[1]
      if plugin_name and not axios.is_disabled(plugin_name) then
        table.insert(plugins, plugin)
      end
    end
  end
end

-- Core plugins (always loaded)
add_plugins("which-key")
add_plugins("ui")
add_plugins("editor")

-- Navigation
add_plugins("telescope")
add_plugins("explorer")
add_plugins("terminal")

-- Development
add_plugins("treesitter")
add_plugins("lsp")
add_plugins("completion")

-- Git
add_plugins("git")

-- Debugging
add_plugins("debug")

-- Session
add_plugins("session")

-- AI (conditional)
if axios.ai_enabled() then
  add_plugins("ai")
end

return plugins
