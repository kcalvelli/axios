{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.axios.pwa;

  # Convert user-friendly icon path to store path
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
        description = "Icon name (without extension) - must match a .png file in iconPath";
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
    };
  };
in
{
  options.axios.pwa = {
    enable = lib.mkEnableOption "PWA apps with Brave Nightly";

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

    extraApps = lib.mkOption {
      type = lib.types.attrsOf pwaAppType;
      default = { };
      example = lib.literalExpression ''
        {
          immich = {
            name = "Immich";
            url = "https://photos.example.com";
            icon = "immich";
            categories = [ "Graphics" "Photography" ];
          };
        }
      '';
      description = "Additional PWA definitions to include";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.pwa-apps.override {
        extraDefs =
          if cfg.includeDefaults then
            cfg.extraApps
          else
            # If not including defaults, pass empty base and only extra apps
            cfg.extraApps;
        extraIconPaths = lib.optional (cfg.iconPath != null) cfg.iconPath;
      })
    ];
  };
}
