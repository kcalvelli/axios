# Claude Desktop for NixOS

Unofficial Claude Desktop package for NixOS, wrapping the [claude-desktop-debian](https://github.com/aaddrick/claude-desktop-debian) project.

## Overview

This package provides Claude Desktop (version 1.0.2768) for NixOS by:
1. Fetching the prebuilt Debian package from claude-desktop-debian
2. Extracting and patching it for NixOS
3. Wrapping it in an FHS environment for MCP server compatibility

## Package Variants

The package exports two variants:

### Default (FHS Wrapper) - Recommended
```nix
pkgs.claude-desktop
```

Best for MCP server support. Provides a complete FHS environment with:
- Node.js, Python, Git
- Common utilities (curl, wget, jq)
- Build tools (gcc, make) for native extensions

Use this if you plan to use MCP servers.

### Unwrapped
```nix
pkgs.claude-desktop.unwrapped
```

Direct execution without FHS wrapper. Lighter weight but may have issues with:
- MCP servers requiring Node.js/Python
- Native module compilation
- System integration

## Usage

### Try It Out
```bash
# With MCP support (FHS wrapper)
NIXPKGS_ALLOW_UNFREE=1 nix run github:yourusername/axios#claude-desktop

# Without FHS wrapper
NIXPKGS_ALLOW_UNFREE=1 nix run github:yourusername/axios#claude-desktop.unwrapped
```

### Install in Configuration
```nix
{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    pkgs.claude-desktop  # or pkgs.claude-desktop.unwrapped
  ];
}
```

### Integration with axios AI Module

The easiest way to use this is through axios's AI module:

```nix
{ config, ... }:

{
  services.ai = {
    enable = true;
    # This will include claude-code CLI
  };

  # Add Claude Desktop GUI separately
  environment.systemPackages = with pkgs; [
    claude-desktop
  ];
}
```

## Features from claude-desktop-debian

This package inherits all features from claude-desktop-debian v1.2.1:

✅ **Wayland Support**: Native Wayland by default with XWayland fallback available
✅ **Claude Code Integration**: node-pty support for terminal integration
✅ **System Tray**: Functional tray icon on Wayland
✅ **MCP Servers**: Full Model Context Protocol support via FHS wrapper
✅ **Desktop Integration**: Proper .desktop file and icon installation

### Wayland vs XWayland

This package now **defaults to native Wayland** with explicit Electron flags:
- Default: `claude-desktop` → native Wayland with `--ozone-platform=wayland`
- Fallback: `claude-desktop-xwayland` → XWayland mode (better for global hotkeys)

**Why native Wayland by default?**
- Fixes blank window issue on Wayland compositors
- Better integration with Wayland-native desktops (Niri, Sway, Hyprland)
- Proper window decorations and scaling

**When to use XWayland mode:**
- If you rely on global hotkeys (Ctrl+Alt+Space may not work in Wayland mode)
- If you experience issues with the Wayland backend

```bash
# Use Wayland mode (default)
claude-desktop

# Force XWayland mode
claude-desktop-xwayland
```

## Known Issues

Based on the upstream claude-desktop-linux-flake issues:

1. **ERR_QUIC_PROTOCOL_ERROR**: If you encounter network errors, try launching with:
   ```bash
   claude-desktop --disable-quic
   ```

2. **Desktop Portal Services**: Some desktop environments may need xdg-desktop-portal packages:
   ```nix
   environment.systemPackages = with pkgs; [
     xdg-desktop-portal
     xdg-desktop-portal-gtk  # or xdg-desktop-portal-kde
   ];
   ```

3. **Google Login Issues**: OAuth may require setting up protocol handlers. The debian package handles this.

## Development

### Updating to New Version

When claude-desktop-debian releases a new version:

1. Update `version` and `debVersion` in `default.nix`
2. Calculate new hash:
   ```bash
   nix-prefetch-url "https://github.com/aaddrick/claude-desktop-debian/releases/download/v${NEW_VERSION}/claude-desktop_${CLAUDE_VERSION}_amd64.deb"
   nix hash to-sri --type sha256 <hash-output>
   ```
3. Update `sha256` in `default.nix`
4. Test: `nix build .#claude-desktop`

### Building Locally

```bash
# Build FHS wrapper
nix build .#claude-desktop

# Build unwrapped version
nix build .#claude-desktop.unwrapped

# Check package structure
tree $(nix build .#claude-desktop --print-out-paths)
```

## License

- **Claude Desktop**: Proprietary software by Anthropic
- **claude-desktop-debian**: Build scripts licensed under MIT/Apache 2.0
- **This package**: MIT/Apache 2.0 (build script only)

## Credits

- **Anthropic**: Claude Desktop application
- **aaddrick**: [claude-desktop-debian](https://github.com/aaddrick/claude-desktop-debian) packaging
- **k3d3**: [claude-desktop-linux-flake](https://github.com/k3d3/claude-desktop-linux-flake) original Nix approach

## See Also

- [Claude Desktop Official Docs](https://support.anthropic.com/en/articles/10065433-installing-claude-for-desktop)
- [axios AI Module Documentation](../../docs/modules/ai.md) (if exists)
- [MCP Server Configuration](../../home/ai/mcp.nix)
