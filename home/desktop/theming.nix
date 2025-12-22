{ config, pkgs, ... }:

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

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
  };

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

  # Qt6ct configuration for icon theme and matugen colors
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/matugen.conf
    custom_palette=true
    icon_theme=Papirus-Dark
    standard_dialogs=xdgdesktopportal
    style=Fusion

    [Fonts]
    fixed="DejaVu Sans,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="DejaVu Sans,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=1
    wheel_scroll_lines=3

    [Troubleshooting]
    force_raster_widgets=1
    ignored_applications=@Invalid()
  '';

  # Qt5ct configuration for icon theme and matugen colors
  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.home.homeDirectory}/.config/qt5ct/colors/matugen.conf
    custom_palette=true
    icon_theme=Papirus-Dark
    standard_dialogs=xdgdesktopportal
    style=Fusion

    [Fonts]
    fixed="DejaVu Sans,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="DejaVu Sans,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=1
    wheel_scroll_lines=3

    [Troubleshooting]
    force_raster_widgets=1
    ignored_applications=@Invalid()
  '';

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

    # Register kdeglobals template for KDE Connect and other KDE apps
    KDEGLOBALS_TEMPLATE="${config.home.homeDirectory}/.config/matugen/templates/kdeglobals.mustache"

    # Copy kdeglobals template if it doesn't exist or is outdated
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen/templates
    if [ ! -f "$KDEGLOBALS_TEMPLATE" ] || ! cmp -s "${../resources/templates/kdeglobals.mustache}" "$KDEGLOBALS_TEMPLATE" 2>/dev/null; then
      $DRY_RUN_CMD cp "${../resources/templates/kdeglobals.mustache}" "$KDEGLOBALS_TEMPLATE"
      echo "Copied kdeglobals template to matugen templates directory"
    fi

    # Register kdeglobals template with matugen
    if grep -q "kdeglobals" "$MATUGEN_CONFIG" 2>/dev/null; then
      echo "kdeglobals template already registered in matugen"
    else
      echo "[templates.kdeglobals]" >> "$MATUGEN_CONFIG"
      echo "input_path = '$KDEGLOBALS_TEMPLATE'" >> "$MATUGEN_CONFIG"
      echo "output_path = '${config.home.homeDirectory}/.config/kdeglobals'" >> "$MATUGEN_CONFIG"
      echo "" >> "$MATUGEN_CONFIG"
      echo "Registered kdeglobals template with matugen"
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
