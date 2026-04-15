## ADDED Requirements

### Requirement: PipeWire owns Bluetooth headset profiles

The bluetooth module SHALL disable bluetoothd's HFP/HSP profile registration so that PipeWire's native bluetooth backend has exclusive ownership of headset profiles. This SHALL be unconditional — applied whenever bluetooth is enabled.

#### Scenario: Bluetooth headset connects on a standard desktop

- **WHEN** bluetooth is enabled (default Cairn configuration)
- **AND** a user pairs a Bluetooth headset
- **THEN** `hardware.bluetooth.settings.General.Disable` SHALL include `"Headset"`
- **AND** PipeWire's WirePlumber bluez backend SHALL be the sole owner of HFP/HSP profiles
- **AND** the headset SHALL connect without profile ownership conflicts

#### Scenario: A2DP profile remains unaffected

- **WHEN** bluetooth is enabled with the Headset profile disabled in bluetoothd
- **AND** a user connects a Bluetooth speaker or headset in A2DP mode
- **THEN** A2DP profile registration and audio routing SHALL work identically to before this change
- **AND** no A2DP-related settings SHALL be modified

#### Scenario: Bluetooth enabled without PipeWire (unsupported)

- **WHEN** a downstream consumer imports only the bluetooth module without enabling PipeWire
- **THEN** HFP/HSP profiles SHALL still be disabled in bluetoothd
- **AND** no HFP/HSP audio SHALL be available (this is an unsupported configuration)

### Requirement: Optional WirePlumber seat monitoring override

The bluetooth module SHALL expose an option to disable WirePlumber's bluez seat monitoring for headless machines that lack an active logind seat. This option SHALL default to disabled.

#### Scenario: Default configuration on a desktop machine

- **WHEN** `cairn.system.bluetooth.disableSeatMonitoring` is `false` (default)
- **THEN** no WirePlumber bluez seat monitoring override SHALL be generated
- **AND** WirePlumber SHALL use its default seat monitoring behavior

#### Scenario: Headless machine enables seat monitoring override

- **WHEN** `cairn.system.bluetooth.disableSeatMonitoring` is `true`
- **THEN** a WirePlumber configuration fragment SHALL be added via `services.pipewire.wireplumber.configPackages`
- **AND** the fragment SHALL set `monitor.bluez.properties` with `bluez5.seat-monitoring = false` (or equivalent WirePlumber 0.4+ syntax)
- **AND** Bluetooth audio connections SHALL succeed without an active logind seat

#### Scenario: Desktop user accidentally enables seat monitoring override

- **WHEN** `cairn.system.bluetooth.disableSeatMonitoring` is `true` on a machine with an active logind seat
- **THEN** Bluetooth audio SHALL still function normally
- **AND** the only effect SHALL be that WirePlumber skips the seat check (no negative impact on seated sessions)
