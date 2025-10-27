{
  description = "Multi-host axiOS configuration example";

  inputs = {
    # Import axiOS as the base framework
    axios.url = "github:kcalvelli/axios";
    
    # Follow axios's nixpkgs for compatibility
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs = { self, axios, nixpkgs, ... }:
    let
      # Shared configuration across all hosts
      sharedConfig = {
        modules = {
          system = true;
          desktop = true;
          development = true;
          graphics = true;
          networking = true;
          users = true;
          services = false;
          virt = false;
          gaming = false;
        };
      };

      # Desktop workstation configuration
      desktopConfig = sharedConfig // {
        hostname = "desktop";
        system = "x86_64-linux";
        formFactor = "desktop";
        
        hardware = {
          cpu = "amd";
          gpu = "amd";
          hasSSD = true;
          isLaptop = false;
        };
        
        homeProfile = "workstation";
        userModulePath = ./users/desktop-user.nix;
        diskConfigPath = ./hosts/desktop/disks.nix;
        
        extraConfig = {
          # Desktop-specific configuration
          # time.timeZone = "America/New_York";
        };
      };

      # Laptop configuration
      laptopConfig = sharedConfig // {
        hostname = "laptop";
        system = "x86_64-linux";
        formFactor = "laptop";
        
        hardware = {
          cpu = "intel";
          gpu = "intel";
          hasSSD = true;
          isLaptop = true;
        };
        
        homeProfile = "laptop";
        userModulePath = ./users/laptop-user.nix;
        diskConfigPath = ./hosts/laptop/disks.nix;
        
        extraConfig = {
          # Laptop-specific configuration
          # services.thermald.enable = true;
        };
      };

      # Work server configuration
      serverConfig = {
        hostname = "server";
        system = "x86_64-linux";
        formFactor = "desktop";
        
        hardware = {
          cpu = "intel";
          gpu = "intel";
          hasSSD = true;
          isLaptop = false;
        };
        
        modules = {
          system = true;
          desktop = false;      # No desktop on server
          development = true;
          graphics = false;     # No graphics drivers
          networking = true;
          users = true;
          services = true;      # Enable services
          virt = true;          # Enable virtualization
          gaming = false;
        };
        
        homeProfile = "workstation";
        userModulePath = ./users/server-user.nix;
        diskConfigPath = ./hosts/server/disks.nix;
        
        extraConfig = {
          # Server-specific configuration
          # services.openssh.enable = true;
        };
      };
    in
    {
      # Build all host configurations
      nixosConfigurations = {
        desktop = axios.lib.mkSystem desktopConfig;
        laptop = axios.lib.mkSystem laptopConfig;
        server = axios.lib.mkSystem serverConfig;
      };
    };
}
