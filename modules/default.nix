{
  # Define all the modules that are available in the system
  flake.nixosModules = {
    system = ./system;
    desktop = ./desktop.nix;
    development = ./development.nix;
    hardware = ./hardware;
    graphics = ./graphics.nix;
    networking = ./networking;
    services = ./services;
    users = ./users.nix;
    virt = ./virtualisation.nix;
    desktopHardware = ./hardware/desktop.nix;
    laptopHardware = ./hardware/laptop.nix;
    gaming = ./gaming.nix;
  };
}
