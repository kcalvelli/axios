## MODIFIED Requirements

### Requirement: Core Tooling

The development module SHALL provide development-specific packages that are NOT already managed by home-manager `programs.*` declarations. CLI tools with home-manager program modules (eza, fzf, gh, fish, starship) and neovim (configured via `home/terminal/neovim/`) MUST NOT be duplicated in the system package list.

The development module SHALL include: Visual Studio Code, Bun, mitmproxy, k6, devenv, nil, bat, jq, pgcli, litecli, httpie, difftastic, dog, and wrangler.

The development module SHALL NOT include: neovim, starship, fish, eza, fzf, gh, btop, or mtr — these are provided by home-manager programs or other modules.

#### Scenario: Development module packages do not duplicate home-manager tools
- **WHEN** `development.enable = true`
- **THEN** `environment.systemPackages` MUST NOT contain eza, fzf, gh, fish, starship, or neovim
- **AND** these tools SHALL still be available to users via home-manager `programs.*` declarations

#### Scenario: Development module retains development-specific packages
- **WHEN** `development.enable = true`
- **THEN** `environment.systemPackages` MUST contain bat, jq, difftastic, dog, and other development-specific tools not managed by home-manager

#### Scenario: mtr not duplicated with networking module
- **WHEN** `development.enable = true`
- **THEN** `environment.systemPackages` MUST NOT contain mtr
- **AND** mtr SHALL be provided by the networking module's `programs.mtr.enable`
