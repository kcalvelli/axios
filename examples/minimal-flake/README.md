# Minimal axiOS Configuration Example

This is a minimal example of using axiOS as a library to build your own NixOS configuration.

## Structure

```
minimal-flake/
├── flake.nix       # Main flake with host configuration
├── user.nix        # User account definition
├── disks.nix       # Disk/filesystem configuration
└── README.md       # This file
```

**That's it!** Just 3 configuration files to manage.

## What You Get

All of these come from axiOS automatically:
- ✅ Niri desktop environment with Material Shell
- ✅ Development tools (editors, compilers, LSP servers)
- ✅ Modern terminal (Ghostty with custom theming)
- ✅ Graphics drivers (AMD/Intel/Nvidia)
- ✅ Home Manager configuration
- ✅ Security hardening and system optimization
- ✅ Hardware-specific optimizations

## How to Use

### 1. Copy this example

```bash
mkdir ~/my-nixos-config
cp -r examples/minimal-flake/* ~/my-nixos-config/
cd ~/my-nixos-config
```

### 2. Customize for your system

Edit `flake.nix`:
- Change `hostname` to your computer name
- Set `cpu` and `gpu` to match your hardware
- Set `formFactor` to "laptop" or "desktop"
- Enable/disable modules as needed

Edit `user.nix`:
- Change `username`, `fullName`, and `email`
- Modify groups as needed

Edit `disks.nix`:
- Replace UUIDs with your actual disk UUIDs (find with `lsblk -f` or `blkid`)
- Or run `nixos-generate-config` and extract the filesystem configuration

### 3. Build and install

```bash
# Build the configuration
nix build .#nixosConfigurations.mycomputer.config.system.build.toplevel

# Install NixOS (from installer)
sudo nixos-install --flake .#mycomputer

# Or switch on existing system
sudo nixos-rebuild switch --flake .#mycomputer
```

### 4. Initialize git

```bash
git init
git add .
git commit -m "Initial configuration"
```

Optional: Push to your own GitHub/GitLab repository.

## Updating axiOS

To get new features from axiOS:

```bash
nix flake update
sudo nixos-rebuild switch --flake .#mycomputer
```

You control when to update. Pin to specific axios versions for stability:

```nix
axios.url = "github:kcalvelli/axios/v1.0.0";  # Pin to tag
# or
axios.url = "github:kcalvelli/axios/<commit-sha>";  # Pin to commit
```

## Adding More Hosts

See [ADDING_HOSTS.md](../../docs/ADDING_HOSTS.md) for managing multiple machines.

## Need More?

- [axiOS Documentation](../../docs/)
- [Library API Reference](../../lib/README.md)
- [Real-world Example](https://github.com/kcalvelli/nixos_config)

## Customization

Want to customize beyond the defaults? You can:

1. Add options to `extraConfig` in your host config
2. Override specific packages or settings
3. Add your own modules alongside axiOS modules
4. Fork axios if you need deep customizations

The library approach gives you maximum flexibility with minimal maintenance.
