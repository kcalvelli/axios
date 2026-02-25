## Context

axios deeply integrates DMS as its desktop shell (Niri compositor + DankMaterialShell), with extensive home-manager configuration for theming, keybindings, feature toggles, and lifecycle management. DMS has a growing community plugin ecosystem (~75 plugins) with a Nix flake registry (`dms-plugin-registry`) that provides declarative plugin management via `programs.dank-material-shell.plugins`.

Currently, axios uses zero community plugins. axios-monitor (a custom fork of nixMonitor) is the only DMS plugin, maintained as a separate flake input with axiOS-specific functionality (dual rebuild, flake update, axiOS version tracking).

## Goals / Non-Goals

**Goals:**
- Add `dms-plugin-registry` as a flake input so plugins are available declaratively
- Import the registry module in both desktop profiles (standard + normie)
- Auto-enable a curated set of plugins based on existing axiOS module/hardware flags
- Explicitly disable `nixMonitor` to avoid conflict with axios-monitor
- Keep all other plugins available for users to opt into downstream

**Non-Goals:**
- Replacing axios-monitor with nixMonitor (axios-monitor has axiOS-specific features)
- Adding plugin configuration options to axiOS (users configure via `programs.dank-material-shell.plugins` directly)
- Making any changes to the system-level NixOS desktop module (plugins are home-manager only)

## Decisions

### 1. Import registry module in home desktop profiles, not in lib/default.nix

The registry provides a home-manager module (not NixOS). It should be imported alongside the existing DMS home modules in `home/desktop/default.nix` and `home/desktop/normie.nix`.

**Alternative considered:** Import in `lib/default.nix` sharedModules. Rejected because plugins are desktop-specific and the module is a home-manager module.

### 2. Use `osConfig` for conditional enablement signals

Home-manager modules can read NixOS-level config via `osConfig`. The signals needed:
- `osConfig.desktop.enable` — desktop is active (always true in these files, but good for clarity)
- `osConfig.services.ai.enable or false` — AI module active
- `osConfig.hardware.laptop.enable or false` — laptop form factor
- `osConfig.networking.tailscale.enable or false` — tailscale active (standard NixOS option, set by axios networking module)
- `osConfig.virt.enable or false` — virtualisation module active
- `osConfig.hardware.logitech.wireless.enableGraphical or false` — already used for Solaar, pattern is established

**Alternative considered:** Passing hostCfg flags through specialArgs. Rejected — `osConfig` is the established pattern for cross-boundary queries (already used for Solaar, AI, PIM checks).

### 3. Curated plugin tiers

**Always-on** (when desktop enabled):
- `displayManager` — Monitor hardware brightness/resolution control. Universal utility.
- `niriWindows` — Window switcher from launcher. Core Niri integration.
- `niriScreenshot` — Screenshot from control center. Core Niri integration.

**Conditional on module flags:**
- `claudeCodeUsage` — when `services.ai.enable` (token tracking for Claude Code users)
- `tailscale` — when `networking.tailscale.enable` (Tailscale toggle in DankBar)
- `dankKDEConnect` — always on (kdeconnect is already enabled in both profiles)
- `dockerManager` — when `osConfig.virt.enable or false` (Docker/Podman container status)

**Conditional on hardware:**
- `dankBatteryAlerts` — when `hardware.laptop.enable` (battery warnings)
- `powerUsagePlugin` — when `hardware.laptop.enable` (power draw monitoring)

**Explicitly disabled:**
- `nixMonitor` — axios-monitor replaces this

**Alternative considered:** Enabling more plugins by default (webSearch, commandRunner, sshConnections). Rejected — keep the curated set minimal and aligned with existing module flags. Users can enable any plugin in their downstream config.

### 4. Same plugin set for standard and normie profiles

Both profiles get the same conditional plugins. Monitoring widgets (battery, power, display) are equally useful for non-technical users. The normie profile already enables the same DMS feature toggles as standard.

**Alternative considered:** Fewer plugins for normie. Rejected — these are status indicators and control panels, not power-user tools. A non-technical user benefits from battery alerts and display controls.

## Risks / Trade-offs

**[DMS plugins option may not exist yet]** → The registry module checks `options ? programs.dank-material-shell.plugins`. If the current DMS version in axios's flake.lock doesn't expose this option, the module silently no-ops. Verify by checking DMS upstream or updating flake.lock. Low risk — the module handles this gracefully.

**[Plugin dependency chain]** → Some plugins may need external tools not in axiOS's package set. The curated plugins (displayManager, niriWindows, niriScreenshot, tailscale, etc.) should have minimal external dependencies since they interact with services already present. → Verify during implementation.

**[Additional flake input maintenance]** → One more input to track in flake.lock updates. Low burden — registry updates are independent and non-breaking (all plugins default to disabled).

**[axios-monitor + nixMonitor conflict]** → Both provide Nix system monitoring. Explicitly disabling nixMonitor prevents dual-widget confusion. → Already handled in design.
