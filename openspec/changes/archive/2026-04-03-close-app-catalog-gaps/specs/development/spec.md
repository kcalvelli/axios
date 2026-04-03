## ADDED Requirements

### Requirement: Database CLI Clients

The development module SHALL include lightweight database CLI clients for interactive querying.

#### Scenario: PostgreSQL querying with pgcli

- **WHEN** user enables `development.enable = true`
- **THEN** `pgcli` SHALL be installed
- **AND** the user SHALL be able to connect to PostgreSQL databases with auto-completion and syntax highlighting

#### Scenario: SQLite querying with litecli

- **WHEN** user enables `development.enable = true`
- **THEN** `litecli` SHALL be installed
- **AND** the user SHALL be able to query SQLite databases with the same UX as pgcli

### Requirement: HTTP API Testing CLI

The development module SHALL include a modern HTTP client for API testing from the terminal.

#### Scenario: API testing with httpie

- **WHEN** user enables `development.enable = true`
- **THEN** `httpie` SHALL be installed
- **AND** the user SHALL be able to make HTTP requests with `http` and `https` commands
- **AND** response bodies SHALL be syntax-highlighted by default

### Requirement: Structural Diff Tool

The development module SHALL include an AST-aware diff tool for language-specific structural comparisons.

#### Scenario: Structural diff with difftastic

- **WHEN** user enables `development.enable = true`
- **THEN** `difftastic` SHALL be installed
- **AND** the user SHALL be able to run `difft` to compare files with language-aware structural diffing

### Requirement: System and Network Diagnostic CLI Tools

The development module SHALL include modern system monitoring and network diagnostic tools.

#### Scenario: System monitoring with btop

- **WHEN** user enables `development.enable = true`
- **THEN** `btop` SHALL be installed
- **AND** the user SHALL be able to monitor CPU, memory, disk, and network usage via the `btop` command

#### Scenario: Network path analysis with mtr

- **WHEN** user enables `development.enable = true`
- **THEN** `mtr` SHALL be installed
- **AND** the user SHALL be able to diagnose network paths combining traceroute and ping functionality

#### Scenario: DNS lookup with dog

- **WHEN** user enables `development.enable = true`
- **THEN** `dog` SHALL be installed
- **AND** the user SHALL be able to perform DNS lookups with colored, human-readable output via the `dog` command
