# axiOS Example Configuration

This is the canonical axiOS downstream configuration structure. It demonstrates single-host, multi-host, and shared-user scenarios.

## Structure

```
example-config/
├── flake.nix                       # Main flake with mkHost helper
├── hosts/
│   ├── desktop.nix                 # Desktop workstation config
│   ├── desktop/
│   │   └── hardware.nix            # Desktop hardware
│   ├── laptop.nix                  # Laptop config
│   ├── laptop/
│   │   └── hardware.nix            # Laptop hardware
│   ├── server.nix                  # Server config (headless)
│   └── server/
│       └── hardware.nix            # Server hardware
├── users/
│   ├── alice.nix                   # Alice's user definition
│   └── admin.nix                   # Server admin definition
└── README.md                       # This file
```

## Hosts Included

### Desktop Workstation
- **Hostname**: `desktop`
- **Hardware**: AMD CPU/GPU, NVMe SSD
- **Profile**: Full workstation with Niri desktop
- **Users**: alice

### Laptop
- **Hostname**: `laptop`
- **Hardware**: Intel CPU/GPU, NVMe SSD
- **Profile**: Laptop with power management
- **Users**: alice (same user, shared definition)

### Server
- **Hostname**: `server`
- **Hardware**: Intel CPU, SATA disk
- **Profile**: Headless with virtualization
- **Users**: admin
- **Note**: No desktop environment or graphics drivers

## Key Concepts

### Convention-Over-Configuration

axiOS prescribes a canonical directory structure. Hosts live in `hosts/`, users in `users/`, and the flake uses a `mkHost` helper:

```nix
mkHost = hostname: axios.lib.mkSystem (
  (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
    configDir = self.outPath;
  }
);
```

### Host-User Association

Each host declares which users belong to it via a `users` list. axiOS automatically resolves `users/<name>.nix` for each name:

```nix
# hosts/desktop.nix
users = [ "alice" ];

# hosts/server.nix
users = [ "admin" ];
```

### Shared Users Across Hosts

The same user definition (`users/alice.nix`) is shared between desktop and laptop. No duplication needed.

### Per-Host Configuration

Each host has its own file with hardware settings, module toggles, and extra config:

```nix
# hosts/server.nix
modules = {
  desktop = false;   # No desktop
  graphics = false;  # No GPU drivers
  virt = true;       # Enable virtualization
};
```

## Usage

### Building a Specific Host

```bash
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
nix build .#nixosConfigurations.laptop.config.system.build.toplevel
nix build .#nixosConfigurations.server.config.system.build.toplevel
```

### Installing to a Machine

```bash
sudo nixos-install --flake .#desktop
sudo nixos-install --flake .#laptop
sudo nixos-install --flake .#server
```

### Switching Configuration

```bash
# On the desktop
sudo nixos-rebuild switch --flake .#desktop

# On the laptop
sudo nixos-rebuild switch --flake .#laptop

# On the server
sudo nixos-rebuild switch --flake .#server
```

### Remote Deployment

```bash
nixos-rebuild switch --flake .#server --target-host admin@server --use-remote-sudo
```

## Adding More Hosts

1. Create `hosts/<hostname>.nix` with a `hostConfig` attribute set
2. Create `hosts/<hostname>/hardware.nix` from `nixos-generate-config`
3. Add to `flake.nix`:

```nix
nixosConfigurations = {
  desktop = mkHost "desktop";
  laptop  = mkHost "laptop";
  server  = mkHost "server";
  newhost = mkHost "newhost";   # Add this
};
```

## Adding More Users

1. Create `users/<username>.nix`:

```nix
{ ... }:
{
  axios.users.users.newuser = {
    fullName = "New User";
    email = "new@example.com";
    isAdmin = false;
  };
}
```

2. Add the username to the host's `users` list in `hosts/<hostname>.nix`.
