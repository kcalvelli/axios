## ADDED Requirements

### Requirement: LobeHub Desktop Package

axiOS SHALL provide a custom Nix derivation for LobeHub Desktop, packaged from the official AppImage release using `appimageTools.wrapType2`.

#### Scenario: Package builds successfully

- **WHEN** the LobeHub package is built via `nix build .#lobehub`
- **THEN** the derivation SHALL fetch the official LobeHub AppImage (v2.1.30 or later, stable channel only)
- **AND** the resulting binary SHALL be wrapped with `--ozone-platform=wayland` and `--enable-wayland-ime` flags
- **AND** the package SHALL include a `.desktop` file with appropriate name, icon, and categories

#### Scenario: LobeHub launches on Niri

- **WHEN** the user launches LobeHub from the Fuzzel application launcher
- **THEN** the application SHALL render using native Wayland (no XWayland fallback)
- **AND** the window SHALL use server-side decorations (Niri's `prefer-no-csd`)
- **AND** the application SHALL display the LobeHub chat interface

### Requirement: LobeHub Ollama Integration

LobeHub SHALL connect to the local Ollama instance for LLM inference without requiring additional configuration.

#### Scenario: Default Ollama connection (server role)

- **WHEN** `services.ai.local.enable = true` and `services.ai.local.role = "server"`
- **AND** Ollama is running on localhost:11434
- **AND** the user opens LobeHub
- **THEN** LobeHub SHALL be able to discover and use models from the local Ollama instance
- **AND** no proxy, reverse proxy, or Tailscale configuration SHALL be required

#### Scenario: Client role Ollama connection

- **WHEN** `services.ai.local.enable = true` and `services.ai.local.role = "client"`
- **AND** `OLLAMA_HOST` points to a remote Ollama server via Tailscale
- **THEN** the user SHALL be able to configure LobeHub to use the remote Ollama endpoint
- **AND** LobeHub SHALL support custom Ollama host URLs in its settings

#### Scenario: No local AI stack

- **WHEN** `services.ai.local.enable = false`
- **THEN** LobeHub SHALL NOT be installed
- **AND** the package SHALL NOT appear in the system closure

### Requirement: LobeHub Installation Gating

LobeHub SHALL only be installed when the local AI inference stack is enabled.

#### Scenario: AI local enabled

- **WHEN** `services.ai.enable = true` and `services.ai.local.enable = true`
- **THEN** LobeHub SHALL be included in `environment.systemPackages`

#### Scenario: AI enabled without local inference

- **WHEN** `services.ai.enable = true` and `services.ai.local.enable = false`
- **THEN** LobeHub SHALL NOT be included in `environment.systemPackages`
