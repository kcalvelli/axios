## ADDED Requirements

### Requirement: Local LLM Chat UI

The AI module SHALL provide a desktop chat UI for interacting with local LLM models when the local inference stack is enabled.

#### Scenario: LobeHub installed with local AI stack

- **WHEN** `services.ai.enable = true` and `services.ai.local.enable = true`
- **THEN** LobeHub desktop application SHALL be installed
- **AND** the application SHALL be launchable from the Fuzzel application launcher
- **AND** the application SHALL connect to the local Ollama instance for inference

#### Scenario: LobeHub not installed without local AI stack

- **WHEN** `services.ai.enable = true` and `services.ai.local.enable = false`
- **THEN** LobeHub SHALL NOT be installed
- **AND** no additional closure size SHALL be added for the chat UI
