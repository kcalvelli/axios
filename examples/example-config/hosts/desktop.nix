# Host: desktop (desktop workstation)
{ lib, ... }:
{
  hostConfig = {
    # Basic identification
    hostname = "desktop";
    system = "x86_64-linux";
    formFactor = "desktop";

    # Users on this host (references users/<name>.nix)
    users = [ "alice" ];

    # Hardware configuration
    hardware = {
      cpu = "amd";
      gpu = "amd";
      hasSSD = true;
      isLaptop = false;
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
    homeProfile = "workstation";

    # Path to hardware configuration
    hardwareConfigPath = ./desktop/hardware.nix;

    # Extra NixOS configuration
    extraConfig = {
      axios.system.timeZone = "America/New_York";
    };
  };
}
