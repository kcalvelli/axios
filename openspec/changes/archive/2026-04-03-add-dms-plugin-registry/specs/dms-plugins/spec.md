## ADDED Requirements

### Requirement: Declarative DMS plugin management

The desktop module SHALL integrate the dms-plugin-registry flake input to provide declarative management of community DMS plugins via `programs.dank-material-shell.plugins`.

#### Scenario: Registry module is imported

- **WHEN** `desktop.enable = true` and user has standard or normie profile
- **THEN** the dms-plugin-registry home-manager module is imported
- **AND** all registry plugins are available as `programs.dank-material-shell.plugins.<id>.enable` options
- **AND** all plugins default to disabled unless explicitly enabled by axiOS or the user

### Requirement: Core Niri plugins are always enabled

The desktop module SHALL auto-enable DMS plugins that provide core Niri integration for all desktop users.

#### Scenario: Desktop user gets Niri plugins

- **WHEN** `desktop.enable = true`
- **THEN** `programs.dank-material-shell.plugins.displayManager.enable` is true
- **AND** `programs.dank-material-shell.plugins.niriWindows.enable` is true
- **AND** `programs.dank-material-shell.plugins.niriScreenshot.enable` is true
- **AND** `programs.dank-material-shell.plugins.dankKDEConnect.enable` is true

### Requirement: AI-conditional plugin enablement

The claudeCodeUsage plugin SHALL be auto-enabled when the AI module is active.

#### Scenario: AI module enables Claude Code usage tracking

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.services.ai.enable` is true
- **THEN** `programs.dank-material-shell.plugins.claudeCodeUsage.enable` is true

#### Scenario: AI module disabled skips Claude Code usage tracking

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.services.ai.enable` is false or unset
- **THEN** `programs.dank-material-shell.plugins.claudeCodeUsage.enable` is false

### Requirement: Networking-conditional plugin enablement

The tailscale DMS plugin SHALL be auto-enabled when Tailscale is active at the system level.

#### Scenario: Tailscale module enables tailscale bar widget

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.services.tailscale.enable` is true
- **THEN** `programs.dank-material-shell.plugins.tailscale.enable` is true

#### Scenario: Tailscale not enabled skips bar widget

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.services.tailscale.enable` is false or unset
- **THEN** `programs.dank-material-shell.plugins.tailscale.enable` is false

### Requirement: Virtualisation-conditional plugin enablement

The dockerManager plugin SHALL be auto-enabled when the virtualisation module is active.

#### Scenario: Virtualisation module enables container monitoring

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.virt.enable` is true
- **THEN** `programs.dank-material-shell.plugins.dockerManager.enable` is true

#### Scenario: Virtualisation not enabled skips container monitoring

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.virt.enable` is false or unset
- **THEN** `programs.dank-material-shell.plugins.dockerManager.enable` is false

### Requirement: Laptop-conditional plugin enablement

Battery and power monitoring plugins SHALL be auto-enabled for laptop form factors.

#### Scenario: Laptop gets battery and power plugins

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.hardware.laptop.enable` is true
- **THEN** `programs.dank-material-shell.plugins.dankBatteryAlerts.enable` is true
- **AND** `programs.dank-material-shell.plugins.powerUsagePlugin.enable` is true

#### Scenario: Desktop skips battery and power plugins

- **WHEN** `desktop.enable = true`
- **AND** `osConfig.hardware.laptop.enable` is false or unset
- **THEN** `programs.dank-material-shell.plugins.dankBatteryAlerts.enable` is false
- **AND** `programs.dank-material-shell.plugins.powerUsagePlugin.enable` is false

### Requirement: nixMonitor is explicitly disabled

The nixMonitor registry plugin SHALL be explicitly disabled to prevent conflict with axios-monitor.

#### Scenario: nixMonitor does not conflict with axios-monitor

- **WHEN** `desktop.enable = true`
- **AND** the dms-plugin-registry module is imported
- **THEN** `programs.dank-material-shell.plugins.nixMonitor.enable` is false
- **AND** axios-monitor continues to function as the system monitoring widget

### Requirement: Users can enable additional plugins downstream

Users SHALL be able to enable any registry plugin in their downstream configuration without modifying axiOS.

#### Scenario: User enables webSearch plugin

- **WHEN** user adds `programs.dank-material-shell.plugins.webSearch.enable = true` in their downstream config
- **THEN** the webSearch plugin is installed and functional
- **AND** no axiOS modules need to be modified

### Requirement: Both profiles receive identical plugin configuration

Standard and normie profiles SHALL receive the same conditional plugin enablement logic.

#### Scenario: Normie user on laptop gets battery plugins

- **WHEN** user has `homeProfile = "normie"`
- **AND** `osConfig.hardware.laptop.enable` is true
- **THEN** `programs.dank-material-shell.plugins.dankBatteryAlerts.enable` is true
- **AND** behavior is identical to standard profile

#### Scenario: Standard user on laptop gets battery plugins

- **WHEN** user has `homeProfile = "standard"`
- **AND** `osConfig.hardware.laptop.enable` is true
- **THEN** `programs.dank-material-shell.plugins.dankBatteryAlerts.enable` is true
- **AND** behavior is identical to normie profile
