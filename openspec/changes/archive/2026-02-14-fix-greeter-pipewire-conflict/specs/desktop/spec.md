## ADDED Requirements

### Requirement: Greeter PipeWire Isolation

The desktop module SHALL prevent PipeWire from socket-activating for the greetd greeter user. The greeter does not need audio, and its PipeWire instance causes ALSA device contention that breaks HDMI audio for the real user at login.

#### Scenario: Greeter session does not start PipeWire

- **WHEN** greetd spawns the greeter user session
- **THEN** `pipewire.socket` SHALL NOT activate for the greeter user
- **AND** `pipewire-pulse.socket` SHALL NOT activate for the greeter user
- **AND** no PipeWire or WirePlumber processes run under the greeter uid

#### Scenario: Real user HDMI audio works after login

- **WHEN** user logs in via the greeter
- **THEN** WirePlumber SHALL successfully claim all ALSA HDMI devices
- **AND** the configured default audio sink (e.g., `hdmi-stereo-extra2`) SHALL be available immediately
- **AND** no "Device or resource busy" errors appear in the user's WirePlumber journal

#### Scenario: PipeWire works normally for regular users

- **WHEN** any non-root, non-greeter user session starts
- **THEN** PipeWire socket-activation SHALL work as normal
- **AND** audio devices are available without manual intervention

#### Scenario: No WirePlumber permission errors for greeter

- **WHEN** greetd spawns the greeter session
- **THEN** there are no `wp-state: failed to create directory /var/empty/.local/state/wireplumber` errors in the journal
