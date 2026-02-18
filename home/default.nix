{ ... }:
{
  # Define home modules for different setups
  # This explicit list serves as API documentation for library consumers
  #
  # NOTE: Calendar/contacts sync has moved to axios-dav
  # See: https://github.com/kcalvelli/axios-dav
  flake = {
    homeModules = {
      desktop = ./desktop;
      standard = ./profiles/standard.nix;
      normie = ./profiles/normie.nix;
      pim = ./pim;
      ai = ./ai;
      immich = ./immich;
      secrets = ./secrets;
    };
  };
}
