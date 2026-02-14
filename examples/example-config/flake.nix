{
  description = "Multi-host axiOS configuration example";

  inputs = {
    # Import axiOS as the base framework
    axios.url = "github:kcalvelli/axios";

    # Follow axios's nixpkgs for compatibility
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs =
    {
      self,
      axios,
      nixpkgs,
      ...
    }:
    let
      # Helper to build a host configuration
      # Each host declares its users by name; axiOS resolves users/<name>.nix automatically
      mkHost =
        hostname:
        axios.lib.mkSystem (
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
