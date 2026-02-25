## Why

DMS has a rich plugin ecosystem (75+ community plugins) with a Nix flake registry that enables declarative management. axios deeply integrates DMS but currently uses zero community plugins. The registry provides a clean module that hooks into `programs.dank-material-shell.plugins`, and axios is uniquely positioned to auto-enable relevant plugins based on existing module flags (formFactor, services.ai, modules.virtualisation, etc.) — the same conditional wiring pattern used for MCP servers.

## What Changes

- Add `dms-plugin-registry` as a new flake input (follows nixpkgs)
- Import the registry's home-manager module in the desktop home modules (standard + normie profiles)
- Wire conditional plugin enablement based on existing axiOS module/hardware flags:
  - **Always-on** (when desktop enabled): `displayManager`, `niriWindows`, `niriScreenshot`
  - **AI-conditional**: `claudeCodeUsage` (when `services.ai.enable`)
  - **Networking-conditional**: `tailscale` (when tailscale module active)
  - **Desktop-conditional**: `dankKDEConnect` (kdeconnect is already enabled by desktop module)
  - **Virtualisation-conditional**: `dockerManager` (when `modules.virtualisation`)
  - **Laptop-conditional**: `dankBatteryAlerts`, `powerUsagePlugin` (when `formFactor == "laptop"`)
- Explicitly disable `nixMonitor` (axios-monitor already provides this, customized for axiOS)
- All other registry plugins remain available but disabled — users opt in via their downstream config

## Capabilities

### New Capabilities
- `dms-plugins`: Declarative DMS plugin management via the community registry, with conditional auto-enablement based on axiOS module flags

### Modified Capabilities
- `desktop`: Desktop module gains plugin registry integration and conditional plugin wiring

## Impact

- **New flake input**: `dms-plugin-registry` (github:AvengeMedia/dms-plugin-registry, follows nixpkgs)
- **Files modified**: `flake.nix` (input), `home/desktop/default.nix` (standard profile), `home/desktop/normie.nix` (normie profile)
- **Dependencies**: Requires DMS to expose `programs.dank-material-shell.plugins` option (verify current DMS version supports this)
- **Build impact**: Minimal — disabled plugins are not fetched/built. Only enabled plugins add derivations.
- **No breaking changes**: Purely additive
