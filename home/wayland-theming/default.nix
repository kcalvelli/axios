{ pkgs, config, ... }:
{
  # Theming for all WMs
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

  # For Dank Colors
  xdg.configFile."gtk-4.0/gtk.css" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css";
    force = true; # override anything the gtk module would write
  };

  xdg.configFile."gtk-3.0/gtk.css" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css";
    force = true;
  };

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

    [Environment]
    GTK_THEME=Colloid           
    GTK_USE_PORTAL=1
    XCURSOR_PATH=/run/host/user-share/icons:/run/host/share/icons
  '';
}
