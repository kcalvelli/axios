# Normie Profile — Delta

## MODIFIED Requirements

### Requirement: Normie profile excludes AI home modules

The normie profile SHALL NOT receive AI home-manager modules (claude-code, gemini, MCP servers, system prompts). User-facing AI desktop applications that do not depend on the AI home-manager stack MAY still be provided when they are intentionally included as normie applications.

#### Scenario: AI power-user tooling is not present for normie user

- **WHEN** a normie user's home-manager configuration is evaluated
- **THEN** `home/ai/` modules are NOT imported
- **AND** no Claude Code, Gemini CLI, or MCP server configuration is generated for this user
- **AND** the system-level AI module (`services.ai`) remains unchanged

#### Scenario: Normie user receives approved AI desktop applications

- **WHEN** a normie user's home-manager configuration is evaluated
- **THEN** approved user-facing desktop AI applications can be included without importing `home/ai/`
- **AND** those applications do not require the broader AI power-user workflow to be enabled

### Requirement: Normie profile retains core desktop features

The normie profile SHALL include the same visual polish, MIME associations, PWA apps, media playback, and approved user-facing desktop applications as the standard profile where those applications improve the non-technical user experience.

#### Scenario: Normie user has full application catalog

- **WHEN** a normie user opens the DMS app launcher
- **THEN** all default normie applications are available, including approved user-facing desktop AI applications such as ChatGPT
- **AND** desktop entries and launcher metadata are generated for those applications
- **AND** the applications appear without exposing AI power-user tooling

#### Scenario: Normie user launches ChatGPT desktop

- **WHEN** ChatGPT desktop is included for the normie workflow
- **THEN** the user can launch it from the normal application surface
- **AND** it behaves as a standalone desktop application rather than as part of the axios AI power-user stack
