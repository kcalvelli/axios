{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:

let
  cfg = config.axios.pwa;

  # Hardware acceleration flags from NixOS desktop module (GPU-aware)
  browserArgs = osConfig.desktop.browserArgs or { };
  argsFor = browser: browserArgs.${browser} or [ ];
  argsStr = browser: lib.concatStringsSep " " (argsFor browser);

  # Browser type shared between global option and per-app option
  browserEnum = lib.types.enum [
    "brave"
    "chromium"
    "google-chrome"
  ];

  # Browser resolution helpers
  browserPkgFor =
    browser:
    {
      brave = pkgs.brave;
      chromium = pkgs.chromium;
      google-chrome = pkgs.google-chrome;
    }
    .${browser};

  browserBinFor = browser: lib.getExe (browserPkgFor browser);

  # Chromium uses "chrome" internally for WM_CLASS, not "chromium"
  wmPrefixFor =
    browser:
    {
      brave = "brave";
      chromium = "chrome";
      google-chrome = "chrome";
    }
    .${browser};

  # Convert URL to browser's app_id format for WM_CLASS matching
  # Format: {browserPrefix}-{domain}{path}-Default
  # Path conversion: first slash -> __, subsequent slashes -> _
  # Port numbers are stripped from the domain
  urlToAppId =
    browser: url:
    let
      wmPrefix = wmPrefixFor browser;
      withoutProtocol = lib.removePrefix "https://" (lib.removePrefix "http://" url);
      parts = lib.splitString "/" withoutProtocol;
      domainWithPort = lib.head parts;
      domain = lib.head (lib.splitString ":" domainWithPort);
      pathParts = lib.tail parts;
      path = if pathParts == [ ] then "" else "__" + (lib.concatStringsSep "_" pathParts);
    in
    "${wmPrefix}-${domain}${path}-Default";

  # Resolve effective browser for an app (per-app override or global default)
  effectiveBrowser = app: if app.browser != null then app.browser else cfg.browser;

  # Collect unique browser packages needed across all apps
  allBrowserPkgs = lib.unique (
    lib.mapAttrsToList (_: app: browserPkgFor (effectiveBrowser app)) cfg.apps
  );

  # Generate launcher script for a PWA app
  makeLauncher =
    appId: app:
    let
      browser = effectiveBrowser app;
      bin = browserBinFor browser;
      wmClass = urlToAppId browser app.url;
      dataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/${appId}";
      flags = argsStr browser;
      flagsPrefix = if flags != "" then "${flags} " else "";
    in
    pkgs.writeShellScriptBin "pwa-${appId}" (
      if app.isolated then
        ''exec ${bin} ${flagsPrefix}--user-data-dir=${dataDir} --class=${wmClass} "--app=${app.url}" "$@"''
      else
        ''exec ${bin} ${flagsPrefix}"--app=${app.url}" "$@"''
    );

  # PWA app submodule type
  pwaAppType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Display name of the PWA";
      };

      url = lib.mkOption {
        type = lib.types.str;
        description = "URL to open as a PWA";
      };

      icon = lib.mkOption {
        type = lib.types.str;
        description = "Icon name (without extension) - must match a .png file in iconPath or base icons";
      };

      categories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "Network" ];
        description = "Desktop entry categories";
      };

      mimeTypes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "MIME types handled by this PWA";
      };

      actions = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Action display name";
              };
              url = lib.mkOption {
                type = lib.types.str;
                description = "URL for this action";
              };
            };
          }
        );
        default = { };
        description = "Desktop entry actions";
      };

      isolated = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "When true, use an isolated user-data-dir per app";
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Description for the desktop entry comment field";
      };

      browser = lib.mkOption {
        type = lib.types.nullOr browserEnum;
        default = null;
        description = "Browser override for this app. When null, uses the global axios.pwa.browser setting.";
      };
    };
  };
in
{
  options.axios.pwa = {
    enable = lib.mkEnableOption "PWA apps with configurable browser backend";

    browser = lib.mkOption {
      type = browserEnum;
      default = "chromium";
      description = "Default browser to use for PWA app mode. Can be overridden per app.";
    };

    includeDefaults = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include default PWA apps from axios (YouTube, Google Drive, etc.)";
    };

    iconPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to directory containing icon PNG files for extra apps";
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf pwaAppType;
      default = { };
      example = lib.literalExpression ''
        {
          immich = {
            name = "Immich";
            url = "https://photos.example.com";
            icon = "immich";
            categories = [ "Graphics" "Photography" ];
            isolated = true;
          };
          youtube-music = {
            name = "YouTube Music";
            url = "https://music.youtube.com/";
            icon = "youtube-music";
            browser = "brave";  # Widevine DRM support
          };
        }
      '';
      description = "PWA app definitions to generate desktop entries for";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Part 1: Default apps (conditional on includeDefaults)
      (lib.mkIf cfg.includeDefaults {
        axios.pwa.apps = lib.mapAttrs (
          _: def:
          lib.mkDefault {
            inherit (def) name url icon;
            categories = def.categories or [ "Network" ];
            mimeTypes = def.mimeTypes or [ ];
            actions = def.actions or { };
            isolated = false; # Default apps share browser profile
            description = null;
            browser = null; # Use global default
          }
        ) (import ../../pkgs/pwa-apps/pwa-defs.nix);
      })

      # Part 2: Desktop entries, icons, and browser packages
      {
        home.packages = allBrowserPkgs ++ lib.mapAttrsToList makeLauncher cfg.apps;

        xdg.desktopEntries = lib.mapAttrs (
          appId: app:
          let
            browser = effectiveBrowser app;
            bin = browserBinFor browser;
            wmClass = urlToAppId browser app.url;
            dataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/${appId}";
          in
          {
            name = app.name;
            comment = if app.description != null then app.description else "Launch ${app.name} as a PWA";
            exec = "pwa-${appId}";
            icon = appId;
            terminal = false;
            categories = app.categories;
            mimeType = app.mimeTypes;
            settings.StartupWMClass = wmClass;
            actions =
              let
                flags = argsStr browser;
                flagsPrefix = if flags != "" then "${flags} " else "";
              in
              lib.mapAttrs (_: action: {
                name = action.name;
                exec =
                  if app.isolated then
                    ''${bin} ${flagsPrefix}--user-data-dir=${dataDir} --class=${wmClass} "--app=${action.url}"''
                  else
                    ''${bin} ${flagsPrefix}"--app=${action.url}"'';
              }) app.actions;
          }
        ) cfg.apps;

        home.file = lib.mkMerge (
          lib.mapAttrsToList (
            appId: app:
            let
              baseIconPath = ../../home/resources/pwa-icons;
              iconFile = "${app.icon}.png";
              baseIcon = baseIconPath + "/${iconFile}";
              extraIcon = if cfg.iconPath != null then cfg.iconPath + "/${iconFile}" else null;
              iconSource =
                if extraIcon != null && builtins.pathExists extraIcon then
                  extraIcon
                else if builtins.pathExists baseIcon then
                  baseIcon
                else
                  null;
            in
            lib.optionalAttrs (iconSource != null) {
              ".local/share/icons/hicolor/128x128/apps/${appId}.png".source = iconSource;
            }
          ) cfg.apps
        );
      }
    ]
  );
}
