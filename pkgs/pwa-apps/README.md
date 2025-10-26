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

Desktop entries are generated automatically from `pwa-defs.nix`, with proper StartupWMClass hints to match Brave's app-id format.

### How it Works

1. **Icons**: Installed to `$out/share/icons/hicolor/128x128/apps/`
2. **Desktop Entries**: Created by home-manager with proper metadata
3. **StartupWMClass**: Set to match Brave's app-id pattern (`brave-{url-transformed}-Default`)
4. **Launch**: Apps launch via `brave --app=URL` with consistent app-ids

### Brave App-ID Format

Brave generates app-ids based on URLs:
- URL: `https://messages.google.com/web`
- App-ID: `brave-messages.google.com__web-Default`

The transformation:
1. Remove `https://` or `http://`
2. Replace `/` with `__` (double underscore)
3. Prefix with `brave-` and suffix with `-Default`

This pattern is used in:
- Desktop entry `StartupWMClass` hint
- Window manager rules (e.g., niri window rules)
- Keybindings that need to match specific windows

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
- Consistent app-id generation

### App-ID Matching for Window Rules

If you need to match PWA windows in your compositor (e.g., niri window rules), use Brave's app-id pattern:

```nix
# For Google Messages (https://messages.google.com/web)
{ app-id = "^brave-messages\\.google\\.com__web-Default$"; }
```

The desktop entry's `StartupWMClass` is automatically set to match this pattern, ensuring window managers can properly identify PWA windows.

### Browser Compatibility

Currently configured for Brave, but the approach works with:
- Brave: `--app=URL`
- Chrome/Chromium: `--app=URL`
- Firefox: (requires different approach, not yet supported)

### Launching PWAs

**From Application Launcher**: Search for the PWA name (e.g., "YouTube", "Drive")

**From Command Line**: 
```bash
# Via desktop entry
gio launch google-messages.desktop

# Direct launch (same result)
brave --app=https://messages.google.com/web
```

**From Keybindings**: Use direct launch for consistent app-id:
```nix
"Mod+G".action.spawn = [ "brave" "--app=https://messages.google.com/web" ];
```

## Integration

The package is consumed by `home/browser/pwa.nix` which:
1. Installs the package (`home.packages = [ pkgs.pwa-apps ]`)
2. Generates desktop entries from `pwa-defs.nix`
3. Sets icon paths to reference the Nix store

## License

Part of the axios NixOS framework - MIT License
