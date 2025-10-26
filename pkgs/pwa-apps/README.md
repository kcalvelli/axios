# PWA Apps Package

Progressive Web App collection with bundled icons and launchers for axios.

## Overview

This package provides a curated collection of Progressive Web Apps (PWAs) that work immediately without requiring manual installation through the browser. Icons are bundled in the Nix store and desktop entries use direct URLs with Brave's `--app` mode.

## Features

- **Works immediately** - No manual PWA installation required
- **Bundled icons** - Icons stored in Nix store, version controlled
- **Direct URL launch** - Uses `--app=URL` instead of opaque app-ids
- **Declarative** - PWAs defined in `pwa-defs.nix`
- **Portable** - Works across browser profiles and fresh installs

## Included PWAs

### Google Services
- Google Drive
- YouTube (with Subscriptions and Explore actions)
- Google Messages
- Google Meet
- Google Chat
- Google Maps
- Google Photos

### Proton Services
- Proton Pass
- Proton Mail
- Proton Drive
- Proton Calendar
- Proton Wallet

### Communication
- Element (Matrix client)
- Telegram Web
- Microsoft Teams
- Outlook (with New Event, New Message, Open Calendar actions)

### Other
- Sonos Controller
- Windows App (Remote Desktop)

## Structure

```
pkgs/pwa-apps/
├── default.nix      # Package derivation
├── pwa-defs.nix     # PWA definitions (URLs, names, icons, metadata)
└── README.md        # This file

home/resources/pwa-icons/
└── *.png           # Icon files (128x128 PNG)
```

## Package Outputs

The package installs:

- **Icons**: `$out/share/icons/hicolor/128x128/apps/*.png`
- **Launchers**: `$out/bin/pwa-*` (optional CLI launchers)

## Usage

The PWA package is automatically included in axios home modules (workstation, laptop) via `home/browser/pwa.nix`.

Desktop entries are generated automatically using the definitions in `pwa-defs.nix`.

## Adding New PWAs

1. Get the icon (128x128 PNG recommended):
   ```bash
   cp icon.png home/resources/pwa-icons/my-app.png
   ```

2. Add definition to `pkgs/pwa-apps/pwa-defs.nix`:
   ```nix
   my-app = {
     name = "My App";
     url = "https://example.com";
     icon = "my-app";
     categories = [ "Network" ];
     # Optional:
     mimeTypes = [ "x-scheme-handler/myapp" ];
     actions = {
       "action-id" = {
         name = "Action Name";
         url = "https://example.com/action";
       };
     };
   };
   ```

3. Rebuild your configuration

## Technical Details

### Why Direct URLs Instead of App-IDs?

Browser-generated PWA app-ids like `aghbiahbpaijignceidepookljebhfak` have several issues:

- Require manual browser installation first
- Opaque and hard to maintain
- Tied to specific browser profile
- Icons stored in user's `~/.local/share`

Using `--app=URL` with bundled icons:
- Works immediately on fresh installs
- Clear, readable URLs
- Browser-agnostic approach
- Icons in Nix store (version controlled)

### Browser Compatibility

Currently configured for Brave, but the approach works with:
- Brave: `--app=URL`
- Chrome/Chromium: `--app=URL`
- Firefox: (requires different approach, not yet supported)

## Integration

The package is consumed by `home/browser/pwa.nix` which:
1. Installs the package (`home.packages = [ pkgs.pwa-apps ]`)
2. Generates desktop entries from `pwa-defs.nix`
3. Sets icon paths to reference the Nix store

## License

Part of the axios NixOS framework - MIT License
