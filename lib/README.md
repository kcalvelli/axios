# axiOS Library Functions

This directory contains library functions that can be used by downstream flakes to build NixOS configurations using axiOS as a base.

**For complete documentation, see [docs/LIBRARY_USAGE.md](../docs/LIBRARY_USAGE.md)**

## Quick Reference

### `mkSystem`

Build a NixOS configuration from a host specification:

```nix
axios.lib.mkSystem {
  hostname = "myhost";
  system = "x86_64-linux";
  formFactor = "desktop" | "laptop";
  hardware = { cpu = "amd" | "intel"; gpu = "amd" | "nvidia"; hasSSD = bool; isLaptop = bool; };
  modules = { system = bool; desktop = bool; development = bool; /* ... */ };
  homeProfile = "workstation" | "laptop";
  users = [ "alice" "bob" ];         # References users/<name>.nix via configDir
  configDir = path;                  # Root of config repo (required when users is non-empty)
  hardwareConfigPath = path;         # Full hardware config from nixos-generate-config
  extraConfig = { /* NixOS options */ };
}
```

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

  outputs = { self, axios, nixpkgs, ... }:
    let
      mkHost = hostname: axios.lib.mkSystem (
        (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
          configDir = self.outPath;
        }
      );
    in
    {
      nixosConfigurations.myhost = mkHost "myhost";
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

### Optional Fields (with defaults)
- `system`: String - System architecture (default: "x86_64-linux")
- `formFactor`: "desktop" | "laptop"
- `hardware`: Attribute set
  - `vendor`: "msi" | "system76" | null (optional, default: null)
  - `cpu`: "amd" | "intel"
  - `gpu`: "amd" | "nvidia" | "intel"
  - `hasSSD`: boolean
  - `isLaptop`: boolean
- `homeProfile`: "workstation" | "laptop" - Home-manager profile

### Module Selection
- `modules`: Attribute set of boolean flags
  - `system`: Core system configuration (default: true)
  - `desktop`: Desktop environment - Niri (default: false)
  - `development`: Development tools (default: false)
  - `graphics`: Graphics drivers and tools (default: false)
  - `networking`: Network configuration (default: true)
  - `users`: User management (default: true)
  - `virt`: Virtualization - libvirt, containers (default: false)
  - `gaming`: Gaming - Steam, GameMode (default: false)
  - `ai`: AI tools - Claude Code, Gemini, MCP servers (default: true)
  - `pim`: Personal info management - email, calendar (default: false)
  - `secrets`: Encrypted secrets via agenix (default: false)
  - `syncthing`: Peer-to-peer XDG directory sync (default: false)
  - `services`: Self-hosted services - Immich (default: false)

### Multi-User Support
- `users`: List of strings - User names (resolves `users/<name>.nix` via configDir)
- `configDir`: Path - Root of config repo (required when `users` is non-empty)

### Other Optional Fields
- `hardwareConfigPath`: Path to hardware configuration (from nixos-generate-config)
- `extraConfig`: Additional NixOS configuration attribute set
- `inputs`: Override or supplement framework flake inputs
- `virt`: Virtualization configuration (if modules.virt is true)
- `secrets`: Secrets configuration (if modules.secrets is true)

## Examples

See [examples/example-config/](../examples/example-config/) for complete examples of host configurations.
