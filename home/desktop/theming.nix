{
  inputs,
  config,
  pkgs,
  ...
}:

let
  codeExtDir = "${config.home.homeDirectory}/.vscode/extensions";
  themeProjectDir = "${config.home.homeDirectory}/.config/material-code-theme";

  gtk4Css = "${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css";
  gtk3Css = "${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css";
  qt6ct = "${config.home.homeDirectory}/.config/qt6ct/colors/matugen.conf";
  qt5ct = "${config.home.homeDirectory}/.config/qt5ct/colors/matugen.conf";

  base16ExtDir = "${codeExtDir}/local.dynamic-base16-dankshell-0.0.1";
in
{
  # Basic theming for all WMs
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    dotIcons.enable = true;
  };

  # Note: GTK and Qt theming managed manually by user to avoid clobbering existing configs
  # Theming packages (papirus-icon-theme, adw-gtk3, qt5ct, qt6ct) installed in modules/desktop
  # Dynamic colors handled via dank-colors.css (GTK) and kdeglobals template (KDE/Qt apps)

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
  };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    XCURSOR_THEME = "Bibata-Modern-Ice";
  };

  # Dank Colors integration
  xdg.configFile."gtk-4.0/gtk.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css";
    force = true; # override anything the gtk module would write
  };

  xdg.configFile."gtk-3.0/gtk.css" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css";
    force = true;
  };

  # Note: qt5ct/qt6ct configuration files are managed by the user via qt5ct/qt6ct GUI tools
  # The packages are installed in modules/desktop/default.nix
  # Users can configure icon themes (recommend Papirus-Dark) and color schemes via the GUI

  # Flatpak Theming
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        "color-scheme" = "prefer-dark";
      };
    };
  };

  # Flatpak per-user overrides (GTK3 apps pick up your theme/cursor)
  xdg.dataFile."flatpak/overrides/global".text = ''
    [Context]
    filesystems=xdg-config/gtk-3.0:ro;xdg-config/gtk-4.0:ro
  '';

  # Register matugen templates for dynamic theming
  # This handles both neovim and ghostty template registration with matugen
  home.activation.registerMatugenTemplates = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    MATUGEN_CONFIG="${config.home.homeDirectory}/.config/matugen/config.toml"

    # Create config directory if it doesn't exist
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen

    # Ensure [config] section exists
    if ! grep -q "^\[config\]" "$MATUGEN_CONFIG" 2>/dev/null; then
      echo "[config]" >> "$MATUGEN_CONFIG"
      echo "" >> "$MATUGEN_CONFIG"
    fi

    # Register neovim dankshell vim template
    if [ -f "$MATUGEN_CONFIG" ] && grep -q "dankshell.vim" "$MATUGEN_CONFIG" 2>/dev/null; then
      echo "Neovim dankshell template already registered in matugen"
    else
      echo "[templates.dankshell-vim]" >> "$MATUGEN_CONFIG"
      echo "input_path = '${config.home.homeDirectory}/.config/matugen/templates/base16-vim.mustache'" >> "$MATUGEN_CONFIG"
      echo "output_path = '${config.home.homeDirectory}/.config/nvim/colors/dankshell.vim'" >> "$MATUGEN_CONFIG"
      echo "" >> "$MATUGEN_CONFIG"
      echo "Registered neovim dankshell template with matugen"
    fi

    # Register ghostty template with current DMS path
    # Use direct reference to DMS package from inputs (PATH not available during activation)
    DMS_PATH="${inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.default}"
    if [ -n "$DMS_PATH" ]; then
      GHOSTTY_TEMPLATE="$DMS_PATH/share/quickshell/dms/matugen/templates/ghostty.conf"

      if [ -f "$GHOSTTY_TEMPLATE" ]; then
        # Remove any existing ghostty template entries (may point to old DMS paths)
        if grep -q "\[templates\.ghostty\]" "$MATUGEN_CONFIG" 2>/dev/null; then
          # Create temp file without ghostty section
          ${pkgs.gawk}/bin/awk '/\[templates\.ghostty\]/,/^$/ {next} {print}' "$MATUGEN_CONFIG" > "$MATUGEN_CONFIG.tmp"
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
      echo "Warning: DMS package not available, skipping ghostty template registration"
    fi

    # Register kdeglobals template for KDE Connect and other KDE apps
    # Use DMS's kcolorscheme.colors template which is already well-tested
    if [ -n "$DMS_PATH" ] && [ -f "$DMS_PATH/share/quickshell/dms/matugen/templates/kcolorscheme.colors" ]; then
      KDEGLOBALS_TEMPLATE="$DMS_PATH/share/quickshell/dms/matugen/templates/kcolorscheme.colors"

      # Remove any existing kdeglobals template entries (may point to old path)
      if grep -q "\[templates\.kdeglobals\]" "$MATUGEN_CONFIG" 2>/dev/null; then
        ${pkgs.gawk}/bin/awk '/\[templates\.kdeglobals\]/,/^$/ {next} {print}' "$MATUGEN_CONFIG" > "$MATUGEN_CONFIG.tmp"
        mv "$MATUGEN_CONFIG.tmp" "$MATUGEN_CONFIG"
        echo "Removed old kdeglobals template registration"
      fi

      # Always register kdeglobals template with current DMS path
      echo "[templates.kdeglobals]" >> "$MATUGEN_CONFIG"
      echo "input_path = '$KDEGLOBALS_TEMPLATE'" >> "$MATUGEN_CONFIG"
      echo "output_path = '${config.home.homeDirectory}/.config/kdeglobals'" >> "$MATUGEN_CONFIG"
      echo "" >> "$MATUGEN_CONFIG"
      echo "Registered kdeglobals template with matugen (using DMS kcolorscheme.colors)"
    else
      echo "Warning: DMS kcolorscheme template not found, skipping kdeglobals template registration"
    fi
  '';

  # Register base16 VSCode extension so VSCode can detect it
  home.activation.registerVSCodeExtension = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "${base16ExtDir}" ]; then
      $DRY_RUN_CMD chmod -R u+rwX "${base16ExtDir}" 2>/dev/null || true

      extJson="${codeExtDir}/extensions.json"
      extId="local.dynamic-base16-dankshell"

      # Ensure extensions.json exists
      if [ ! -f "$extJson" ]; then
        $DRY_RUN_CMD mkdir -p "${codeExtDir}"
        echo '[]' > "$extJson"
      fi

      # Only register if not already in extensions.json
      if ! grep -q "$extId" "$extJson" 2>/dev/null; then
        timestamp=$(date +%s)000

        # Add extension entry to extensions.json
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq '. += [{
          "identifier": {"id": "'"$extId"'"},
          "version": "0.0.1",
          "location": {
            "$mid": 1,
            "path": "'"${base16ExtDir}"'",
            "scheme": "file"
          },
          "relativeLocation": "local.dynamic-base16-dankshell-0.0.1",
          "metadata": {
            "installedTimestamp": '"$timestamp"',
            "pinned": false,
            "source": "gallery",
            "targetPlatform": "undefined",
            "updated": false,
            "private": false,
            "isPreReleaseVersion": false,
            "hasPreReleaseVersion": false
          }
        }]' "$extJson" > "$extJson.tmp" && mv "$extJson.tmp" "$extJson"
      fi
    fi
  '';
}
