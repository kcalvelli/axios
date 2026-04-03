## 1. Update flake.nix wrapper

- [x] 1.1 Add gum and all dependencies to PATH via `pkgs.lib.makeBinPath`
- [x] 1.2 Pass `"$@"` to script for --help flag support
- [x] 1.3 Update meta.description

## 2. Rewrite script preamble and utilities

- [x] 2.1 Add `--help` / `-h` handler with usage text (exits 0)
- [x] 2.2 Add gum prerequisite check
- [x] 2.3 Add Ctrl-C trap for clean exit
- [x] 2.4 Add gum wrapper functions: banner, section_header, info_box, ask_input, ask_confirm, ask_choose, ask_multi

## 3. Refactor hardware detection

- [x] 3.1 Wrap detection logic in `detect_hardware()` function
- [x] 3.2 Display results in styled info_box instead of raw echo
- [x] 3.3 Fix laptop detection glob (use compgen instead of bare glob in test)

## 4. Implement startup mode selection

- [x] 4.1 Banner display with gum style
- [x] 4.2 Mode chooser: "New configuration" / "Add host to existing config"
- [x] 4.3 Route to appropriate flow function

## 5. Implement Mode A (new configuration)

- [x] 5.1 Hardware detection → system info → primary user → additional users → features → summary
- [x] 5.2 Flat multi-select for features (replaces nested virt questions)
- [x] 5.3 Generate all files using shared generation functions
- [x] 5.4 Auto git init + commit

## 6. Implement Mode B (add host to existing config)

- [x] 6.1 Prompt for git URL, clone to ~/.config/nixos_config
- [x] 6.2 Validate flake.nix exists, scan hosts/*.nix and users/*.nix
- [x] 6.3 Display existing hosts/users in info box
- [x] 6.4 Collect new host info (hostname with duplicate check)
- [x] 6.5 User assignment from existing users via multi-select + create-new option
- [x] 6.6 Features, summary, confirm
- [x] 6.7 Generate host files + insert into flake.nix (find last mkHost line)
- [x] 6.8 Auto git commit

## 7. Shared generation functions

- [x] 7.1 `generate_user_file()` — template sed substitution
- [x] 7.2 `generate_host_files()` — host config + hardware config (with gum spin)
- [x] 7.3 `generate_secrets_dir()` — conditional secrets directory creation
- [x] 7.4 `compute_derived()` — IS_LAPTOP, HOME_PROFILE, USERS_LIST, etc.

## 8. Rewrite OpenSpec artifacts

- [x] 8.1 Rewrite proposal.md to match gum + dual-mode implementation
- [x] 8.2 Rewrite design.md with actual decisions and architecture
- [x] 8.3 Rewrite spec.md with correct requirements and scenarios
- [x] 8.4 Rewrite tasks.md (this file) with actual task breakdown

## 9. Verification

- [x] 9.1 `nix run .#init -- --help` prints usage and exits 0
- [x] 9.2 `nix flake check` passes
- [x] 9.3 `nix fmt .` passes
