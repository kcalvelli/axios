{ config, lib, ... }:

{
  # Enable Syncthing for desktop users (Photos sync from mobile devices)
  services.syncthing = {
    enable = true;

    # Enable tray icon for easy access
    tray.enable = true;

    # Configure Syncthing settings
    settings = {
      options = {
        # Enable NAT traversal for connecting across networks
        natEnabled = true;
        # Enable local discovery (same network)
        localAnnounceEnabled = true;
        # Enable global discovery (internet)
        globalAnnounceEnabled = true;
        # Enable UPnP for automatic port forwarding
        upnpEnabled = true;
      };

      # Configure Pictures folder for photo sync
      folders = {
        "Pictures" = {
          path = "${config.home.homeDirectory}/Pictures";
          id = "pictures";
          label = "Pictures";
          # Receive-only: desktop acts as permanent archive
          # Deletions on phone will NOT delete from desktop
          type = "receiveonly";
          # Non-destructive versioning: keep overwritten files for 30 days
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
