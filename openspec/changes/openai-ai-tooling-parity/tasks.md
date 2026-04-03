## 1. AI Module Options And Packages

- [ ] 1.1 Add a `services.ai.openai` option namespace in `modules/ai/default.nix` parallel to the existing vendor toggles
- [ ] 1.2 Install `pkgs.codex` as the baseline OpenAI terminal agent when `services.ai.openai.enable = true`
- [ ] 1.3 Add explicit companion suboptions for selected `nixpkgs` OpenAI tools (at minimum evaluate `codex-acp` and `chatgpt`) and wire each enabled option to the corresponding package

## 2. Home Integration And Guidance

- [ ] 2.1 Add any stable OpenAI-specific home-manager configuration hooks that are supported declaratively by the selected tools without introducing brittle wrappers
- [ ] 2.2 Update AI-facing prompts, docs, or module reference text to describe OpenAI support, authentication expectations, and any prompt/configuration limitations
- [ ] 2.3 Document any worthwhile OpenAI ecosystem tools not available in `nixpkgs` as explicit follow-up considerations rather than first-pass dependencies

## 3. Validation

- [ ] 3.1 Run `nix fmt .` after the Nix changes
- [ ] 3.2 Evaluate or build the affected AI module paths to confirm the new OpenAI options resolve cleanly
