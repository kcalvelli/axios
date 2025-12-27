{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.axios.theming;

  codeExtDir = "${config.home.homeDirectory}/.vscode/extensions";
  themeProjectDir = "${config.home.homeDirectory}/.config/material-code-theme";

  gtk4Css = "${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css";
  gtk3Css = "${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css";
  qt6ct = "${config.home.homeDirectory}/.config/qt6ct/colors/matugen.conf";
  qt5ct = "${config.home.homeDirectory}/.config/qt5ct/colors/matugen.conf";

  base16ExtDir = "${codeExtDir}/local.dynamic-base16-dankshell-0.0.1";
in
{
  options.axios.theming = {
    useAxiosTemplates = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use axios custom templates instead of DMS-managed templates.

        When false (default): DMS manages all application themes via control panel checkboxes.
        axios only provides Kate syntax highlighting theme.

        When true (legacy mode): axios manages template registration for neovim, ghostty,
        and KDE color schemes. Use this if DMS template management fails.

        Note: Requires uncommenting custom template lines in home/terminal/neovim.nix.
      '';
    };
  };

  config = {
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

  # Deploy Kate syntax highlighting theme template
  # Note: This is NOT redundant with DMS - DMS provides KDE color schemes (.colors files)
  # but NOT Kate syntax highlighting themes (.theme files for code editor text styles)
  xdg.configFile."matugen/templates/kate-dankshell.mustache" = {
    source = ../terminal/resources/kate-dankshell.mustache;
  };

  # Ensure Kate themes directory exists
  home.activation.createKateThemesDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.local/share/org.kde.syntax-highlighting/themes
  '';

  # Register matugen templates for dynamic theming
  # By default, DMS manages templates via its control panel checkboxes
  # Set axios.theming.useAxiosTemplates = true to revert to axios-managed templates
  home.activation.registerMatugenTemplates = config.lib.dag.entryAfter [ "writeBoundary" ] (
    if cfg.useAxiosTemplates then
      # LEGACY MODE: axios manages all templates
      # This is the old behavior - kept for easy rollback if DMS templates fail
      ''
        MATUGEN_CONFIG="${config.home.homeDirectory}/.config/matugen/config.toml"

        # Create config directory if it doesn't exist
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen/templates

        # Get DMS path for templates
        DMS_PATH="${inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.default}"

        echo "Using axios-managed templates (legacy mode)"

        # Generate clean matugen config file
        cat > "$MATUGEN_CONFIG" << 'MATUGEN_EOF'
    [config]

    [templates.dankshell-vim]
    input_path = '${config.home.homeDirectory}/.config/matugen/templates/base16-vim.mustache'
    output_path = '${config.home.homeDirectory}/.config/nvim/colors/dankshell.vim'

    [templates.kate-dankshell]
    input_path = '${config.home.homeDirectory}/.config/matugen/templates/kate-dankshell.mustache'
    output_path = '${config.home.homeDirectory}/.local/share/org.kde.syntax-highlighting/themes/DankShell.theme'
    MATUGEN_EOF

        # Add ghostty template if available
        if [ -n "$DMS_PATH" ] && [ -f "$DMS_PATH/share/quickshell/dms/matugen/templates/ghostty.conf" ]; then
          cat >> "$MATUGEN_CONFIG" << MATUGEN_EOF

    [templates.ghostty]
    input_path = '$DMS_PATH/share/quickshell/dms/matugen/templates/ghostty.conf'
    output_path = '${config.home.homeDirectory}/.config/ghostty/config-dankcolors'
    MATUGEN_EOF
          echo "Registered ghostty template with matugen"
        fi

        # Add kdeglobals template if available
        if [ -n "$DMS_PATH" ] && [ -f "$DMS_PATH/share/quickshell/dms/matugen/templates/kcolorscheme.colors" ]; then
          cat >> "$MATUGEN_CONFIG" << MATUGEN_EOF

    [templates.kdeglobals]
    input_path = '$DMS_PATH/share/quickshell/dms/matugen/templates/kcolorscheme.colors'
    output_path = '${config.home.homeDirectory}/.config/kdeglobals'
    MATUGEN_EOF
          echo "Registered kdeglobals template with matugen"
        fi

        echo "Matugen config generated successfully (vim, kate, ghostty, kdeglobals)"
      ''
    else
      # DEFAULT MODE: DMS manages templates via control panel
      # axios does NOT touch matugen config.toml to avoid overwriting DMS's template registration
      ''
        # Create config directory if it doesn't exist
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen/templates

        echo "Using DMS-managed templates (default mode)"
        echo ""
        echo "Templates managed by DMS control panel checkboxes:"
        echo "  - neovim (requires RRethy/base16-nvim plugin)"
        echo "  - VS Code"
        echo "  - KColorScheme (KDE color schemes)"
        echo "  - Ghostty, kitty, foot, alacritty, wezterm"
        echo "  - GTK, niri, qt5ct, qt6ct"
        echo "  - Firefox, pywalfox, vesktop"
        echo ""
        echo "DMS manages ~/.config/matugen/config.toml based on checkbox settings."
        echo "axios provides Kate syntax highlighting template but does NOT register it"
        echo "automatically to avoid overwriting DMS's config."
        echo ""
        echo "To enable Kate syntax highlighting, either:"
        echo "  1. Wait for DMS to add Kate support, or"
        echo "  2. Manually add to DMS config.toml, or"
        echo "  3. Set axios.theming.useAxiosTemplates = true (legacy mode)"
      ''
  );

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
  };
}
