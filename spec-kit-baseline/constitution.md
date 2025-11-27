# Constitution

## Purpose
This document defines the non-negotiable rules, standards, and architectural constraints that govern the axiOS codebase. All changes must comply with these policies. This is a library/framework project, NOT a personal configuration.

## Code Style Standards

### Formatting
- **Formatter**: [EXPLICIT] nixfmt-rfc-style via treefmt-nix (evidence: flake.nix:149-152, .github/workflows/formatting.yml)
- **Enforcement**: CI check on all .nix files
- **Pre-commit Hook**: [REQUIRED] `nix fmt .` must be run before committing
- **Commands**:
  - `nix fmt .` - Format all Nix files (explicit directory target)
  - `./scripts/fmt.sh` - AI-safe helper script
  - `nix fmt -- --fail-on-change .` - Validate formatting without modifying (exits with error if changes needed)
  - `./scripts/fmt.sh --check` - Helper script validation mode
- **AI Tool Safety**: [EXPLICIT] Always use explicit `.` argument to avoid ambiguity
- **CI Validation**: Required on all PRs affecting .nix files

### Naming Conventions
- **Files**: [INFERRED] lowercase with hyphens (kebab-case)
  - Examples: `default.nix`, `init-config.sh`, `gdrive-sync.nix`
- **Modules**: [EXPLICIT] lowercase, directory-based (evidence: modules/default.nix)
  - Each module is a directory containing `default.nix`
  - Examples: `modules/desktop/`, `modules/networking/`
- **Options**: [EXPLICIT] camelCase for option names
  - Pattern: `config.MODULE_NAME.optionName`
  - Examples: `axios.system.timeZone`, `desktop.enable`
- **Variables**: [INFERRED] camelCase in let bindings
  - Pattern: `userCfg`, `cfg`, `homeModules`

### Linting Rules
- **Primary Linter**: nixfmt-rfc-style (Nix code formatter)
- **Critical Rules**:
  - Consistent indentation (2 spaces)
  - Proper attribute set formatting
  - Semicolon placement
- **No Additional Linters**: Standard Nix evaluation catches most errors

## Testing Requirements

### Test Framework Standards
- **Unit Tests**: None (typical for Nix projects - deterministic evaluation)
- **Integration Tests**: CI-based validation
- **Validation**: `nix flake check --all-systems`

### CI Test Requirements
All PRs must pass:
1. **flake-check**: Structure validation (`nix flake check --all-systems`)
2. **formatting**: Code style check (`nix fmt -- --check`)
3. **test-init-script**: Init script functionality
4. **build-devshells**: DevShell builds (optional, on devshell changes)

### Coverage Requirements
[ASSUMED] Not applicable for Nix - evaluation is deterministic

## Architecture & Tech Stack

### Architectural Style
[EXPLICIT] Modular Library/Framework Architecture (evidence: .claude/project.md)
- Provides reusable NixOS and home-manager modules
- Users import as flake input: `inputs.axios.nixosModules.<name>`
- No opinionated end-user configuration

### Approved Technologies
- **Languages**:
  - Nix (primary) - All system configuration
  - Bash (limited) - Helper scripts only (init-config.sh)
- **Frameworks**:
  - NixOS - Base system framework
  - home-manager - User environment management
  - flake-parts - Flake organization
- **Build Tools**:
  - Nix flakes - Primary build system
  - nixfmt-rfc-style - Code formatting
  - devshell - Development environments

### Architecture Decision Records

#### ADR-001: Module Structure Pattern
- **Pattern**: Directory-based modules with default.nix
- **Evidence**: modules/default.nix, .claude/project.md:60-66
- **Constraints**:
  - Each module MUST be a directory with `default.nix`
  - NO separate `applications.nix` files
  - Packages MUST be inline within `config = lib.mkIf cfg.enable { ... }` blocks
  - Additional .nix files in module directory are aspect files (e.g., `samba.nix`, `tailscale.nix`)
- **Confidence**: [EXPLICIT]

#### ADR-002: No Regional Defaults
- **Pattern**: User MUST explicitly configure locale-dependent settings
- **Evidence**: .claude/project.md:95-101
- **Constraints**:
  - `axios.system.timeZone` - NO DEFAULT, user must set
  - `axios.system.locale` - Defaults to en_US.UTF-8 but configurable
- **Rationale**: Library shouldn't hardcode regional preferences
- **Confidence**: [EXPLICIT]

#### ADR-003: Conditional Package Evaluation
- **Pattern**: Packages MUST be inside mkIf blocks
- **Evidence**: .claude/project.md:63-64, module examples
- **Constraints**:
  - NEVER import packages unconditionally
  - ALWAYS wrap packages in `config = lib.mkIf cfg.enable { ... }`
  - Prevents evaluation of disabled modules
- **Confidence**: [EXPLICIT]

#### ADR-004: System Reference Pattern
- **Pattern**: Use `pkgs.stdenv.hostPlatform.system` instead of `system`
- **Evidence**: .claude/project.md:124-134
- **Constraints**:
  - CORRECT: `inputs.foo.packages.${pkgs.stdenv.hostPlatform.system}.bar`
  - WRONG: `inputs.foo.packages.${system}.bar` (deprecated)
- **Confidence**: [EXPLICIT]

#### ADR-005: Calendar Versioning
- **Pattern**: YYYY.MM.DD versioning scheme
- **Evidence**: CHANGELOG.md:6, git tags (v2025.11.21, v2025.11.19, etc.)
- **Constraints**:
  - Version format: v<YEAR>.<MONTH>.<DAY>
  - Changelog follows Keep a Changelog format
- **Confidence**: [EXPLICIT]

#### ADR-006: Home-Manager Integration
- **Pattern**: Home modules mirror NixOS module structure
- **Evidence**: .claude/project.md:136-140
- **Constraints**:
  - Check system config with `osConfig.services.ai.enable or false`
  - Declarative MCP via `programs.claude-code.mcpServers`
  - Home modules follow same directory structure as NixOS modules
- **Confidence**: [EXPLICIT]

### Module Boundaries
- **Independence**: Modules are independently importable (no inter-module dependencies)
- **Composition**: Users compose modules in their own flake configurations
- **Isolation**: Each module is self-contained with its own options and configuration

### Data Flow Constraints
- **Unidirectional**: Configuration flows from user flake → axios modules → NixOS system
- **No State**: Modules are purely declarative (no runtime state)
- **Immutability**: Nix store is read-only, all changes require rebuild

## Process & Workflow

### Version Control Rules
- **Branch Strategy**: [ASSUMED] Trunk-based development (master branch)
- **Protected Branches**: master (inferred from CI workflows)
- **Pre-commit Hook**: [REQUIRED] `nix fmt .` must be run before committing
- **Commit Format**: [INFERRED] Descriptive commit messages, some follow Conventional Commits style
  - Recent commits show: "feat:", "fix:", "chore:", "refactor:" prefixes
- **No Force Push**: To master branch (assumed standard practice)

### Pull Request Requirements
- **Minimum Reviewers**: [TBD] Not explicitly configured
- **Required Checks**:
  1. Flake structure validation (flake-check)
  2. Code formatting (formatting)
  3. Init script test (if scripts/ changed)
  4. DevShell builds (if devshells/ changed)
- **Recommended Checks**:
  1. [TBD] No automated architectural reviews yet
- **Merge Strategy**: [TBD] Not explicitly documented

### CI/CD Pipeline Stages
1. **Validation Stage**:
   - Flake check (`nix flake check --all-systems`)
   - Code formatting check
   - Triggers: push to master, PRs
2. **Build Stage**:
   - DevShell builds (optional)
   - Example configuration builds (dry-run)
   - Triggers: path-specific changes
3. **Dependency Stage**:
   - Weekly flake.lock updates (Mondays 6 AM UTC)
   - Automated PR creation with validation
   - Manual approval required

### Deployment Rules
- **Environments**: N/A (library project - users deploy in their own configs)
- **Release Process**:
  1. Update CHANGELOG.md
  2. Create git tag (v<YEAR>.<MONTH>.<DAY>)
  3. Push tag to trigger GitHub release
  4. Users update flake.lock to pull new version

## Non-Negotiable Constraints

### Library Philosophy
[EXPLICIT] This is a library/framework, NOT a personal configuration:
- NO hardcoded personal preferences
- NO hardcoded regional defaults
- Users MUST have full control over configuration
- Modules MUST be independently optional

### Modular Independence
[EXPLICIT] All modules must be:
- Independently importable
- Self-contained with clear options
- Guarded by enable options
- Free of inter-module dependencies

### Backwards Compatibility
[ASSUMED] Breaking changes should be:
- Documented in CHANGELOG.md
- Versioned appropriately
- Communicated to users

### Performance
- [INFERRED] Module evaluation must be lazy (mkIf guards prevent unnecessary evaluation)
- Build caching via Cachix for faster downloads

### Compatibility
- **NixOS**: Follows nixpkgs unstable channel
- **Flake Support**: Required (this is a flake library)
- **System Support**: Primarily x86_64-linux (evidence: systems input)

## Configuration Management
- **Module Options**: Defined via `options.<module>.enable` pattern
- **Secrets Management**: [EXPLICIT] agenix for encrypted secrets
- **Feature Flags**: Via module enable options
- **Environment Variables**: Managed through NixOS configuration
- **Configuration Location**: User's downstream flake configuration

## Deprecation & Migration Policies
[INFERRED from CHANGELOG]
- Deprecated features are noted in CHANGELOG
- Migration guides provided for breaking changes
- Examples: removal of ollama module, file-roller enable option

## License & Legal
**Project License**: [EXPLICIT] MIT License
- **Copyright**: (c) 2023 Keith Calvelli
- **Terms**: Permissive open-source license
- **Commercial Use**: Allowed
- **Modification**: Allowed
- **Distribution**: Allowed
- **Sublicensing**: Allowed
- **Warranty**: None (AS-IS)
- **Liability**: Authors not liable
- **Requirement**: Must include license and copyright notice

**Evidence**: LICENSE file (root), README.md:98-99

**Implications for Contributors**:
- All contributions are under MIT License
- Contributors retain copyright but grant MIT permissions
- No CLA (Contributor License Agreement) required

## Unknowns
- [TBD] PR review process and requirements
- [TBD] Breaking change policy and communication strategy
- [TBD] Security vulnerability disclosure process
- [TBD] Contribution guidelines (CONTRIBUTING.md not found)
- [TBD] Code of conduct
- [TBD] Merge strategy (squash, rebase, or merge commits)
- [TBD] Branch naming conventions
- [TBD] Issue triage process
