# Syncthing XDG Sync

## Purpose

Declarative Syncthing module for peer-to-peer XDG directory synchronization across axiOS hosts via Tailscale MagicDNS.

## Components

### Syncthing XDG Sync
- **Protocol**: Peer-to-peer file sync via Syncthing over Tailscale MagicDNS
- **Transport**: Tailscale-only (no global discovery, relays, or NAT traversal)
- **Folders**: XDG directory names (documents, music, pictures, etc.) resolved to user home paths
- **Devices**: Addressed by Tailscale MagicDNS names with optional overrides
- **Implementation**: `modules/syncthing/default.nix`

## Requirements

### Requirement: Syncthing XDG sync module

The system SHALL provide an `axios.syncthing` NixOS module that configures Syncthing to synchronize XDG directories between axiOS hosts over Tailscale.

#### Scenario: Module enabled with devices and folders

- **WHEN** `axios.syncthing.enable` is `true`
- **AND** `axios.syncthing.user` is set to a valid username
- **AND** at least one device is declared in `axios.syncthing.devices`
- **AND** at least one folder is declared in `axios.syncthing.folders`
- **THEN** `services.syncthing.enable` SHALL be `true`
- **AND** `services.syncthing.user` SHALL match `axios.syncthing.user`
- **AND** `services.syncthing.dataDir` SHALL be the user's home directory
- **AND** `services.syncthing.settings.options.globalAnnounceEnabled` SHALL be `false`
- **AND** `services.syncthing.settings.options.localAnnounceEnabled` SHALL be `false`
- **AND** `services.syncthing.settings.options.relaysEnabled` SHALL be `false`
- **AND** `services.syncthing.settings.options.natEnabled` SHALL be `false`

#### Scenario: Module disabled

- **WHEN** `axios.syncthing.enable` is `false`
- **THEN** no Syncthing service or configuration SHALL be generated

### Requirement: XDG folder name resolution

The module SHALL accept folder declarations by XDG directory name and resolve them to the correct filesystem path for the configured user.

#### Scenario: Folder declared by XDG name

- **WHEN** a folder is declared as `axios.syncthing.folders.documents`
- **AND** `axios.syncthing.user` is `"alice"`
- **THEN** the Syncthing folder path SHALL resolve to `/home/alice/Documents`

#### Scenario: All supported XDG names

- **WHEN** a folder is declared using any of the following names: `documents`, `music`, `pictures`, `videos`, `downloads`, `templates`, `desktop`, `publicshare`
- **THEN** the folder path SHALL resolve to the corresponding standard XDG default path under the user's home directory (e.g., `documents` resolves to `~/Documents`, `pictures` resolves to `~/Pictures`)

#### Scenario: Custom path override

- **WHEN** a folder is declared with `pathOverride` set to a non-null path
- **THEN** the Syncthing folder path SHALL use the override path instead of the XDG default

#### Scenario: Invalid folder name

- **WHEN** a folder is declared with a name not in the supported XDG name list
- **THEN** the NixOS module evaluation SHALL produce a type error (enforced by `lib.types.enum`)

### Requirement: Device declarations with Tailscale MagicDNS addresses

The module SHALL accept device declarations that specify Syncthing device IDs and derive addresses from Tailscale MagicDNS names.

#### Scenario: Device addressed by MagicDNS name (default)

- **WHEN** a device is declared as `axios.syncthing.devices.pangolin` with `id` set
- **AND** `networking.tailscale.domain` is `"example-tailnet.ts.net"`
- **AND** `tailscaleName` is not set
- **THEN** `services.syncthing.settings.devices.pangolin.id` SHALL be set to the declared device ID
- **AND** `services.syncthing.settings.devices.pangolin.addresses` SHALL be set to `[ "tcp://pangolin.example-tailnet.ts.net:22000" ]`

#### Scenario: Device with explicit Tailscale name override

- **WHEN** a device is declared as `axios.syncthing.devices.phone` with `tailscaleName = "google-pixel-10"`
- **AND** `networking.tailscale.domain` is `"example-tailnet.ts.net"`
- **THEN** `services.syncthing.settings.devices.phone.addresses` SHALL be set to `[ "tcp://google-pixel-10.example-tailnet.ts.net:22000" ]`

#### Scenario: Device with fully custom addresses

- **WHEN** a device is declared with `addresses` set to a non-null list
- **THEN** `services.syncthing.settings.devices.<name>.addresses` SHALL use the declared addresses instead of deriving from MagicDNS

#### Scenario: Tailscale domain required

- **WHEN** `axios.syncthing.enable` is `true`
- **AND** `networking.tailscale.domain` is not set
- **AND** no device overrides `addresses` explicitly
- **THEN** an assertion SHALL fail with a message instructing the user to set `networking.tailscale.domain`

### Requirement: Per-folder device association

Each folder declaration SHALL specify which devices participate in syncing that folder.

#### Scenario: Folder with specific devices

- **WHEN** a folder `documents` is declared with `devices = [ "workstation" "laptop" ]`
- **THEN** `services.syncthing.settings.folders."documents".devices` SHALL include entries for `"workstation"` and `"laptop"`

#### Scenario: Folder with no devices

- **WHEN** a folder is declared with an empty `devices` list
- **THEN** the folder SHALL be configured with no shared devices (local-only)

### Requirement: Selective folder sync per host

Each host SHALL be able to independently declare which XDG directories it participates in, without requiring all hosts to sync the same set.

#### Scenario: Workstation syncs all, server syncs only documents

- **WHEN** host A declares folders for `documents`, `music`, `pictures`, and `videos`
- **AND** host B declares folders for `documents` only
- **THEN** host A SHALL sync all four directories
- **AND** host B SHALL sync only `documents`
- **AND** no error SHALL be raised due to the mismatch

### Requirement: Conflict handling configuration

The module SHALL support configurable ignore patterns per folder for managing Syncthing conflict files.

#### Scenario: Default conflict behavior

- **WHEN** a folder is declared without `ignorePatterns`
- **THEN** Syncthing's default `.sync-conflict-*` file creation SHALL apply
- **AND** no `.stignore` file SHALL be generated by the module

#### Scenario: Folder with ignore patterns

- **WHEN** a folder is declared with `ignorePatterns = [ "*.tmp" ".DS_Store" ]`
- **THEN** the module SHALL generate ignore patterns in the Syncthing folder configuration

### Requirement: Tailscale transport enforcement

The module SHALL enforce Tailscale-only connectivity by disabling all external discovery and relay mechanisms.

#### Scenario: Transport defaults applied

- **WHEN** the module is enabled
- **THEN** Syncthing SHALL NOT attempt global announce discovery
- **AND** Syncthing SHALL NOT attempt local network discovery
- **AND** Syncthing SHALL NOT use relay servers
- **AND** Syncthing SHALL NOT attempt NAT traversal

### Requirement: Module user option

The module SHALL require a `user` option specifying which system user owns the Syncthing instance.

#### Scenario: User option set

- **WHEN** `axios.syncthing.user` is set to `"alice"`
- **THEN** the Syncthing service SHALL run as user `"alice"`
- **AND** `services.syncthing.dataDir` SHALL be `/home/alice`
- **AND** `services.syncthing.configDir` SHALL be `/home/alice/.config/syncthing`

#### Scenario: User option not set

- **WHEN** `axios.syncthing.enable` is `true`
- **AND** `axios.syncthing.user` is not set
- **THEN** an assertion SHALL fail with a message instructing the user to set `axios.syncthing.user`

### Requirement: Module registration

The module SHALL be registered in the axiOS module system following existing conventions.

#### Scenario: Module available via modules flag

- **WHEN** a host config sets `modules.syncthing = true`
- **THEN** the `syncthing` NixOS module SHALL be imported
- **AND** `axios.syncthing.enable` SHALL be set to `true` via `lib/default.nix` hostModule wiring

#### Scenario: Module not imported by default

- **WHEN** a host config does not set `modules.syncthing`
- **THEN** the `syncthing` module SHALL NOT be imported (default is `false`)
