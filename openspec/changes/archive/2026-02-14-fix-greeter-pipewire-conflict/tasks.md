## 1. Implementation

- [x] 1.1 Add `ConditionUser` overrides to `pipewire.socket` and `pipewire-pulse.socket` in `modules/desktop/default.nix`, excluding `root` and `greeter` users
- [x] 1.2 Run `nix fmt .` to format the changes

## 2. Validation

- [x] 2.1 Run `nix flake check --all-systems` to verify the flake builds correctly
