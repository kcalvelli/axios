## Context

axiOS enables PipeWire with WirePlumber for all audio (`modules/system/sound.nix`) and Bluetooth unconditionally (`modules/system/bluetooth.nix`). The current bluetooth config sets `enable = true` and `powerOnBoot` but does nothing about HFP/HSP profile ownership. By default, bluetoothd registers these profiles itself, conflicting with PipeWire's native bluetooth backend which also wants to own them. This causes connection failures and codec negotiation issues with BT headsets.

Separately, WirePlumber's bluez seat monitoring assumes an active logind seat. Headless machines (servers, kiosks) without a graphical seat get bluez connections refused because WirePlumber thinks nobody's home.

## Goals / Non-Goals

**Goals:**
- Eliminate HFP/HSP profile conflict between bluetoothd and PipeWire
- Provide an opt-in escape hatch for headless machines that need BT audio without a logind seat

**Non-Goals:**
- Changing PipeWire or WirePlumber package versions
- Adding A2DP codec configuration (mSBC, LC3, aptX) — that's a separate concern
- Modifying the desktop module's audio stack

## Decisions

### 1. Unconditional `Disable = "Headset"` in bluetooth settings

**Decision**: Always set `hardware.bluetooth.settings.General.Disable = "Headset"` when bluetooth is enabled.

**Rationale**: axiOS always enables PipeWire with WirePlumber. There is no supported configuration where bluetoothd should own HFP/HSP profiles. Making this conditional would add complexity for a scenario that doesn't exist in this distribution.

**Alternative considered**: Making it opt-in via an option. Rejected because every axiOS system runs PipeWire — there's no valid reason to keep bluetoothd's headset profiles active.

### 2. WirePlumber seat monitoring as opt-in option

**Decision**: Add `axios.system.bluetooth.disableSeatMonitoring` (default `false`) that writes a WirePlumber config fragment via `services.pipewire.wireplumber.configPackages`.

**Rationale**: Most axiOS machines are desktops/laptops with active logind seats. Headless is the exception. Default-off keeps the common case simple while providing a clean toggle for edge cases.

**Alternative considered**: Auto-detecting headless via `!config.desktop.enable`. Rejected because not all non-desktop machines are headless, and the user knows better than heuristics whether they have a seat.

### 3. Config lives in bluetooth.nix, not sound.nix

**Decision**: Both the bluetoothd setting and the WirePlumber override go in `modules/system/bluetooth.nix`.

**Rationale**: These are bluetooth-specific behaviors. `sound.nix` is a minimal PipeWire enablement file and should stay that way. The WirePlumber config fragment is bluetooth-adjacent even though it touches the WirePlumber config path.

## Risks / Trade-offs

- **[Risk] Disabling Headset profiles breaks non-PipeWire setups** → Mitigated by the fact that axiOS always enables PipeWire. If someone imports only the bluetooth module without sound, they'd get a broken HFP/HSP — but that's not a supported configuration.
- **[Risk] WirePlumber configPackages syntax changes upstream** → Low risk. The `monitor.bluez.properties` path is stable WirePlumber 0.4+ API. If it changes, it'll break everyone, not just us.
- **[Trade-off] Unconditional vs conditional Headset disable** → We lose the ability to let bluetoothd handle headset profiles. This is intentional — PipeWire does it better, and the dual-registration is the bug.
