{ config, lib, ... }:
let
  cfg = config.axios.system;
in
{
  options.axios.system = {
    timeZone = lib.mkOption {
      type = lib.types.str;
      description = ''
        System timezone (e.g., "America/New_York", "Europe/London", "Asia/Tokyo").

        This is a required setting. Use `timedatectl list-timezones` to see available timezones.
      '';
      example = "America/New_York";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = ''
        Default system locale.

        UTF-8 locales are recommended for compatibility.
      '';
      example = "en_GB.UTF-8";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.timeZone != "";
        message = "axios.system.timeZone must be set in your host configuration";
      }
    ];

    # Set timezone from axios.system option
    time.timeZone = cfg.timeZone;

    # Locale configuration with sensible UTF-8 defaults
    i18n = {
      defaultLocale = lib.mkDefault cfg.locale;
      supportedLocales = lib.mkDefault [ "${cfg.locale}/UTF-8" ];

      extraLocaleSettings = lib.mkDefault {
        LC_ADDRESS = cfg.locale;
        LC_IDENTIFICATION = cfg.locale;
        LC_MEASUREMENT = cfg.locale;
        LC_MONETARY = cfg.locale;
        LC_NAME = cfg.locale;
        LC_NUMERIC = cfg.locale;
        LC_PAPER = cfg.locale;
        LC_TELEPHONE = cfg.locale;
        LC_TIME = cfg.locale;
      };
    };
  };
}
