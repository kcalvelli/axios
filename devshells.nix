# devshell.nix
{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      devShells = {
        rust = import ./devshells/rust.nix { inherit pkgs inputs; };
        zig = import ./devshells/zig.nix { inherit pkgs inputs; };
        qml = import ./devshells/qml.nix { inherit pkgs inputs; };
        dotnet = import ./devshells/dotnet.nix { inherit pkgs inputs; };

        # Pick whichever one you want as default
        default = lib.mkDefault (import ./devshells/rust.nix { inherit pkgs inputs; });
      };
    };
}
