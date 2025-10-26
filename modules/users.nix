{ inputs, self, ... }:
{
  # Configure home-manager for user configurations
  # User accounts are defined in your config repo via userModulePath parameter
  home-manager = {
    useGlobalPkgs = false; # Use separate nixpkgs instance for home-manager
    useUserPackages = true; # Install user packages directly to the user's profile
    extraSpecialArgs = {
      inherit inputs self;
    };
  };
}
