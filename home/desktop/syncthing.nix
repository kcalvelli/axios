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
          # Non-destructive versioning: keep deleted/modified files for 30 days
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
