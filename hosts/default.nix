# Simple version that uses host config files but explicit mapping
{ inputs, self, lib, ... }:
let
  # Import library functions
  axiosLib = import ../lib { inherit inputs self lib; };
  inherit (axiosLib) mkSystem;
  
  # Load host configurations
  # Add your host configurations here:
  # myHostCfg = (import ./myhost.nix { inherit lib; }).hostConfig;
  
  # Minimal installer configuration
  installerModules = [
    inputs.disko.nixosModules.disko
    ./installer
  ];
in
{
  flake.nixosConfigurations = {
    # Add your host configurations here:
    # Example:
    # myhost = mkSystem myHostCfg;
    
    # Installer ISO
    installer = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs self;
        inherit (self) nixosModules homeModules;
      };
      modules = installerModules;
    };
    
    # To add a new host:
    # 1. Create hosts/newhostname.nix with hostConfig (use TEMPLATE.nix or EXAMPLE-*.nix)
    # 2. Import it above: myHostCfg = (import ./myhost.nix { inherit lib; }).hostConfig;
    # 3. Add here: myhost = mkSystem myHostCfg;
  };
}
