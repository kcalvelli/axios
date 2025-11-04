{ ... }:
{
  # Define home modules for different setups
  # This explicit list serves as API documentation for library consumers
  flake = {
    homeModules = {
      wayland = ./wayland.nix;
      workstation = ./workstation.nix;
      laptop = ./laptop.nix;
      ai = ./ai;
    };
  };
}
