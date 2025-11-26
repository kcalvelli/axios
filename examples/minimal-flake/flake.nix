{
  description = "Minimal axiOS configuration example";

  inputs = {
    # Import axiOS as the base framework
    axios.url = "github:kcalvelli/axios";

    # Follow axios's nixpkgs for compatibility
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs =
    { self, axios, ... }:
    let
      # Define your host configuration
      myHostConfig = {
        # Basic identification
        hostname = "mycomputer";
        system = "x86_64-linux";
        formFactor = "desktop"; # or "laptop"

        # Hardware configuration
        hardware = {
          cpu = "amd"; # "amd" or "intel"
          gpu = "amd"; # "amd" or "nvidia"
          hasSSD = true;
          isLaptop = false;
          # vendor = "msi";      # Optional: for MSI motherboards
          # vendor = "system76"; # Optional: for System76 laptops
        };

        # NixOS modules to enable
        modules = {
          system = true; # Core system configuration
          desktop = true; # Niri desktop environment
          development = true; # Development tools
          services = false; # System services (optional)
          graphics = true; # Graphics drivers
          networking = true; # Network configuration
          users = true; # User management
          virt = false; # Virtualization (optional)
          gaming = false; # Gaming support (optional)
        };

        # Home-manager profile
        homeProfile = "workstation"; # or "laptop"

        # Path to your user module
        userModulePath = self.outPath + "/user.nix";

        # Path to disk configuration
        diskConfigPath = ./disks.nix;

        # Optional: Extra NixOS configuration
        extraConfig = {
          # Add any additional NixOS options here
          # Required: Set system timezone
          axios.system.timeZone = "America/New_York";

          # For example:
          # time.hardwareClockInLocalTime = true;
        };
      };
    in
    {
      # Build the NixOS configuration using axios.lib.mkSystem
      nixosConfigurations.mycomputer = axios.lib.mkSystem myHostConfig;
    };
}
