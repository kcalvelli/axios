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

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        "color-scheme" = "prefer-dark";
      };
    };
  };

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
