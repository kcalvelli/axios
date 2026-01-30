{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.axios.pwa;

  # Browser package and binary mapping
  browserPkg =
    {
      brave = pkgs.brave;
      chromium = pkgs.chromium;
      google-chrome = pkgs.google-chrome;
    }
    .${cfg.browser};
  browserBin = lib.getExe browserPkg;
  browserWmPrefix =
    {
      brave = "brave";
      chromium = "chromium";
      google-chrome = "chrome";
    }
    .${cfg.browser};

  # Convert URL to browser's app_id format for WM_CLASS matching
  # Format: {browserPrefix}-{domain}{path}-Default
  # Path conversion: first slash -> __, subsequent slashes -> _
  # Port numbers are stripped from the domain
  urlToAppId =
    url:
    let
      withoutProtocol = lib.removePrefix "https://" (lib.removePrefix "http://" url);
      parts = lib.splitString "/" withoutProtocol;
      domainWithPort = lib.head parts;
      domain = lib.head (lib.splitString ":" domainWithPort);
      pathParts = lib.tail parts;
      path = if pathParts == [ ] then "" else "__" + (lib.concatStringsSep "_" pathParts);
    in
    "${browserWmPrefix}-${domain}${path}-Default";

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
    };
  };
in
{
  options.axios.pwa = {
    enable = lib.mkEnableOption "PWA apps with configurable browser backend";

    browser = lib.mkOption {
      type = lib.types.enum [
        "brave"
        "chromium"
        "google-chrome"
      ];
      default = "chromium";
      description = "Browser to use for PWA app mode";
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
          }
        ) (import ../../pkgs/pwa-apps/pwa-defs.nix);
      })

      # Part 2: Desktop entries, icons, and browser package
      {
        home.packages = [ browserPkg ];

        xdg.desktopEntries = lib.mapAttrs (
          appId: app:
          let
            wmClass = urlToAppId app.url;
            dataDir = "${config.home.homeDirectory}/.local/share/axios-pwa/${appId}";
            execCmd =
              if app.isolated then
                ''${browserBin} --user-data-dir=${dataDir} --class=${wmClass} "--app=${app.url}"''
              else
                ''${browserBin} "--app=${app.url}"'';
          in
          {
            name = app.name;
            comment = if app.description != null then app.description else "Launch ${app.name} as a PWA";
            exec = execCmd;
            icon = appId;
            terminal = false;
            categories = app.categories;
            mimeType = app.mimeTypes;
            settings.StartupWMClass = wmClass;
            actions = lib.mapAttrs (_: action: {
              name = action.name;
              exec =
                if app.isolated then
                  ''${browserBin} --user-data-dir=${dataDir} --class=${wmClass} "--app=${action.url}"''
                else
                  ''${browserBin} "--app=${action.url}"'';
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
