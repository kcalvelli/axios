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

  # Register templates with matugen
  home.activation.registerMatugenTemplate = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    MATUGEN_CONFIG="${config.home.homeDirectory}/.config/matugen/config.toml"

    # Create config directory if it doesn't exist
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen

    # Ensure [config] section exists
    if ! grep -q "^\[config\]" "$MATUGEN_CONFIG" 2>/dev/null; then
      echo "[config]" >> "$MATUGEN_CONFIG"
      echo "" >> "$MATUGEN_CONFIG"
    fi

    # Register dankshell vim template
    if [ -f "$MATUGEN_CONFIG" ] && grep -q "dankshell.vim" "$MATUGEN_CONFIG" 2>/dev/null; then
      echo "dankshell vim template already registered in matugen"
    else
      echo "[templates.dankshell-vim]" >> "$MATUGEN_CONFIG"
      echo "input_path = '${config.home.homeDirectory}/.config/matugen/templates/base16-vim.mustache'" >> "$MATUGEN_CONFIG"
      echo "output_path = '${config.home.homeDirectory}/.config/nvim/colors/dankshell.vim'" >> "$MATUGEN_CONFIG"
      echo "" >> "$MATUGEN_CONFIG"
      echo "Registered dankshell vim template with matugen"
    fi

    # Register ghostty template with current DMS path
    # Find current DMS store path
    DMS_BIN=$(which dms 2>/dev/null || echo "")
    if [ -n "$DMS_BIN" ]; then
      DMS_PATH=$(readlink -f "$DMS_BIN" | xargs dirname | xargs dirname)
      GHOSTTY_TEMPLATE="$DMS_PATH/share/quickshell/dms/matugen/templates/ghostty.conf"

      if [ -f "$GHOSTTY_TEMPLATE" ]; then
        # Remove any existing ghostty template entries (may point to old DMS paths)
        if grep -q "\[templates\.ghostty\]" "$MATUGEN_CONFIG" 2>/dev/null; then
          # Create temp file without ghostty section
          awk '/\[templates\.ghostty\]/,/^$/ {next} {print}' "$MATUGEN_CONFIG" > "$MATUGEN_CONFIG.tmp"
          mv "$MATUGEN_CONFIG.tmp" "$MATUGEN_CONFIG"
          echo "Removed outdated ghostty template registration"
        fi

        # Add ghostty template with current DMS path
        echo "[templates.ghostty]" >> "$MATUGEN_CONFIG"
        echo "input_path = '$GHOSTTY_TEMPLATE'" >> "$MATUGEN_CONFIG"
        echo "output_path = '${config.home.homeDirectory}/.config/ghostty/config-dankcolors'" >> "$MATUGEN_CONFIG"
        echo "" >> "$MATUGEN_CONFIG"
        echo "Registered ghostty template with matugen (DMS path: $DMS_PATH)"
      else
        echo "Warning: DMS ghostty template not found at $GHOSTTY_TEMPLATE"
      fi
    else
      echo "Warning: dms command not found, skipping ghostty template registration"
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
