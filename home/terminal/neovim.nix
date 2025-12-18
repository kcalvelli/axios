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

    # Check if template is already registered with correct output path
    if [ -f "$MATUGEN_CONFIG" ] && grep -q "dankshell.vim" "$MATUGEN_CONFIG" 2>/dev/null; then
      echo "dankshell vim template already registered in matugen"
    else
      # Ensure [config] section exists
      if ! grep -q "^\[config\]" "$MATUGEN_CONFIG" 2>/dev/null; then
        echo "[config]" >> "$MATUGEN_CONFIG"
        echo "" >> "$MATUGEN_CONFIG"
      fi

      # Append template registration using matugen 3.1.0 format
      echo "[templates.dankshell-vim]" >> "$MATUGEN_CONFIG"
      echo "input_path = '${config.home.homeDirectory}/.config/matugen/templates/base16-vim.mustache'" >> "$MATUGEN_CONFIG"
      echo "output_path = '${config.home.homeDirectory}/.config/nvim/colors/dankshell.vim'" >> "$MATUGEN_CONFIG"
      echo "" >> "$MATUGEN_CONFIG"
      echo "Registered dankshell vim template with matugen"
    fi
  '';

  # Note about initial theme generation
  home.activation.noteInitialTheme = config.lib.dag.entryAfter [ "registerMatugenTemplate" ] ''
    THEME_FILE="${config.home.homeDirectory}/.config/nvim/colors/dankshell.vim"

    if [ ! -f "$THEME_FILE" ]; then
      echo "Note: dankshell colorscheme will generate on first wallpaper change via DMS"
      echo "      Neovim will use catppuccin fallback until then"
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
