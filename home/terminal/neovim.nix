{
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.lazyvim.homeManagerModules.default
  ];

  # Deploy base16 template to matugen templates directory
  xdg.configFile."matugen/templates/base16-vim.mustache" = {
    source = ./resources/base16-vim.mustache;
  };

  # Ensure nvim colors directory exists
  home.activation.createNvimColorsDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/nvim/colors
  '';

  # Register template with matugen
  home.activation.registerMatugenTemplate = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    MATUGEN_CONFIG="${config.home.homeDirectory}/.config/matugen/config.toml"

    if [ -f "$MATUGEN_CONFIG" ]; then
      if ! grep -q "base16-vim.mustache" "$MATUGEN_CONFIG" 2>/dev/null; then
        echo "" >> "$MATUGEN_CONFIG"
        echo "# axiOS neovim base16 colorscheme" >> "$MATUGEN_CONFIG"
        echo "[[templates]]" >> "$MATUGEN_CONFIG"
        echo "input_path = \"${config.home.homeDirectory}/.config/matugen/templates/base16-vim.mustache\"" >> "$MATUGEN_CONFIG"
        echo "output_path = \"${config.home.homeDirectory}/.config/nvim/colors/base16-dankshell.vim\"" >> "$MATUGEN_CONFIG"
        echo "Registered base16-vim template with matugen"
      fi
    fi
  '';

  # Generate initial theme notification
  home.activation.generateInitialTheme = config.lib.dag.entryAfter [ "registerMatugenTemplate" ] ''
    THEME_FILE="${config.home.homeDirectory}/.config/nvim/colors/base16-dankshell.vim"

    if [ ! -f "$THEME_FILE" ]; then
      echo "Note: base16-dankshell colorscheme will generate on first wallpaper change"
    fi
  '';

  programs.neovim = {
    enable = true;
    # Aliases removed - keeping vim separate from nvim
  };

  programs.lazyvim = {
    enable = true;

    # Configure colorscheme with fallback handling
    extraLuaConfig = ''
      -- Load base16-dankshell colorscheme if available
      -- Fall back to catppuccin if theme hasn't been generated yet
      local ok, _ = pcall(vim.cmd, "colorscheme base16-dankshell")
      if not ok then
        vim.notify("base16-dankshell not found, using default theme", vim.log.levels.WARN)
        vim.notify("Theme will generate on first wallpaper change", vim.log.levels.INFO)
        -- Fall back to catppuccin (lazyvim default)
        vim.cmd("colorscheme catppuccin")
      end
    '';

    extras = {
      coding = {
        blink.enable = true;
        mini-surround.enable = true;
        yanky.enable = true;
      };
      formatting = {
        prettier.enable = true;
      };
      dap = {
        core.enable = true;
      };
      util = {
        dot = {
          enable = true;
        };
      };
      lang = {
        nix.enable = true;
        markdown.enable = true;
        zig.enable = true;
      };
    };
  };
}
