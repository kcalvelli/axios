{
  description = "Multi-host Cairn configuration example";

  inputs = {
    # Import Cairn as the base framework
    cairn.url = "github:kcalvelli/cairn";

    # Follow cairn's nixpkgs for compatibility
    nixpkgs.follows = "cairn/nixpkgs";
  };

  outputs =
    {
      self,
      cairn,
      nixpkgs,
      ...
    }:
    let
      # Helper to build a host configuration
      # Each host declares its users by name; Cairn resolves users/<name>.nix automatically
      mkHost =
        hostname:
        cairn.lib.mkSystem (
          (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig
          // {
            configDir = self.outPath;
          }
        );
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        laptop = mkHost "laptop";
        server = mkHost "server";
      };
    };
}
