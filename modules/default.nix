{
  # Define all the modules that are available in the system
  # This explicit list serves as API documentation for library consumers
  flake.nixosModules = {
    system = ./system;
    desktop = ./desktop;
    development = ./development;
    hardware = ./hardware;
    graphics = ./graphics;
    networking = ./networking;
    users = ./users.nix;
    virt = ./virtualisation;
    desktopHardware = ./hardware/desktop.nix;
    laptopHardware = ./hardware/laptop.nix;
    gaming = ./gaming;
    ai = ./ai;
    secrets = ./secrets;
  };
}
