## Why

The AI module currently presents Anthropic and Gemini tooling as first-class choices while OpenAI-oriented workflows are either absent or only available through generic browser access. That creates an avoidable ecosystem bias in a module that is supposed to expose reusable, vendor-neutral AI tooling choices.

## What Changes

- Add OpenAI ecosystem tooling to the `services.ai` module at the same decision level as the existing Claude and Gemini toggles, while keeping the existing vendors available unchanged.
- Prefer OpenAI-related packages already available in `nixpkgs` as the package source for this addition, including any required home-manager or prompt integration needed to make them usable after rebuild.
- Keep ChatGPT in the first-pass implementation as a user-facing OpenAI PWA, and make it available to the normie workflow independently of `services.ai.enable`.
- Document and gate any OpenAI ecosystem additions that are not in `nixpkgs` behind a clear justification so the default implementation remains low-friction and reproducible.
- Update AI-facing documentation and requirements so supported vendors, authentication expectations, and prompt/configuration behavior are explicit.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `ai`: Expand the AI module and user-facing AI requirements so OpenAI ecosystem tooling is offered alongside Claude and Gemini with comparable enablement, configuration, and documentation expectations, without replacing or de-emphasizing the existing vendors.
- `normie-profile`: Allow user-facing OpenAI PWA access where it adds value for non-power users, without importing the broader AI power-user home modules into the normie profile.

## Impact

- Affected code: [`modules/ai/default.nix`](/home/keith/Projects/axios/modules/ai/default.nix), normie profile and desktop modules under [`home/`](/home/keith/Projects/axios/home), and AI-related documentation.
- Affected behavior: package selection, tool enablement options, prompt/configuration injection, supported vendor guidance for AI tooling, and the default application set available to normie users.
- Dependencies: primarily `nixpkgs` packages, with optional follow-up evaluation for external OpenAI ecosystem tooling only if the package gap is material.
