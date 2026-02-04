{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  # Check if AI module is enabled at system level
  aiEnabled = osConfig.services.ai.enable or false;

  # Template for user's init.lua
  initLuaTemplate = ''
    -- axiOS Neovim Configuration
    -- This file is user-owned - customize freely!

    -- Leader key (MUST be set before loading plugins)
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- Load axios preset with your customizations
    require("axios").setup({
      -- Use DMS-generated colorscheme
      colorscheme = "dankshell",

      -- AI configuration (uncomment and modify as needed)
      -- ai = {
      --   claude = {
      --     auth_type = "api",  -- "api", "pro", or "max"
      --   },
      -- },
    })

    -- Add your custom configuration below:
  '';
in
{
  # Enable neovim via home-manager
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Dependencies that should always be available
    extraPackages = with pkgs; [
      # LSPs (always available)
      nil # Nix
      lua-language-server

      # Formatters
      nixfmt-rfc-style
      stylua

      # Tools needed by plugins
      ripgrep
      fd
      lazygit
      tree-sitter

      # Build tools for plugins
      gcc
      gnumake
    ];

    # Add axios preset to runtimepath via wrapper (doesn't touch user's init.lua)
    extraWrapperArgs = [
      "--cmd"
      "set runtimepath^=${pkgs.axios-nvim-preset}"
    ];
  };

  # Set environment variables for the preset
  home.sessionVariables = lib.mkMerge [
    # AI enabled flag
    (lib.mkIf aiEnabled {
      AXIOS_AI_ENABLED = "1";
    })
  ];

  # Bootstrap init.lua if it doesn't exist (user-owned, not managed by home-manager)
  home.activation.neovimAxiosBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        NVIM_CONFIG_DIR="${config.home.homeDirectory}/.config/nvim"
        INIT_LUA="$NVIM_CONFIG_DIR/init.lua"

        # Only create if no init.lua exists (preserves user customization)
        if [ ! -f "$INIT_LUA" ] || [ -L "$INIT_LUA" ]; then
          # Remove symlink if home-manager created one
          [ -L "$INIT_LUA" ] && rm "$INIT_LUA"
          run mkdir -p "$NVIM_CONFIG_DIR"
          run cat > "$INIT_LUA" << 'AXIOSEOF'
    ${initLuaTemplate}
    AXIOSEOF
          verbose "Created neovim config with axios IDE preset"
        fi
  '';
}
