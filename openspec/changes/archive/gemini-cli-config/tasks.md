# Tasks for Gemini CLI Configuration (Revised)

1.  **Analyze the current `gemini` configuration:**
    *   [x] Search for `gemini` in the repository.
    *   [x] Analyze `home/ai/mcp.nix`.
    *   [x] Analyze `modules/ai/default.nix`.
    *   [x] Analyze `home/terminal/fish.nix`.
    *   [x] Conclude that the current configuration is incorrect and relies on an external script.

2.  **Propose a declarative `gemini-cli` configuration (Initial Proposal - Incorrect):**
    *   [x] Create a `proposal.md` to explain the new approach.
    *   [x] The proposal should recommend using `home.file` to create `~/.gemini/settings.json`.
    *   [x] The API key should be managed by `agenix`.

3.  **Implement the new configuration (Initial Implementation - Incorrect):**
    *   [x] Modify `home/ai/mcp.nix` to add the `home.file` block for `~/.gemini/settings.json`.
    *   [x] Modify `home/terminal/fish.nix` to remove the `axios-gemini` alias and replace it with a direct alias to `gemini-cli`.

4.  **Correct the implementation based on new information about OAuth:**
    *   [x] Revert the changes in `home/ai/mcp.nix` that added `settings.json` and `GEMINI_API_KEY`.
    *   [x] Keep the `GEMINI_SYSTEM_MD` environment variable configuration.
    *   [x] The `fish.nix` change to use `gemini-cli` directly is still correct.

5.  **Update documentation:**
    *   [x] Update `openspec/specs/ai/spec.md` to reflect the correct OAuth authentication method.
    *   [x] Update `proposal.md` to reflect the revised understanding and solution.
    *   [x] Update this `tasks.md` file.