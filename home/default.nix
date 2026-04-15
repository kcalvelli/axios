{ ... }:
{
  # Define home modules for different setups
  # This explicit list serves as API documentation for library consumers
  #
  # NOTE: Calendar/contacts sync has moved to cairn-dav
  # See: https://github.com/kcalvelli/cairn-dav
  flake = {
    homeModules = {
      desktop = import ./desktop;
      firstBoot = import ./first-boot;
      standard = import ./profiles/standard.nix;
      normie = import ./profiles/normie.nix;
      pim = import ./pim;
      ai = import ./ai;
      immich = import ./immich;
      secrets = import ./secrets;
    };
  };
}
