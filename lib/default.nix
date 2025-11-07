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
      # Validation module - checks configuration consistency
      validationModule = {
        config.assertions =
          let
            hw = hostCfg.hardware or { };
            cpu = hw.cpu or null;
            gpu = hw.gpu or null;
            vendor = hw.vendor or null;
            isLaptop = hw.isLaptop or false;
            formFactor = hostCfg.formFactor or null;
            modules = hostCfg.modules or { };
            homeProfile = hostCfg.homeProfile or null;
          in
          [
            # Required fields
            {
              assertion = hostCfg ? hostname;
              message = ''
                axiOS configuration error: 'hostname' is required but not specified.

                Add to your configuration:
                  hostname = "myhostname";
              '';
            }

            # Valid CPU type
            {
              assertion = cpu == null || lib.elem cpu [ "amd" "intel" ];
              message = ''
                axiOS configuration error: Invalid hardware.cpu value: "${lib.generators.toPretty {} cpu}"

                Valid options: "amd", "intel", or null
                Note: Values are case-sensitive (use lowercase).
              '';
            }

            # Valid GPU type
            {
              assertion = gpu == null || lib.elem gpu [ "amd" "nvidia" "intel" ];
              message = ''
                axiOS configuration error: Invalid hardware.gpu value: "${lib.generators.toPretty {} gpu}"

                Valid options: "amd", "nvidia", "intel", or null
              '';
            }

            # Valid vendor
            {
              assertion = vendor == null || lib.elem vendor [ "msi" "system76" ];
              message = ''
                axiOS configuration error: Invalid hardware.vendor value: "${lib.generators.toPretty {} vendor}"

                Valid options: "msi", "system76", or null (for generic hardware)

                Note: Most users should use null unless you have specific MSI or System76 hardware.
              '';
            }

            # Valid form factor
            {
              assertion = formFactor == null || lib.elem formFactor [ "desktop" "laptop" ];
              message = ''
                axiOS configuration error: Invalid formFactor value: "${lib.generators.toPretty {} formFactor}"

                Valid options: "desktop", "laptop"
              '';
            }

            # Valid home profile
            {
              assertion = homeProfile == null || lib.elem homeProfile [ "workstation" "laptop" ];
              message = ''
                axiOS configuration error: Invalid homeProfile value: "${lib.generators.toPretty {} homeProfile}"

                Valid options: "workstation", "laptop"
              '';
            }

            # Consistency: isLaptop vs formFactor
            {
              assertion = !isLaptop || formFactor == "laptop";
              message = ''
                axiOS configuration error: Inconsistent laptop configuration.

                You have:
                  hardware.isLaptop = true
                  formFactor = "${formFactor}"

                These must match. Fix by setting:
                  formFactor = "laptop";
                  hardware.isLaptop = true;
              '';
            }

            # Consistency: desktop formFactor shouldn't have isLaptop
            {
              assertion = formFactor != "desktop" || !isLaptop;
              message = ''
                axiOS configuration error: Inconsistent desktop configuration.

                You have:
                  formFactor = "desktop"
                  hardware.isLaptop = true

                Desktop systems should not have isLaptop = true. Fix by setting:
                  hardware.isLaptop = false;
              '';
            }

            # Vendor constraint: axiOS only supports System76 laptops
            {
              assertion = vendor != "system76" || formFactor == "laptop";
              message = ''
                axiOS configuration error: System76 vendor requires laptop form factor.

                You have:
                  hardware.vendor = "system76"
                  formFactor = "${formFactor}"

                axiOS currently only supports System76 laptop configurations.
                While System76 does make desktops (Thelio), axiOS doesn't have
                hardware modules for them yet.

                Fix by setting:
                  formFactor = "laptop";

                Or use vendor = null for generic desktop configuration.
              '';
            }

            # Vendor constraint: MSI in this context means desktop
            {
              assertion = vendor != "msi" || formFactor == "desktop";
              message = ''
                axiOS configuration error: MSI vendor requires desktop form factor.

                You have:
                  hardware.vendor = "msi"
                  formFactor = "${formFactor}"

                The MSI vendor option is for desktop motherboards. Fix by setting:
                  formFactor = "desktop";

                Note: If you have an MSI laptop, use vendor = null instead.
              '';
            }

            # Module dependency: AI module should have networking enabled
            {
              assertion = !(modules.ai or false) || (modules.networking or true);
              message = ''
                axiOS configuration error: AI module requires networking module.

                You have:
                  modules.ai = true
                  modules.networking = false

                AI services (Ollama, OpenWebUI) require networking. Fix by setting:
                  modules.networking = true;
              '';
            }

            # Helpful warning: AI without services module limits functionality
            # This is a warning, not an error, so we make the assertion always pass
            # and put the warning in the modules that need it

            # Consistency: gaming usually wants graphics
            {
              assertion = !(modules.gaming or false) || (modules.graphics or false);
              message = ''
                axiOS configuration error: Gaming module requires graphics module.

                You have:
                  modules.gaming = true
                  modules.graphics = false

                Gaming support requires graphics drivers. Fix by setting:
                  modules.graphics = true;
              '';
            }

            # Consistency: desktop module wants networking for services
            {
              assertion = !(modules.desktop or false) || (modules.networking or true);
              message = ''
                axiOS configuration error: Desktop module requires networking module.

                You have:
                  modules.desktop = true
                  modules.networking = false

                Desktop environment needs networking for various services. Fix by setting:
                  modules.networking = true;
              '';
            }
          ];
      };

      baseModules = [
        validationModule # Validate configuration first
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
        ++ lib.optional (hostCfg.modules.graphics or false) graphics
        ++ lib.optional (hostCfg.modules.networking or true) networking
        ++ lib.optional (hostCfg.modules.users or true) users
        ++ lib.optional (hostCfg.modules.virt or false) virt
        ++ lib.optional (hostCfg.modules.gaming or false) gaming
        ++ lib.optional (hostCfg.modules.ai or false) ai
        ++ lib.optional (hostCfg.modules.secrets or false) secrets
        # Hardware modules based on form factor and vendor
        ++ lib.optional (hostCfg.hardware.vendor or null == "msi") desktopHardware
        ++ lib.optional (hostCfg.hardware.vendor or null == "system76") laptopHardware
        # Generic hardware based on form factor (if no specific vendor)
        ++ lib.optional
          (
            (hostCfg.hardware.vendor or null == null) &&
            (hostCfg.formFactor or "" == "desktop")
          )
          desktopHardware
        ++ lib.optional
          (
            (hostCfg.hardware.vendor or null == null) &&
            (hostCfg.formFactor or "" == "laptop")
          )
          laptopHardware;

      hostModule = { config, lib, ... }:
        let
          hwVendor = hostCfg.hardware.vendor or null;
          profile = hostCfg.homeProfile or "workstation";
          extraCfg = hostCfg.extraConfig or { };

          # Build dynamic config based on what's defined in hostCfg
          dynamicConfig = lib.mkMerge [
            # Always include extraConfig first
            extraCfg
            # Add virt config only if module is enabled and config exists
            (lib.optionalAttrs ((hostCfg.modules.virt or false) && (hostCfg ? virt)) {
              virt = hostCfg.virt;
            })
            # Enable AI module if specified
            (lib.optionalAttrs (hostCfg.modules.ai or false) {
              services.ai.enable = true;
            })
            # Enable desktop module if specified
            (lib.optionalAttrs (hostCfg.modules.desktop or false) {
              desktop.enable = true;
            })
            # Enable development module if specified
            (lib.optionalAttrs (hostCfg.modules.development or false) {
              development.enable = true;
            })
            # Enable gaming module if specified
            (lib.optionalAttrs (hostCfg.modules.gaming or false) {
              gaming.enable = true;
            })
            # Enable secrets module if specified
            (lib.optionalAttrs (hostCfg.modules.secrets or false) {
              secrets.enable = true;
            })
            # Add secrets config only if module is enabled and config exists
            (lib.optionalAttrs ((hostCfg.modules.secrets or false) && (hostCfg ? secrets)) {
              secrets = hostCfg.secrets;
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
              (if profile == "workstation" then [ self.homeModules.workstation ]
              else if profile == "laptop" then [ self.homeModules.laptop ]
              else [ ])
              ++ lib.optional (hostCfg.modules.secrets or false) self.homeModules.secrets;
          }
          dynamicConfig
        ];

      diskModule =
        if hostCfg ? diskConfigPath
        then hostCfg.diskConfigPath
        else {
          # Default: No disk configuration
          imports = [ ];
        };

      userModule =
        if hostCfg ? userModulePath
        then hostCfg.userModulePath
        else { imports = [ ]; };
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
