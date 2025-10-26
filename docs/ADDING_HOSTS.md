# Adding Hosts to Your Configuration

This guide shows how to manage multiple machines with axiOS.

## Using axiOS as a Library (Recommended)

When using axios as a library, adding hosts is simple - just add more configurations to your flake.

### Single Host Structure

```
my-nixos-config/
├── flake.nix
├── user.nix
└── disks.nix
```

### Multi-Host Structure

```
my-nixos-config/
├── flake.nix
├── user.nix          # Shared user module
└── hosts/
    ├── desktop/
    │   ├── config.nix
    │   └── disks.nix
    └── laptop/
        ├── config.nix
        └── disks.nix
```

### Example Multi-Host Flake

**flake.nix:**
```nix
{
  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs = { self, axios, nixpkgs, ... }:
    let
      # Shared user module
      userModule = self.outPath + "/user.nix";
      
      # Desktop configuration
      desktopConfig = {
        hostname = "desktop";
        system = "x86_64-linux";
        formFactor = "desktop";
        
        hardware = {
          vendor = "msi";
          cpu = "amd";
          gpu = "amd";
          hasSSD = true;
          isLaptop = false;
        };
        
        modules = {
          system = true;
          desktop = true;
          development = true;
          gaming = true;
          graphics = true;
          networking = true;
          users = true;
          virt = true;
          services = true;
        };
        
        services = {
          caddy-proxy.enable = true;
        };
        
        homeProfile = "workstation";
        userModulePath = userModule;
        diskConfigPath = ./hosts/desktop/disks.nix;
        
        extraConfig = {
          time.timeZone = "America/New_York";
        };
      };
      
      # Laptop configuration
      laptopConfig = {
        hostname = "laptop";
        system = "x86_64-linux";
        formFactor = "laptop";
        
        hardware = {
          vendor = "system76";
          cpu = "amd";
          gpu = "amd";
          hasSSD = true;
          isLaptop = true;
        };
        
        modules = {
          system = true;
          desktop = true;
          development = true;
          gaming = false;  # No gaming on laptop
          graphics = true;
          networking = true;
          users = true;
          virt = false;
          services = false;
        };
        
        homeProfile = "laptop";
        userModulePath = userModule;
        diskConfigPath = ./hosts/laptop/disks.nix;
        
        extraConfig = {
          time.timeZone = "America/New_York";
          boot.lanzaboote.enableSecureBoot = true;
        };
      };
    in
    {
      nixosConfigurations = {
        desktop = axios.lib.mkSystem desktopConfig;
        laptop = axios.lib.mkSystem laptopConfig;
      };
    };
}
```

### Alternative: Import Host Configs

For cleaner organization, import host configs from separate files:

**flake.nix:**
```nix
{
  inputs = {
    axios.url = "github:kcalvelli/axios";
    nixpkgs.follows = "axios/nixpkgs";
  };

  outputs = { self, axios, nixpkgs, ... }:
    let
      userModule = self.outPath + "/user.nix";
      
      # Import host configs
      desktop = (import ./hosts/desktop/config.nix { 
        lib = nixpkgs.lib;
        userModule = userModule;
      }).hostConfig;
      
      laptop = (import ./hosts/laptop/config.nix {
        lib = nixpkgs.lib;
        userModule = userModule;
      }).hostConfig;
    in
    {
      nixosConfigurations = {
        desktop = axios.lib.mkSystem desktop;
        laptop = axios.lib.mkSystem laptop;
      };
    };
}
```

**hosts/desktop/config.nix:**
```nix
{ lib, userModule, ... }:
{
  hostConfig = {
    hostname = "desktop";
    system = "x86_64-linux";
    formFactor = "desktop";
    
    hardware = {
      vendor = "msi";
      cpu = "amd";
      gpu = "amd";
      hasSSD = true;
      isLaptop = false;
    };
    
    modules = {
      system = true;
      desktop = true;
      development = true;
      gaming = true;
      # ... etc
    };
    
    homeProfile = "workstation";
    userModulePath = userModule;
    diskConfigPath = ./disks.nix;
  };
}
```

### Deploying to Hosts

```bash
# Build desktop config
sudo nixos-rebuild switch --flake .#desktop

# Build laptop config
sudo nixos-rebuild switch --flake .#laptop

# Deploy from remote
nixos-rebuild switch --flake github:user/my-config#laptop --target-host laptop.local
```

## Sharing Configuration Between Hosts

### Shared User Module

Create one user module and reuse it:

**user.nix:**
```nix
{ self, config, ... }:
let
  username = "myuser";
in
{
  users.users.${username} = {
    isNormalUser = true;
    description = "My User";
    initialPassword = "changeme";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  home-manager.users.${username} = {
    home.stateVersion = "24.05";
    # ... shared home-manager config
  };
}
```

All hosts reference the same `userModulePath`.

### Shared Settings via extraConfig

Define common settings once:

```nix
let
  commonConfig = {
    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";
  };
  
  desktopConfig = {
    # ... hardware, modules, etc ...
    extraConfig = commonConfig;
  };
  
  laptopConfig = {
    # ... hardware, modules, etc ...
    extraConfig = commonConfig;
  };
in
{
  nixosConfigurations = {
    desktop = axios.lib.mkSystem desktopConfig;
    laptop = axios.lib.mkSystem laptopConfig;
  };
}
```

### Different Module Sets Per Host

Enable different features per machine:

```nix
# Gaming desktop
desktopConfig.modules = {
  system = true;
  desktop = true;
  gaming = true;  # ✓
  virt = true;    # ✓
  services = true; # ✓
};

# Development laptop
laptopConfig.modules = {
  system = true;
  desktop = true;
  gaming = false;  # ✗ No gaming
  virt = false;    # ✗ No VMs
  services = false; # ✗ No services
};
```

## Remote Deployment

### Deploy from Another Machine

```bash
# Deploy to remote host
nixos-rebuild switch --flake .#remotehostname \
  --target-host user@remote.host \
  --use-remote-sudo

# Deploy without remote sudo (if you have root access)
nixos-rebuild switch --flake .#remotehostname \
  --target-host root@remote.host
```

### Use SSH Config

**~/.ssh/config:**
```
Host mydesktop
    HostName desktop.local
    User myuser
    IdentityFile ~/.ssh/id_ed25519

Host mylaptop
    HostName laptop.local
    User myuser
    IdentityFile ~/.ssh/id_ed25519
```

Then deploy with:
```bash
nixos-rebuild switch --flake .#desktop --target-host mydesktop --use-remote-sudo
```

## Tips

### Host-Specific Overlays

```nix
extraConfig = {
  nixpkgs.overlays = [
    (final: prev: {
      # Override package for this host only
      my-package = prev.my-package.override {
        enableFeature = true;
      };
    })
  ];
}
```

### Conditional Configuration

```nix
extraConfig = {
  # Example: Only enable on desktop
  services.caddy.enable = lib.mkIf (config.networking.hostName == "desktop") true;
}
```

### Testing New Hosts

```bash
# Build without deploying
nix build .#nixosConfigurations.newhost.config.system.build.toplevel

# Test in VM (if configured)
nixos-rebuild build-vm --flake .#newhost
./result/bin/run-*-vm
```

## Examples

- [examples/minimal-flake](../examples/minimal-flake/) - Single host
- [examples/multi-host](../examples/multi-host/) - Multiple hosts (coming soon)
- [Real world example](https://github.com/kcalvelli/nixos_config) - Production multi-host setup

## More Information

- [Library Usage Guide](LIBRARY_USAGE.md) - Complete library API
- [Quick Reference](QUICK_REFERENCE.md) - Common commands
- [Installation Guide](INSTALLATION.md) - Getting started
