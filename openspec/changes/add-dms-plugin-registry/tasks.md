## 1. Flake Input

- [x] 1.1 Add `dms-plugin-registry` input to `flake.nix` with `inputs.nixpkgs.follows = "nixpkgs"`
- [x] 1.2 Run `nix flake lock --update-input dms-plugin-registry` to populate flake.lock

## 2. Standard Profile Integration

- [x] 2.1 Import `inputs.dms-plugin-registry.homeModules.default` in `home/desktop/default.nix`
- [x] 2.2 Add always-on plugins: `displayManager`, `niriWindows`, `niriScreenshot`, `dankKDEConnect`
- [x] 2.3 Add AI-conditional plugin: `claudeCodeUsage` (when `osConfig.services.ai.enable or false`)
- [x] 2.4 Add networking-conditional plugin: `tailscale` (when `osConfig.services.tailscale.enable or false`)
- [x] 2.5 Add virtualisation-conditional plugin: `dockerManager` (when `osConfig.virt.enable or false`)
- [x] 2.6 Add laptop-conditional plugins: `dankBatteryAlerts`, `powerUsagePlugin` (when `osConfig.hardware.laptop.enable or false`)
- [x] 2.7 Explicitly disable `nixMonitor` to prevent conflict with axios-monitor

## 3. Normie Profile Integration

- [x] 3.1 Import `inputs.dms-plugin-registry.homeModules.default` in `home/desktop/normie.nix`
- [x] 3.2 Add identical plugin enablement logic as standard profile (always-on, conditional, nixMonitor disabled)

## 4. Formatting and Validation

- [x] 4.1 Run `nix fmt .` to format all modified files
- [x] 4.2 Run `nix flake check` to validate flake structure
