{ config, pkgs, ... }:

let
  codeExtDir = "${config.home.homeDirectory}/.vscode/extensions";
  themeProjectDir = "${config.home.homeDirectory}/.config/material-code-theme";

  gtk4Css = "${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css";
  gtk3Css = "${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css";
  qt6ct = "${config.home.homeDirectory}/.config/qt6ct/colors/matugen.conf";
  qt5ct = "${config.home.homeDirectory}/.config/qt5ct/colors/matugen.conf";
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

  # Material Code VSCode theme integration
  # This updates VSCode theme based on matugen-generated colors
  home.file."${themeProjectDir}/update-theme.ts".text = ''
    import { createTheme, createVsCodeTheme, themeOptions } from 'material-code/theme'
    import { readdir, mkdir, writeFile, readFile, access } from 'node:fs/promises'
    import { constants as fsconst } from 'node:fs'
    import { join, dirname } from 'node:path'

    const files = {
      gtk4: '${gtk4Css}',
      gtk3: '${gtk3Css}',
      qt6:  '${qt6ct}',
      qt5:  '${qt5ct}',
    }

    const HEX = /#[0-9a-fA-F]{6}\b/
    const clampHex = (s?: string) => (s && HEX.test(s) ? s.match(HEX)![0] : undefined)

    async function exists(p: string) {
      try { await access(p, fsconst.F_OK); return true } catch { return false }
    }

    async function parseGtk(path: string) {
      if (!(await exists(path))) return undefined
      const css = await readFile(path, 'utf8')
      const varMatch = css.match(/--(accent|primary)[-_]?(color)?:\s*(#[0-9a-fA-F]{6})/)
      const defMatch = css.match(/@define-color\s+(accent(?:[_-]color)?|primary(?:[_-]color)?)\s+(#[0-9a-fA-F]{6})/)
      const primary = clampHex(varMatch?.[3]) ?? clampHex(defMatch?.[2])
      const bgVar = css.match(/--(base|bg|background)[^:]*:\s*(#[0-9a-fA-F]{6})/i)?.[2]
                 ?? css.match(/@define-color\s+(base|bg|background)[^ ]*\s+(#[0-9a-fA-F]{6})/i)?.[2]
      const bg = clampHex(bgVar)
      const isDark = (() => {
        const hex = bg ?? '#202020'
        const r = parseInt(hex.slice(1,3),16), g = parseInt(hex.slice(3,5),16), b = parseInt(hex.slice(5,7),16)
        const lum = 0.2126*r + 0.7152*g + 0.0722*b
        return lum < 140
      })()
      return { primary, darkMode: isDark }
    }

    async function parseQt(path: string) {
      if (!(await exists(path))) return undefined
      const txt = await readFile(path, 'utf8')
      const keyMatch = txt.match(/^(Accent|Highlight|accent|highlight)\s*=\s*(#[0-9a-fA-F]{6})/m)
      const primary = clampHex(keyMatch?.[2])
      const bgMatch = txt.match(/^(Window|Base|Background)\s*=\s*(#[0-9a-fA-F]{6})/m)
      const bg = clampHex(bgMatch?.[2]) ?? '#202020'
      const r = parseInt(bg.slice(1,3),16), g = parseInt(bg.slice(3,5),16), b = parseInt(bg.slice(5,7),16)
      const lum = 0.2126*r + 0.7152*g + 0.0722*b
      const darkMode = lum < 140
      return { primary, darkMode }
    }

    async function detectPalette() {
      const gtk4 = await parseGtk(files.gtk4); if (gtk4?.primary) return gtk4
      const gtk3 = await parseGtk(files.gtk3); if (gtk3?.primary) return gtk3
      const qt6  = await parseQt(files.qt6);   if (qt6?.primary)  return qt6
      const qt5  = await parseQt(files.qt5);   if (qt5?.primary)  return qt5
      return { primary: '#6c6f93', darkMode: true }
    }

    async function resolveThemeJson(vscodeExtensionsDir: string): Promise<string> {
      const entries = await readdir(vscodeExtensionsDir).catch(() => [])
      const target = entries.find(d => d.includes('material-code'))
      if (!target) {
        throw new Error(
          'material-code extension not found in ' + vscodeExtensionsDir +
          '.\\nInstall it from the Marketplace inside VS Code (not via Nix), then retry.'
        )
      }
      const extRoot = join(vscodeExtensionsDir, target)
      const pkg = JSON.parse(await readFile(join(extRoot, 'package.json'), 'utf8'))
      const themes = (pkg?.contributes?.themes ?? []) as Array<any>
      const pick = themes.find((t: any) => t?.type === 'dark' || t?.uiTheme === 'vs-dark') ?? themes[0]
      if (!pick?.path) return join(extRoot, 'themes', 'dark.json')
      return join(extRoot, pick.path)
    }

    const { primary, darkMode } = await detectPalette()
    const vscodeDir = '${codeExtDir}'
    const themeJsonPath = await resolveThemeJson(vscodeDir)

    const theme = createTheme({ ...themeOptions, darkMode: !!darkMode, primary: primary ?? '#6c6f93' })
    const vscodeTheme = createVsCodeTheme(theme)

    await mkdir(dirname(themeJsonPath), { recursive: true })
    await writeFile(themeJsonPath, JSON.stringify(vscodeTheme, null, 2))
    console.log('Updated theme JSON:', themeJsonPath, '→', primary, darkMode ? '(dark)' : '(light)')
  '';
}
