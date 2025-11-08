{ config, lib, ... }:
let
  cfg = config.networking.samba;
in
{
  options.networking.samba = {
    enableUserShares = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable automatic Samba shares for common user directories.
        Creates shares for Music, Pictures, Videos, and Documents directories
        for all normal users on the system.
      '';
    };

    sharedDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "Music" "Pictures" "Videos" "Documents" ];
      description = ''
        List of directories to share from each user's home directory.
        Only applies when enableUserShares is true.
      '';
    };
  };

  config = {
    services.samba = {
      enable = true;
      openFirewall = true;

      # Disable legacy NetBIOS browser; prefer WS-Discovery instead.
      nmbd.enable = false;

      settings = lib.mkMerge [
        # Base global settings
        {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = "%h Samba";
            "map to guest" = "Bad User";

            # Security posture
            "smb encrypt" = "required"; # or "desired" if you need broader client support
            "server min protocol" = "SMB2_02";
            "client min protocol" = "SMB2_02";
            "ntlm auth" = "no"; # disable NTLMv1

            # We're not doing classic browsing / WINS
            "wins support" = "no";
            "local master" = "no";
            "domain master" = "no";
            "preferred master" = "no";
            "dns proxy" = "no";

            # Printer stack off (speeds up startup if you don't share printers)
            "load printers" = "no";
            "disable spoolss" = "yes";
            "printing" = "bsd";
            "printcap name" = "/dev/null";
          };

          # --- Example public share ---
          public = {
            path = "/srv/samba/public"; # <-- REQUIRED
            "read only" = "no";
            "guest ok" = "no"; # set "yes" if you want guest access
            browseable = "yes";
            # "valid users" = "@smbshare";  # optional: restrict to a group
          };

          # --- Homes share (special Samba share) ---
          homes = {
            browseable = "no";
            "read only" = "no";
            "guest ok" = "no";
          };
        }

        # Add user directory shares
        (lib.mkIf cfg.enableUserShares (
          let
            # Get all normal users
            normalUsers = lib.filterAttrs (_name: user: user.isNormalUser or false) config.users.users;

            # Generate share config for a user's directory
            mkUserShare = username: shareName: {
              name = "${username}-${shareName}";
              value = {
                path = "/home/${username}/${shareName}";
                writable = "yes";
                "guest ok" = "no";
                "valid users" = username;
                browseable = "yes";
                comment = "${username}'s ${shareName}";
              };
            };

            # Generate all shares for all users
            userShares = lib.concatMap
              (username:
                map (dir: mkUserShare username dir) cfg.sharedDirectories
              )
              (builtins.attrNames normalUsers);
          in
          builtins.listToAttrs userShares
        ))
      ];
    };

    # Modern Windows discovery without NetBIOS:
    services.samba-wsdd.enable = true;

    # Optional: create the public share directory and group
    users.groups.smbshare = { };
    systemd.tmpfiles.rules = [
      "d /srv/samba/public 0770 root smbshare - -"
    ];
  };
}
