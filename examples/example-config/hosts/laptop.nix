# Host: laptop
{ lib, ... }:
{
  hostConfig = {
    # Basic identification
    hostname = "laptop";
    system = "x86_64-linux";
    formFactor = "laptop";

    # Users on this host (same user as desktop)
    users = [ "alice" ];

    # Hardware configuration
    hardware = {
      cpu = "intel";
      gpu = "intel";
      hasSSD = true;
      isLaptop = true;
    };

    # NixOS modules to enable
    modules = {
      system = true;
      desktop = true;
      development = true;
      graphics = true;
      networking = true;
      users = true;
      virt = false;
      gaming = false;
    };

    # Home-manager profile
    homeProfile = "laptop";

    # Path to hardware configuration
    hardwareConfigPath = ./laptop/hardware.nix;

    # Extra NixOS configuration
    extraConfig = {
      axios.system.timeZone = "America/New_York";
    };
  };
}
