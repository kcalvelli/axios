# AI & Development Assistance — Delta

## ADDED Requirements

### Requirement: OpenAI ecosystem tooling parity
The AI module SHALL expose OpenAI ecosystem tooling at the same vendor-selection layer as Claude and Gemini. It SHALL provide a `services.ai.openai.enable` option and SHALL install a baseline OpenAI terminal agent from `nixpkgs` when that option is enabled. This addition SHALL preserve the existing Claude and Gemini paths.

#### Scenario: OpenAI vendor tooling is enabled
- **WHEN** a user sets `services.ai.enable = true` and `services.ai.openai.enable = true`
- **THEN** the evaluated system configuration includes the baseline OpenAI terminal agent package from `nixpkgs`
- **AND** the OpenAI tooling is selected through a dedicated `services.ai.openai` namespace rather than an ad hoc package list

#### Scenario: OpenAI vendor tooling is disabled
- **WHEN** a user leaves `services.ai.openai.enable = false`
- **THEN** the evaluated system configuration does not add the primary OpenAI terminal agent package
- **AND** existing Claude and Gemini behavior remains unchanged

### Requirement: OpenAI companion tools remain explicit choices
The AI module SHALL expose additional OpenAI ecosystem tools from `nixpkgs` as explicit companion choices under `services.ai.openai`, rather than installing every available OpenAI-related package by default. User-facing desktop applications that are intentionally provided outside the AI workflow are not required to hang off this namespace.

#### Scenario: Companion tools are not installed implicitly
- **WHEN** a user enables `services.ai.openai.enable = true` without enabling any companion suboptions
- **THEN** only the baseline OpenAI tooling defined by the module is installed
- **AND** optional companion tools remain absent from the evaluated package set

#### Scenario: Companion tools can be enabled declaratively
- **WHEN** a user enables an OpenAI companion suboption exposed by the module
- **THEN** the corresponding `nixpkgs` package is added to the evaluated configuration
- **AND** the package is selected without requiring an additional flake input

#### Scenario: ChatGPT PWA can exist outside the AI module
- **WHEN** axios provides ChatGPT through a non-AI user workflow such as the normie profile
- **THEN** that application is not required to depend on `services.ai.openai.enable`
- **AND** the broader AI CLI and MCP tooling remain separately scoped

### Requirement: OpenAI tooling guidance is documented
axios SHALL document the supported OpenAI tools, their authentication expectations, and any prompt/configuration integration limitations alongside the existing AI tooling guidance.

#### Scenario: Authentication requirements are discoverable
- **WHEN** a user reads the AI module documentation or spec-backed guidance for OpenAI tooling
- **THEN** the documentation explains how the selected OpenAI tools authenticate
- **AND** any recommended secret handling follows existing axios guidance rather than introducing a separate credential system

#### Scenario: Unsupported declarative hooks are called out
- **WHEN** an OpenAI tool does not support stable declarative prompt or config injection
- **THEN** axios documents that limitation explicitly
- **AND** the implementation does not rely on undocumented or brittle wrapper behavior
