{ inputs, self, ... }:
{
  # Configure home-manager for user configurations
  # User accounts are defined in your config repo via userModulePath parameter
  home-manager = {
    # useGlobalPkgs and useUserPackages are set in system/default.nix
    extraSpecialArgs = {
      inherit inputs self;
    };
  };
}
