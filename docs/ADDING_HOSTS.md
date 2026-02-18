# Adding Hosts to Your Configuration

This guide shows how to manage multiple machines with axiOS.

## Using axiOS as a Library (Recommended)

When using axios as a library, adding hosts is simple - just add more configurations to your flake.

### Canonical Directory Structure

```
~/.config/nixos_config/
├── flake.nix
├── hosts/
│   ├── desktop.nix
│   ├── desktop/
│   │   └── hardware.nix
│   ├── laptop.nix
│   └── laptop/
│       └── hardware.nix
└── users/
    ├── alice.nix
    └── bob.nix
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
      mkHost = hostname: axios.lib.mkSystem (
        (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
          configDir = self.outPath;
        }
      );
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        laptop = mkHost "laptop";
      };
    };
}
```

**hosts/desktop.nix:**
```nix
{ lib, ... }:
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
      graphics = true;
      networking = true;
      users = true;
      virt = true;
    };

    homeProfile = "workstation";
    hardwareConfigPath = ./desktop/hardware.nix;
    users = [ "alice" ];

    extraConfig = {
      axios.system.timeZone = "America/New_York";
    };
  };
}
```

**hosts/laptop.nix:**
```nix
{ lib, ... }:
{
  hostConfig = {
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
      gaming = false;
      graphics = true;
      networking = true;
      users = true;
      virt = false;
    };

    homeProfile = "laptop";
    hardwareConfigPath = ./laptop/hardware.nix;
    users = [ "alice" ];

    extraConfig = {
      axios.system.timeZone = "America/New_York";
    };
  };
}
```

**users/alice.nix:**
```nix
{ ... }:
{
  axios.users.users.alice = {
    fullName = "Alice Smith";
    email = "alice@example.com";
    isAdmin = true;
  };
}
```

## Hardware Vendor Configuration

### When to Use the Vendor Flag

The `hardware.vendor` field is **optional** and should only be used if you have specific hardware that benefits from vendor-specific optimizations.

**Most users should omit this field** - the generic hardware support works well with all brands (ASUS, Gigabyte, Dell, Lenovo, HP, etc.).

### Supported Vendors

#### MSI (Desktop Motherboards)

Use `vendor = "msi"` if you have an MSI desktop motherboard **AND** want hardware monitoring support:

```nix
hardware = {
  vendor = "msi";  # Enables MSI sensor support
  cpu = "amd";
  gpu = "amd";
  hasSSD = true;
  isLaptop = false;
};
```

**What this enables:**
- `nct6775` kernel module for Super I/O chip sensors (fan speeds, temperatures)
- `acpi_enforce_resources=lax` kernel parameter for sensor access
- Hardware monitoring in tools like `lm_sensors`, `htop`, etc.

**When NOT to use:**
- You have MSI hardware but don't need sensor monitoring
- You have a non-MSI motherboard

#### System76 (Laptops)

Use `vendor = "system76"` if you own a System76 laptop:

```nix
hardware = {
  vendor = "system76";  # Enables System76 laptop features
  cpu = "amd";
  gpu = "amd";
  hasSSD = true;
  isLaptop = true;
};
```

**What this enables:**
- System76 firmware daemon for BIOS/EC firmware updates
- System76 power daemon for advanced power management
- `system76_acpi` kernel module for keyboard backlight control
- Pangolin 12 specific quirks (touchpad, Wi-Fi fixes)

**When NOT to use:**
- You have a laptop from another manufacturer (Dell, Lenovo, HP, etc.)

### Generic Hardware (Recommended)

For all other hardware, simply omit the `vendor` field or set it to `null`:

```nix
hardware = {
  # No vendor field - uses generic optimizations
  cpu = "amd";
  gpu = "amd";
  hasSSD = true;
  isLaptop = false;
};
```

This works perfectly for:
- ASUS, Gigabyte, ASRock motherboards
- Dell, Lenovo, HP, Acer laptops
- Any other brand not explicitly listed above

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

### Shared Users

All hosts reference the same `users/<name>.nix` files. Multiple hosts can share the same users:

```nix
# hosts/desktop.nix
users = [ "alice" "bob" ];

# hosts/laptop.nix
users = [ "alice" ];  # Only Alice uses the laptop
```

### Shared Settings via extraConfig

Define common settings once:

```nix
let
  commonConfig = {
    axios.system.timeZone = "America/New_York";
  };
in
{
  # Use in each host's extraConfig
}
```

### Different Module Sets Per Host

Enable different features per machine:

```nix
# Gaming desktop
modules = {
  system = true;
  desktop = true;
  gaming = true;
  virt = true;
  services = true;
};

# Development laptop
modules = {
  system = true;
  desktop = true;
  gaming = false;
  virt = false;
  services = false;
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

### Testing New Hosts

```bash
# Build without deploying
nix build .#nixosConfigurations.newhost.config.system.build.toplevel

# Test in VM (if configured)
nixos-rebuild build-vm --flake .#newhost
./result/bin/run-*-vm
```

## Examples

- [Example Configuration](../examples/example-config/) - Multi-host setup with multiple users

## More Information

- [Library Usage Guide](LIBRARY_USAGE.md) - Complete library API
- [User Module Guide](USER_MODULE.md) - User configuration
- [Installation Guide](INSTALLATION.md) - Getting started
