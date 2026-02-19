## MODIFIED Requirements

### Requirement: SSD-Consistent Application Selection

All primary desktop applications respect the compositor's `prefer-no-csd` setting. Brief utility windows (screenshot annotation, audio control) are exempt. The normie profile uses `prefer-no-csd = false`, so applications draw client-side decorations (titlebars with window controls).

#### Scenario: User opens any default application (standard profile)

- **Given**: Niri is running with `prefer-no-csd = true` (standard profile)
- **WHEN**: User opens any application from the default desktop set
- **THEN**: The application uses server-side decorations (compositor-drawn titlebar)
- **AND**: The application's appearance is visually consistent with other windows

#### Scenario: User opens any default application (normie profile)

- **Given**: Niri is running with `prefer-no-csd = false` (normie profile)
- **WHEN**: User opens any application from the default desktop set
- **THEN**: The application draws its own client-side decorations (titlebar with close/minimize/maximize)
- **AND**: GTK and Qt apps may have slightly different titlebar styles

#### Scenario: Brief utility exceptions

- **Given**: Swappy (screenshot annotation) or Pavucontrol (audio routing) is opened
- **WHEN**: The window appears
- **THEN**: CSD may be visible (these are brief utility windows)
- **AND**: This is acceptable because these are transient tools, not primary work surfaces

## ADDED Requirements

### Requirement: Solaar autostart is hardware-conditional

Solaar autostart SHALL be determined by hardware configuration, not by profile selection. Both standard and normie profiles receive Solaar autostart when Logitech hardware support is enabled.

#### Scenario: System with Logitech support enabled

- **WHEN** `osConfig.hardware.logitech.wireless.enableGraphical` is true
- **THEN** a Solaar autostart desktop entry is created in the user's home
- **AND** Solaar launches with `--window=hide --battery-icons=solaar`
- **AND** this applies to both standard and normie profile users

#### Scenario: System without Logitech support

- **WHEN** `osConfig.hardware.logitech.wireless.enableGraphical` is false or unset
- **THEN** no Solaar autostart entry is created
- **AND** this applies to both standard and normie profile users

### Requirement: AI home modules are profile-conditional

The AI home-manager modules SHALL be imported only for profiles that include developer tooling (currently: standard). They SHALL NOT be applied universally via `sharedModules`.

#### Scenario: Standard user gets AI tools

- **WHEN** a user with `homeProfile = "standard"` is on a host with `modules.ai = true`
- **THEN** `home/ai/` modules are imported for that user
- **AND** AI tool packages, MCP configuration, and system prompts are available

#### Scenario: Normie user does not get AI tools

- **WHEN** a user with `homeProfile = "normie"` is on a host with `modules.ai = true`
- **THEN** `home/ai/` modules are NOT imported for that user
- **AND** no AI packages or configuration files are generated in their home directory
- **AND** the system-level AI NixOS module remains functional for other users

### Requirement: Init script prompts per-user profile

The init script SHALL prompt for each user's profile during user collection instead of deriving the host-level profile from form factor.

#### Scenario: Primary user profile selection

- **WHEN** the init script collects primary user information
- **THEN** it prompts for profile selection: "standard" or "normie"
- **AND** the selection is stored per-user in the generated `users/<name>.nix` file as `homeProfile = "<selection>"`
- **AND** the host-level `homeProfile` defaults to `"standard"`

#### Scenario: Additional user profile selection

- **WHEN** the init script collects an additional user
- **THEN** it prompts for that user's profile: "standard" or "normie"
- **AND** the selection is written to that user's generated config file

#### Scenario: Form factor no longer determines profile

- **WHEN** the init script detects form factor (desktop or laptop)
- **THEN** form factor is used for hardware configuration only
- **AND** form factor does NOT influence the `homeProfile` value
- **AND** the `HOME_PROFILE` derivation from form factor is removed
