# axiOS Library Functions
# These functions can be used by downstream flakes to build NixOS configurations
{ inputs, self, lib }:
let
  # Helper to build nixos-hardware modules based on hardware configuration
  hardwareModules = hw:
    let
      hwMods = inputs.nixos-hardware.nixosModules;
    in
      lib.optional (hw.cpu or null == "amd") hwMods.common-cpu-amd
      ++ lib.optional (hw.cpu or null == "intel") hwMods.common-cpu-intel
      ++ lib.optional (hw.gpu or null == "amd") hwMods.common-gpu-amd
      ++ lib.optional (hw.gpu or null == "nvidia") hwMods.common-gpu-nvidia
      ++ lib.optional (hw.hasSSD or false) hwMods.common-pc-ssd
      ++ lib.optional (hw.isLaptop or false) hwMods.common-pc-laptop;

  # Helper to build module list for a host configuration
  buildModules = hostCfg:
    let
      baseModules = [
        inputs.disko.nixosModules.disko
        inputs.dankMaterialShell.nixosModules.greeter
        inputs.home-manager.nixosModules.home-manager
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.vscode-server.nixosModules.default
      ];
      
      hwModules = hardwareModules hostCfg.hardware;
      
      ourModules = with self.nixosModules;
        lib.optional (hostCfg.modules.system or true) system
        ++ lib.optional (hostCfg.modules.desktop or false) desktop
        ++ lib.optional (hostCfg.modules.development or false) development
        ++ lib.optional (hostCfg.modules.services or false) services
        ++ lib.optional (hostCfg.modules.graphics or false) graphics
        ++ lib.optional (hostCfg.modules.networking or true) networking
        ++ lib.optional (hostCfg.modules.users or true) users
        ++ lib.optional (hostCfg.modules.virt or false) virt
        ++ lib.optional (hostCfg.modules.gaming or false) gaming
        # Hardware modules based on form factor and vendor
        ++ lib.optional (hostCfg.hardware.vendor or null == "msi") desktopHardware
        ++ lib.optional (hostCfg.hardware.vendor or null == "system76") laptopHardware
        # Generic hardware based on form factor (if no specific vendor)
        ++ lib.optional (
          (hostCfg.hardware.vendor or null == null) &&
          (hostCfg.formFactor or "" == "desktop")
        ) desktopHardware
        ++ lib.optional (
          (hostCfg.hardware.vendor or null == null) &&
          (hostCfg.formFactor or "" == "laptop")
        ) laptopHardware;
      
      hostModule = { config, lib, ... }: 
        let
          hwVendor = hostCfg.hardware.vendor or null;
          profile = hostCfg.homeProfile or "workstation";
          extraCfg = hostCfg.extraConfig or {};
          
          # Build dynamic config based on what's defined in hostCfg
          dynamicConfig = lib.mkMerge [
            # Always include extraConfig first
            extraCfg
            # Add virt config only if module is enabled and config exists
            (lib.optionalAttrs ((hostCfg.modules.virt or false) && (hostCfg ? virt)) {
              virt = hostCfg.virt;
            })
            # Add services config only if module is enabled and config exists  
            (lib.optionalAttrs ((hostCfg.modules.services or false) && (hostCfg ? services)) {
              services = hostCfg.services;
            })
            # Enable desktop hardware module if vendor is msi
            (lib.optionalAttrs (hwVendor == "msi") {
              hardware.desktop = {
                enable = true;
                enableMsiSensors = true;
              };
            })
            # Enable laptop hardware module if vendor is system76
            (lib.optionalAttrs (hwVendor == "system76") {
              hardware.laptop = {
                enable = true;
                enableSystem76 = true;
                enablePangolinQuirks = true;
              };
            })
          ];
        in
        lib.mkMerge [
          {
            networking.hostName = hostCfg.hostname;
            
            home-manager.sharedModules = 
              if profile == "workstation" then [ self.homeModules.workstation ]
              else if profile == "laptop" then [ self.homeModules.laptop ]
              else [];
          }
          dynamicConfig
        ];
      
      diskModule = 
        if hostCfg ? diskConfigPath 
        then hostCfg.diskConfigPath
        else { 
          # Default: No disk configuration
          imports = [];
        };
      
      userModule =
        if hostCfg ? userModulePath
        then hostCfg.userModulePath
        else { imports = []; };
    in
      baseModules ++ hwModules ++ ourModules ++ [ hostModule diskModule userModule ];

  # Main function to create a NixOS system configuration
  # Usage: mkSystem { hostConfig attrs }
  mkSystem = hostCfg: inputs.nixpkgs.lib.nixosSystem {
    system = hostCfg.system or "x86_64-linux";
    specialArgs = {
      inherit inputs self;
      inherit (self) nixosModules homeModules;
    };
    modules = buildModules hostCfg;
  };
in
{
  inherit hardwareModules buildModules mkSystem;
}
