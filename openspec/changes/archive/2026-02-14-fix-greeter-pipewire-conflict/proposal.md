## Why

The greetd greeter user's PipeWire instance socket-activates at boot and holds ALSA HDMI audio devices open. When the real user logs in, WirePlumber tries to claim these devices but gets "Device or resource busy" because the greeter's PipeWire hasn't shut down yet (10-second delay). WirePlumber doesn't retry, so HDMI audio is broken every boot.

## What Changes

- Add `ConditionUser` exclusions to PipeWire user sockets (`pipewire.socket`, `pipewire-pulse.socket`) to prevent socket-activation for the `greeter` user
- This is added in the desktop module since it's the module where both greetd and PipeWire coexist

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `desktop`: Add requirement that PipeWire must not socket-activate for the greeter user to prevent audio device contention at login

## Impact

- **Code**: `modules/desktop/default.nix` - add two `systemd.user.sockets` overrides
- **Behavior**: Greeter session will no longer have PipeWire/WirePlumber running, eliminating ALSA device contention and `/var/empty/.local/state/wireplumber` permission errors
- **Dependencies**: None - uses existing NixOS systemd options
