# Host: server (headless)
{ lib, ... }:
{
  hostConfig = {
    # Basic identification
    hostname = "server";
    system = "x86_64-linux";
    formFactor = "desktop";

    # Users on this host
    users = [ "admin" ];

    # Hardware configuration
    hardware = {
      cpu = "intel";
      gpu = "intel";
      hasSSD = true;
      isLaptop = false;
    };

    # NixOS modules to enable
    modules = {
      system = true;
      desktop = false; # No desktop on server
      development = true;
      graphics = false; # No graphics drivers
      networking = true;
      users = true;
      virt = true; # Enable virtualization
      gaming = false;
    };

    # Virtualization settings
    virt = {
      libvirt.enable = true;
      containers.enable = true;
    };

    # Home-manager profile
    homeProfile = "workstation";

    # Path to hardware configuration
    hardwareConfigPath = ./server/hardware.nix;

    # Extra NixOS configuration
    extraConfig = {
      axios.system.timeZone = "America/New_York";
    };
  };
}
