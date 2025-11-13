{ config, lib, ... }:

{
  # Enable Syncthing for desktop users
  services.syncthing = {
    enable = true;

    # Use XDG data directory for Syncthing data
    tray.enable = true;

    # Configure default folders for XDG directories
    settings = {
      options = {
        # Enable NAT traversal
        natEnabled = true;
        # Enable local discovery
        localAnnounceEnabled = true;
        # Enable global discovery
        globalAnnounceEnabled = true;
        # Enable UPnP
        upnpEnabled = true;
      };

      # Configure default folders to sync XDG directories
      folders = {
        "Documents" = {
          path = "${config.home.homeDirectory}/Documents";
          id = "documents";
          label = "Documents";
          # Versioning: keep 30 days of file history
          versioning = {
            type = "trashcan";
            params = {
              cleanoutDays = "30";
            };
          };
        };

        "Music" = {
          path = "${config.home.homeDirectory}/Music";
          id = "music";
          label = "Music";
          versioning = {
            type = "trashcan";
            params = {
              cleanoutDays = "30";
            };
          };
        };

        "Pictures" = {
          path = "${config.home.homeDirectory}/Pictures";
          id = "pictures";
          label = "Pictures";
          versioning = {
            type = "trashcan";
            params = {
              cleanoutDays = "30";
            };
          };
        };
      };
    };
  };
}
