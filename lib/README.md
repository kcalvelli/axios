# axiOS Library Functions

This directory contains library functions that can be used by downstream flakes to build NixOS configurations using axiOS as a base.

## Exported Functions

### `mkSystem`

The main function to create a NixOS system configuration.

**Usage:**
```nix
{
  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
  };
  
  outputs = { self, axios, ... }: {
    nixosConfigurations.myhost = axios.lib.mkSystem {
      hostname = "myhost";
      system = "x86_64-linux";
      formFactor = "desktop"; # or "laptop"
      
      hardware = {
        vendor = "msi"; # or "system76", or null for generic
        cpu = "amd"; # or "intel"
        gpu = "amd"; # or "nvidia"
        hasSSD = true;
        isLaptop = false;
      };
      
      modules = {
        system = true;
        desktop = true;
        development = true;
        services = false;
        graphics = true;
        networking = true;
        users = true;
        virt = false;
        gaming = true;
      };
      
      homeProfile = "workstation"; # or "laptop"
      
      diskConfigPath = ./disks.nix;
      
      # Optional: Additional configuration
      extraConfig = {
        # Any additional NixOS configuration options
      };
    };
  };
}
```

### `hardwareModules`

Helper function that builds a list of nixos-hardware modules based on hardware configuration.

**Parameters:**
- `hw`: Hardware configuration attribute set with optional fields:
  - `cpu`: "amd" or "intel"
  - `gpu`: "amd" or "nvidia"
  - `hasSSD`: boolean
  - `isLaptop`: boolean

**Returns:** List of nixos-hardware modules

### `buildModules`

Helper function that builds the complete module list for a host configuration. Combines base modules, hardware modules, axiOS modules, and host-specific configuration.

**Parameters:**
- `hostCfg`: Host configuration attribute set (same as `mkSystem` parameter)

**Returns:** List of NixOS modules

## Host Configuration Reference

### Required Fields
- `hostname`: String - The system hostname
- `system`: String - System architecture (typically "x86_64-linux")

### Hardware Configuration
- `formFactor`: "desktop" | "laptop"
- `hardware`: Attribute set
  - `vendor`: "msi" | "system76" | null
  - `cpu`: "amd" | "intel"
  - `gpu`: "amd" | "nvidia"
  - `hasSSD`: boolean
  - `isLaptop`: boolean

### Module Selection
- `modules`: Attribute set of boolean flags
  - `system`: Core system configuration
  - `desktop`: Desktop environment (Niri)
  - `development`: Development tools
  - `services`: System services
  - `graphics`: Graphics drivers and tools
  - `networking`: Network configuration
  - `users`: User management
  - `virt`: Virtualization (libvirt, containers)
  - `gaming`: Gaming configuration (Steam, etc.)

### Optional Fields
- `homeProfile`: "workstation" | "laptop" - Home-manager profile
- `diskConfigPath`: Path to disko configuration
- `extraConfig`: Additional NixOS configuration attribute set
- `virt`: Virtualization configuration (if modules.virt is true)
- `services`: Services configuration (if modules.services is true)

## Examples

See `hosts/TEMPLATE.nix` and `hosts/EXAMPLE-*.nix` for complete examples of host configurations.
