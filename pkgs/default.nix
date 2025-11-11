{ self, inputs, ... }:
let
  # Automatically discover all package directories in pkgs/
  # To add a new package:
  #   1. Create a new directory in pkgs/ (e.g., pkgs/my-package/)
  #   2. Add a default.nix file in that directory
  #   3. The package will be automatically added to flake outputs
  # Each directory with a default.nix will be added as a package
  lib = inputs.nixpkgs.lib;

  # Get all directories in pkgs/ that contain a default.nix
  pkgsDir = ./.;
  packageDirs = builtins.filter
    (name: name != "default.nix" &&
      builtins.pathExists (pkgsDir + "/${name}/default.nix"))
    (builtins.attrNames (builtins.readDir pkgsDir));

  # Convert directory names with dashes to valid attribute names
  # (they're already valid in Nix, but this makes it explicit)
  packageNames = packageDirs;
in
{
  perSystem =
    { system, pkgs, ... }:
    {
      # Automatically export all custom packages
      packages = lib.genAttrs packageNames (name: pkgs.${name});

      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [
          self.overlays.default
          inputs.mcp-servers-nix.overlays.default
        ];
      };
    };

  # Automatically generate overlay from all package directories
  flake.overlays.default = _final: prev:
    lib.genAttrs packageNames (name: prev.callPackage (pkgsDir + "/${name}") { });
}
