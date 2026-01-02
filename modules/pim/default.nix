{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.pim;
in
{
  options.pim = {
    enable = lib.mkEnableOption "Personal Information Management (email, calendar, contacts)";

    emailClient = lib.mkOption {
      type = lib.types.enum [
        "geary"
        "evolution"
        "both"
      ];
      default = "geary";
      description = ''
        Email client to install:
        - geary: Modern, lightweight email client
        - evolution: Full-featured email client with better Exchange/EWS support
        - both: Install both clients
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # === PIM Packages ===
    environment.systemPackages =
      with pkgs;
      [
        # Account Management
        gnome-online-accounts-gtk # GTK UI for account configuration (D-Bus backend)

        # Calendar & Contacts
        gnome-calendar # Calendar app with online account sync
        gnome-contacts # Contact management app with online account sync

        # Email Support
        evolution-ews # Exchange Web Services support for Evolution/GNOME

        # Calendar/Contact Sync Tool
        vdirsyncer # CLI tool for syncing calendars and contacts

        # Email Clients (conditional)
      ]
      ++ lib.optionals (cfg.emailClient == "geary" || cfg.emailClient == "both") [
        geary # Modern, simpler email client
      ]
      ++ lib.optionals (cfg.emailClient == "evolution" || cfg.emailClient == "both") [
        # Evolution is enabled via programs.evolution below
      ];

    # === PIM Programs ===
    programs = {
      evolution.enable = (cfg.emailClient == "evolution" || cfg.emailClient == "both");
    };

    # === PIM Services ===
    services = {
      gnome = {
        evolution-data-server.enable = true; # Calendar/contacts data backend
        gnome-online-accounts.enable = true; # Account management backend
      };
      geoclue2.enable = true; # Location services for weather in gnome-calendar
    };
  };
}
