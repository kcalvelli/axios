## Context

The current AI module exposes vendor-level toggles for Claude and Gemini and installs their primary tooling directly from `modules/ai/default.nix`. OpenAI-oriented tooling exists in the locked `nixpkgs` set (`codex`, `codex-acp`, `chatgpt`, `chatgpt-cli`, `openai`), but axios does not currently surface those tools through `services.ai`, document how they fit into the AI workflow, or define how their configuration should relate to the existing system prompt and secrets conventions. This change adds OpenAI as an additional first-class vendor choice rather than replacing the existing Claude or Gemini paths.

This change is cross-cutting because it touches module options, package selection, home-manager integration, and the AI spec/documentation surface. The design needs to preserve axios's reproducibility goals while avoiding a new external flake dependency unless `nixpkgs` proves insufficient.

## Goals / Non-Goals

**Goals:**
- Add OpenAI ecosystem tooling to the `services.ai` interface at the same vendor-selection layer as Claude and Gemini.
- Prefer packages already present in the locked `nixpkgs` set, with `codex` as the initial OpenAI terminal agent candidate for this change.
- Define an implementation approach for companion OpenAI tools without forcing all of them into the default closure.
- Document authentication and prompt/configuration expectations in a way that matches existing axios patterns.

**Non-Goals:**
- Replacing Claude or Gemini as the default recommended workflow.
- Adding a new flake input for OpenAI tooling during the first implementation pass.
- Designing a bespoke secrets-management layer for OpenAI credentials.
- Guaranteeing full prompt auto-injection for every OpenAI package regardless of upstream support.

## Decisions

### Decision: Add a vendor namespace under `services.ai`

OpenAI support will be exposed as `services.ai.openai`, parallel to the existing `services.ai.claude` and `services.ai.gemini` toggles. This keeps vendor choice discoverable at the same configuration depth and avoids encoding OpenAI support as an implementation detail hidden behind miscellaneous package lists.

Rationale:
- Matches the mental model already established by the AI module.
- Gives the implementation a stable place for vendor-specific suboptions.
- Keeps future expansion possible without redesigning the option tree again.

Alternatives considered:
- Add OpenAI packages unconditionally when `services.ai.enable = true`: rejected because it increases closure size and surprises existing users.
- Add a generic `extraPackages` list only: rejected because it does not create ecosystem parity at the option level.

### Decision: Use `nixpkgs` packages as the first implementation source

The first implementation pass will use `codex` as the initial OpenAI terminal agent and treat `codex-acp` and `chatgpt` as explicit companion packages under suboptions. `chatgpt-cli`, `kardolus-chatgpt-cli`, and the Python `openai` client will not be baseline installs because they are lower-leverage wrappers or libraries rather than the closest parity match for existing vendor tooling.

Rationale:
- `codex` and `codex-acp` map most directly to axios's existing CLI-agent workflow.
- `chatgpt` desktop can be offered as an optional desktop-facing OpenAI client without making it part of the default AI package set.
- Staying within `nixpkgs` keeps builds reproducible and avoids expanding flake maintenance for the first pass.
- This decision is about package sourcing for the OpenAI addition, not about changing axios's overall vendor preference.

Alternatives considered:
- Add all OpenAI-related `nixpkgs` packages by default: rejected as noisy and hard to justify.
- Add a new external OpenAI flake immediately: rejected because the repository already has viable `nixpkgs` candidates.

### Decision: Keep configuration declarative where possible, and document the rest

Implementation will follow the same pattern used elsewhere in axios: package installation and any supported environment/config file setup are declarative; credentials remain user-managed, preferably via `agenix`-backed environment exposure where practical. If a selected OpenAI tool does not expose a stable declarative prompt/config hook, axios will document that limitation rather than inventing brittle wrappers.

Rationale:
- Preserves reproducibility without overpromising unsupported integration.
- Aligns with existing AI guidance, where provider-specific authentication varies by vendor.
- Avoids binding axios to reverse-engineered config internals that may churn quickly.

Alternatives considered:
- Create wrapper scripts that emulate unsupported prompt/config behavior: rejected unless implementation proves the upstream surface is stable enough.
- Require manual installation outside Nix: rejected because it defeats the parity goal.

## Risks / Trade-offs

- [OpenAI CLI surface changes quickly] → Prefer direct `nixpkgs` packages and keep wrappers minimal so updates remain low-risk.
- [New vendor options may increase module complexity] → Scope the first pass to one vendor namespace with a small number of suboptions.
- [Prompt/config integration may differ from Claude/Gemini] → Specify parity at the option and documentation level, not guaranteed identical internals.
- [Default package closure could grow too much] → Keep companion tools opt-in under `services.ai.openai`.

## Migration Plan

No mandatory migration is required for existing users because current Claude and Gemini behavior remains unchanged. Users who want OpenAI tooling will opt in through the new `services.ai.openai` options. If any documentation currently implies Anthropic-first defaults, it will be updated to describe vendor choice more neutrally.

## Open Questions

- Whether `chatgpt` desktop belongs in the initial implementation or should remain a documented optional follow-up if its desktop integration feels out of scope during coding.
- Whether any selected OpenAI tool exposes a stable prompt-file or environment-variable hook worth managing declaratively in `home/ai/`.
