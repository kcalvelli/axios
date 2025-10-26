{ ... }:
{
  # Define home modules for different setups
  flake = {
    homeModules = {
      wayland = ./wayland.nix;
      workstation = ./workstation.nix;
      laptop = ./laptop.nix;
    };
  };
}
