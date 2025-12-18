{ ... }:
{
  # Define home modules for different setups
  # This explicit list serves as API documentation for library consumers
  flake = {
    homeModules = {
      desktop = ./desktop;
      workstation = ./profiles/workstation.nix;
      laptop = ./profiles/laptop.nix;
      ai = ./ai;
      secrets = ./secrets;
      calendar = ./calendar;
    };
  };
}
