## Why

When PipeWire handles Bluetooth audio, bluetoothd still registers HFP/HSP profiles by default, causing profile ownership conflicts. PipeWire's native bluetooth backend needs exclusive ownership of these profiles for reliable BT audio. Additionally, headless machines without an active logind seat need WirePlumber's seat monitoring disabled to prevent bluez from refusing connections.

## What Changes

- Add `hardware.bluetooth.settings.General.Disable = "Headset"` unconditionally in `modules/system/bluetooth.nix` — prevents bluetoothd from registering HFP/HSP profiles so PipeWire owns them exclusively
- Add an optional WirePlumber configuration to disable bluez seat monitoring via `configPackages` — for headless machines without an active logind seat
- Expose a new option `axios.system.bluetooth.disableSeatMonitoring` (default `false`) to control the WirePlumber override

## Capabilities

### New Capabilities

- `bluetooth-pipewire-audio`: Bluetooth audio profile delegation to PipeWire and optional WirePlumber seat monitoring override

### Modified Capabilities

_None — this is additive configuration within the existing system module._

## Impact

- `modules/system/bluetooth.nix` — expanded with PipeWire-aware bluetooth settings and optional WirePlumber config
- `modules/system/sound.nix` — potentially touched if WirePlumber config belongs closer to PipeWire setup
- No breaking changes — existing bluetooth behavior improves (PipeWire already handles BT audio, this just removes the profile conflict)
- No new dependencies
