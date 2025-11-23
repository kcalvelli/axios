# axiOS Spec-Kit Baseline Documentation

**Generated**: 2025-11-21
**Repository**: https://github.com/kcalvelli/axios
**Purpose**: Comprehensive reverse-engineered baseline documentation for GitHub Spec Kit workflow

## Document Overview

This directory contains 8 foundational documents that fully describe the axiOS project's current state, architecture, and operational characteristics:

### Core Documents

1. **[discovery-report.md](discovery-report.md)** (8.7 KB)
   - Repository reconnaissance findings
   - Technology stack inventory
   - Module structure overview
   - Entry points and APIs
   - Change history analysis

2. **[constitution.md](constitution.md)** (8.8 KB)
   - Non-negotiable rules and standards
   - Code style and formatting (nixpkgs-fmt)
   - Module architecture patterns
   - Testing and CI requirements
   - Architecture decision records (ADRs)

3. **[spec.md](spec.md)** (20 KB)
   - Current features and capabilities
   - User types and personas
   - User journeys and workflows
   - API surface documentation
   - Acceptance criteria

4. **[plan.md](plan.md)** (19 KB)
   - Technical architecture overview
   - Module breakdown and dependencies
   - Data architecture and storage
   - Build and deployment processes
   - Infrastructure and operations

5. **[runbook.md](runbook.md)** (12 KB)
   - Development environment setup
   - Build and run procedures
   - Testing and debugging guides
   - Deployment and release process
   - Maintenance operations

6. **[concerns.md](concerns.md)** (16 KB)
   - Security patterns (auth, secrets, validation)
   - Performance strategies (caching, optimization)
   - Error handling and resilience
   - Compliance and governance
   - Observability and monitoring

7. **[glossary.md](glossary.md)** (19 KB)
   - Domain terminology (axiOS-specific)
   - Technical terminology (Nix/NixOS)
   - Acronyms and abbreviations
   - Deprecated terms
   - Common code abbreviations

8. **[unknowns.md](unknowns.md)** (15 KB)
   - Items requiring human review
   - Critical blockers
   - Configuration gaps
   - Operational uncertainties
   - Prioritized action items

## Quick Navigation

**For New Developers**: Start with discovery-report.md → constitution.md → spec.md
**For Contributors**: Read constitution.md → runbook.md → concerns.md
**For Users**: Read spec.md → glossary.md
**For Maintainers**: Review unknowns.md for documentation gaps

## Document Statistics

- **Total Size**: 128 KB
- **Documentation Coverage**: ~75% confidence
- **Unknowns Tracked**: 50+ items categorized
- **Confidence Markers**: [EXPLICIT], [INFERRED], [ASSUMED], [TBD]
- **Evidence Links**: File paths and line numbers throughout

## Key Findings

### Architecture
- **Type**: Nix Flake Library / Framework
- **Pattern**: Modular, independently importable components
- **Philosophy**: Library (not personal config) - no hardcoded preferences
- **Versioning**: Calendar versioning (YYYY.MM.DD)

### Critical Constraints
1. **No Regional Defaults**: Users MUST set timezone explicitly
2. **Conditional Evaluation**: All packages inside `mkIf` blocks
3. **Module Independence**: No inter-module dependencies
4. **Directory-Based Modules**: Consistent structure pattern

### Technology Stack
- **Primary Language**: Nix (100%)
- **Package Manager**: Nix flakes
- **Desktop**: Niri + DankMaterialShell
- **AI Integration**: MCP servers, claude-code, copilot-cli
- **Self-Hosted**: Immich, Caddy, Tailscale

### Most Critical Unknown
**LICENSE information not verified** - Required for legal compliance (HIGH priority)

## Confidence Assessment

| Aspect | Confidence | Status |
|--------|-----------|--------|
| Module Structure | 95% | ✓ Well understood |
| Code Standards | 95% | ✓ Documented and enforced |
| Core Features | 85% | ✓ Main features clear |
| Architecture | 90% | ✓ Patterns documented |
| Operations | 70% | ⚠ Some procedures unclear |
| Security | 65% | ⚠ Audit needed |
| Testing | 60% | ⚠ Limited beyond CI |
| Performance | 50% | ⚠ No benchmarks |

## Maintenance

These baseline documents should be:
1. **Kept in sync** with code changes
2. **Updated** when architectural decisions change
3. **Enhanced** as operational knowledge grows
4. **Used as foundation** for all new spec-driven work

## Integration with GitHub Spec Kit

These documents are ready for:
- `specify` command workflows
- Feature specification references
- Architecture decision records
- AI agent code modification guidance

## Next Steps

See [unknowns.md](unknowns.md) for prioritized action items. High priority:
1. Verify LICENSE and document terms
2. Complete security audit
3. Create CONTRIBUTING.md
4. Document per-module package lists
5. Establish performance benchmarks

## Contributing

[TBD] - See unknowns.md for contribution process gap

## Questions?

Refer to:
- **Terminology**: [glossary.md](glossary.md)
- **Operations**: [runbook.md](runbook.md)
- **Patterns**: [concerns.md](concerns.md)
- **Gaps**: [unknowns.md](unknowns.md)
