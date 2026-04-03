## 1. AI Module Options And Packages

- [ ] 1.1 Add a `services.ai.openai` option namespace in `modules/ai/default.nix` parallel to the existing vendor toggles
- [ ] 1.2 Install `pkgs.codex` as the baseline OpenAI terminal agent when `services.ai.openai.enable = true`
- [ ] 1.3 Add an explicit companion suboption for `codex-acp` under `services.ai.openai` and wire it to the corresponding `nixpkgs` package

## 2. Home Integration And Guidance

- [ ] 2.1 Add stable OpenAI-specific home-manager configuration only where the selected CLI tools expose supported declarative hooks; otherwise document the absence of those hooks
- [ ] 2.2 Update concrete documentation targets for OpenAI support, authentication expectations, and prompt/configuration limitations in the relevant AI/module docs
- [ ] 2.3 Document any worthwhile OpenAI ecosystem tools not available in `nixpkgs` as explicit follow-up considerations rather than first-pass dependencies

## 3. Normie Workflow Integration

- [ ] 3.1 Add `chatgpt` desktop to the appropriate normie-facing application surface without importing `home/ai/`
- [ ] 3.2 Update normie-facing documentation/spec-backed behavior so ChatGPT desktop is treated as an approved standalone application rather than AI power-user tooling

## 4. Validation

- [ ] 4.1 Run `nix fmt .` after the Nix changes
- [ ] 4.2 Evaluate or build the affected AI and normie profile paths to confirm the new options resolve cleanly
