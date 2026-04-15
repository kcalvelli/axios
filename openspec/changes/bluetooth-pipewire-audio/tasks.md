## 1. Bluetooth Profile Delegation

- [x] 1.1 Add `hardware.bluetooth.settings.General.Disable = "Headset"` to `modules/system/bluetooth.nix` inside the existing `config` block
- [x] 1.2 Verify the setting is unconditional (no new mkIf guard — it's always applied when bluetooth is enabled)

## 2. WirePlumber Seat Monitoring Option

- [x] 2.1 Add `axios.system.bluetooth.disableSeatMonitoring` option (type bool, default false) to `modules/system/bluetooth.nix`
- [x] 2.2 Create WirePlumber config fragment that sets `monitor.bluez.seat-monitoring = disabled` via `wireplumber.extraConfig`, gated behind `lib.mkIf cfg.disableSeatMonitoring`
- [x] 2.3 Used `wireplumber.extraConfig` (cleaner than `configPackages` + `writeTextDir` — same result, NixOS handles the derivation)

## 3. Formatting and Validation

- [x] 3.1 Run `nix fmt .` to format modified files
- [x] 3.2 Run `nix flake check` to validate the flake still evaluates cleanly
