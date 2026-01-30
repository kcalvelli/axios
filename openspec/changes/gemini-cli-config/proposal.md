# Proposal: Declarative Gemini CLI Configuration (Revised)

## Problem

The initial investigation into `gemini-cli`'s failures revealed a reliance on an external `axios-gemini` script, which was not part of the `axiOS` repository. The initial proposed solution was to manage the `gemini-cli` API key declaratively using `agenix`.

**This was incorrect.**

Further information has clarified that for **Google AI Pro** accounts, using an API key bypasses the Pro subscription, falling back to the free tier. The correct authentication method for Pro users is the **OAuth login flow** (`gemini auth login`).

## Revised Proposed Solution: Support OAuth Flow

To align with the correct authentication method for Pro users, we will not manage API keys for `gemini-cli`. Instead, we will ensure that the environment is set up correctly for the user to perform the OAuth login themselves, and we will continue to manage the system prompt declaratively.

### Changes

1.  **Remove API Key Management:**
    *   The `home.file` block that created `~/.gemini/settings.json` with an API key has been removed from `home/ai/mcp.nix`.
    *   The `GEMINI_API_KEY` environment variable has been removed from the configuration.

2.  **Keep System Prompt Management:**
    *   The `GEMINI_SYSTEM_MD` environment variable is still set via `home.sessionVariables` in `home/ai/mcp.nix`, ensuring a consistent system prompt.

3.  **Update Documentation:**
    *   `openspec/specs/ai/spec.md` has been updated to reflect that `gemini-cli` uses OAuth for Pro accounts and that API keys are not the recommended method for these users.

### Benefits of the Revised Approach

*   **Correct Authentication:** Users with Google AI Pro subscriptions will correctly authenticate and get access to their paid features and limits.
*   **Simplicity:** The configuration is now simpler, as it removes the need for `agenix` secrets for `gemini-cli`.
*   **Clarity:** The documentation now provides accurate information about `gemini-cli` authentication.

## User Instructions

Users will be instructed to run `gemini auth login` one time to authenticate with their Google AI Pro account. No further configuration is needed.