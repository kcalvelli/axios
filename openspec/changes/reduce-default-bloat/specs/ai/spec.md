## MODIFIED Requirements

### Requirement: OpenAI ecosystem tooling parity

The AI module SHALL expose OpenAI ecosystem tooling at the same vendor-selection layer as Claude and Gemini. It SHALL provide a `services.ai.openai.enable` option and SHALL install a baseline OpenAI terminal agent from `nixpkgs` when that option is enabled. This addition SHALL preserve the existing Claude and Gemini paths. Claude and Gemini SHALL default to disabled, matching OpenAI's opt-in pattern.

#### Scenario: OpenAI vendor tooling is enabled

- **WHEN** a user sets `services.ai.enable = true` and `services.ai.openai.enable = true`
- **THEN** the evaluated system configuration includes the baseline OpenAI terminal agent package from `nixpkgs`
- **AND** the OpenAI tooling is selected through a dedicated `services.ai.openai` namespace rather than an ad hoc package list

#### Scenario: OpenAI vendor tooling is disabled

- **WHEN** a user leaves `services.ai.openai.enable = false`
- **THEN** the evaluated system configuration does not add the primary OpenAI terminal agent package
- **AND** existing Claude and Gemini behavior remains unchanged

#### Scenario: Claude vendor tooling is disabled by default

- **WHEN** a user sets `services.ai.enable = true` without setting `services.ai.claude.enable`
- **THEN** Claude Code, claude-desktop, claude-code-router, and claude-monitor are NOT installed
- **AND** the user MUST set `services.ai.claude.enable = true` to get Claude tooling

#### Scenario: Gemini vendor tooling is disabled by default

- **WHEN** a user sets `services.ai.enable = true` without setting `services.ai.gemini.enable`
- **THEN** gemini-cli-bin and antigravity are NOT installed
- **AND** the user MUST set `services.ai.gemini.enable = true` to get Gemini tooling

## ADDED Requirements

### Requirement: AI workflow tools are opt-in

The AI module SHALL expose a `services.ai.workflow.enable` option (default `false`) that controls installation of spec-driven development workflow tools. These tools SHALL NOT be installed by default when `services.ai.enable = true`.

#### Scenario: Workflow tools disabled by default

- **WHEN** a user sets `services.ai.enable = true` without setting `services.ai.workflow.enable`
- **THEN** `spec-kit` and `openspec` are NOT installed
- **AND** `whisper-cpp` remains installed (vendor-neutral, unconditional)

#### Scenario: Workflow tools explicitly enabled

- **WHEN** a user sets `services.ai.workflow.enable = true`
- **THEN** `spec-kit` and `openspec` are installed
- **AND** other AI ecosystem flags (claude, gemini, openai) are unaffected

### Requirement: claude-monitor is Claude-scoped

`claude-monitor` SHALL be installed only when `services.ai.claude.enable = true`. It SHALL NOT be installed as an unconditional AI tool.

#### Scenario: Claude enabled includes monitor

- **WHEN** a user sets `services.ai.claude.enable = true`
- **THEN** `claude-monitor` is installed alongside claude-code and related tools

#### Scenario: Claude disabled excludes monitor

- **WHEN** a user leaves `services.ai.claude.enable = false`
- **THEN** `claude-monitor` is NOT installed
- **AND** other AI tools (whisper-cpp) remain available if `services.ai.enable = true`

### Requirement: Minimal unconditional AI packages

When `services.ai.enable = true` and no ecosystem flags are set, only vendor-neutral tools SHALL be installed unconditionally.

#### Scenario: AI enabled with no ecosystems

- **WHEN** a user sets `services.ai.enable = true`
- **AND** all of `services.ai.claude.enable`, `services.ai.gemini.enable`, `services.ai.openai.enable`, and `services.ai.workflow.enable` are `false`
- **THEN** only `whisper-cpp` is installed
- **AND** no vendor-specific tools or workflow tools are present
