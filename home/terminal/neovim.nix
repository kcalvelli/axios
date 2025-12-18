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

    # Create config directory if it doesn't exist
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen

    # Check if template is already registered
    if [ -f "$MATUGEN_CONFIG" ] && grep -q "base16-vim.mustache" "$MATUGEN_CONFIG" 2>/dev/null; then
      echo "base16-vim template already registered in matugen"
    else
      # Append template registration to config.toml (creates file if it doesn't exist)
      echo "" >> "$MATUGEN_CONFIG"
      echo "# axiOS neovim base16 colorscheme" >> "$MATUGEN_CONFIG"
      echo "[config]" >> "$MATUGEN_CONFIG"
      echo "[templates.dankshell-vim]" >> "$MATUGEN_CONFIG"
      echo "input_path = \"${config.home.homeDirectory}/.config/matugen/templates/base16-vim.mustache\"" >> "$MATUGEN_CONFIG"
      echo "output_path = \"${config.home.homeDirectory}/.config/nvim/colors/dankshell.vim\"" >> "$MATUGEN_CONFIG"
      echo "Registered base16-vim template with matugen"
    fi
  '';

  # Generate initial theme if needed
  home.activation.generateInitialTheme = config.lib.dag.entryAfter [ "registerMatugenTemplate" ] ''
    THEME_FILE="${config.home.homeDirectory}/.config/nvim/colors/dankshell.vim"

    if [ ! -f "$THEME_FILE" ]; then
      echo "dankshell colorscheme not found, attempting initial generation..."
      # Try to generate theme if matugen is available and a wallpaper is set
      if command -v matugen &> /dev/null; then
        # Attempt to generate theme (will use current wallpaper if set)
        matugen generate 2>/dev/null || echo "Note: dankshell will generate on first wallpaper change"
      else
        echo "Note: dankshell will generate when DMS/matugen runs"
      fi
    fi
  '';

  programs.neovim = {
    enable = true;
    # Aliases removed - keeping vim separate from nvim
  };

  programs.lazyvim = {
    enable = true;

    # Configure colorscheme with fallback handling
    pluginsFile."colorscheme.lua".source = ./resources/colorscheme.lua;

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
