# Unknowns & Questions

## Purpose
This document consolidates all items marked as `[TBD]` or unclear during reverse engineering. These require human review and input before the baseline is considered complete.

## Critical Unknowns
[Items that block full understanding of the system]

### Testing Strategy
- **Question**: How should module interactions be tested beyond `nix flake check`?
- **Context**: No test infrastructure found beyond CI validation
- **Impact**: Cannot verify module interactions or edge cases
- **Source**: constitution.md, runbook.md
- **Recommendation**: Consider NixOS VM tests for integration testing

### License Information
- **Question**: What is the project license?
- **Context**: LICENSE file existence not verified during reconnaissance
- **Impact**: Cannot determine usage rights and obligations
- **Source**: discovery-report.md, constitution.md
- **Priority**: HIGH - Required for legal compliance

### Contribution Guidelines
- **Question**: What is the process for contributing to the project?
- **Context**: CONTRIBUTING.md not found
- **Impact**: Contributors don't know how to submit changes
- **Source**: discovery-report.md, constitution.md
- **Priority**: MEDIUM - Important for community growth

## Configuration Unknowns
[Missing or unclear configuration details]

### Immich Database Configuration
- **Question**: What database is used and how is it configured?
- **Current State**: Assumed PostgreSQL based on typical Immich deployment
- **Needed Info**: Connection pooling, backup strategy, performance tuning
- **Source**: plan.md, concerns.md

### Caddy Security Headers
- **Question**: What security headers are configured?
- **Current State**: Assumed Caddy defaults
- **Needed Info**: Explicit headers (HSTS, CSP, X-Frame-Options, etc.)
- **Source**: concerns.md

### systemd Service Restart Policies
- **Question**: What are the restart policies for each service?
- **Current State**: Assumed standard on-failure
- **Needed Info**: Per-service restart configuration, limits, delays
- **Source**: concerns.md

### Rate Limiting
- **Question**: Are there rate limits on services?
- **Current State**: Not explicitly configured
- **Needed Info**: Caddy rate limiting, Immich API limits
- **Source**: concerns.md

## Architecture Unknowns
[Unclear architectural decisions or patterns]

### Module Package Inventories
- **Question**: What is the complete list of packages in each module?
- **Evidence**: Only sampled modules/desktop/default.nix
- **Hypothesis**: Each module has 10-50 packages
- **Verification**: Read each module default.nix and aspect files
- **Source**: discovery-report.md, spec.md, plan.md

### Virtualization Module Specifics
- **Question**: Does virtualization module use Podman, Docker, or both?
- **Evidence**: modules/virtualisation/ exists but not analyzed in detail
- **Impact**: Affects container workflow documentation
- **Source**: spec.md, plan.md

### Gaming Module Package List
- **Question**: What gaming packages and optimizations are included?
- **Evidence**: modules/gaming/ exists but not analyzed
- **Impact**: Cannot document gaming feature set
- **Source**: spec.md, plan.md

### Browser Module Configuration
- **Question**: Which browser(s) and what configuration?
- **Evidence**: home/browser/ exists but not analyzed
- **Impact**: Cannot document browser capabilities
- **Source**: spec.md, plan.md

### Calendar Module Integration
- **Question**: What calendar system and integration details?
- **Evidence**: home/calendar/ exists but not analyzed
- **Impact**: Cannot document calendar features
- **Source**: spec.md, plan.md

### Security Module Features
- **Question**: What security tools and configuration?
- **Evidence**: home/security/ exists but not analyzed
- **Impact**: Cannot document security tooling
- **Source**: spec.md, plan.md

## Operational Unknowns
[Unclear operational procedures]

### Backup and Restore Procedures
- **Question**: What is the recommended backup strategy?
- **Impact**: Users don't know how to protect their data
- **Workaround**: Users responsible for their own backups
- **Source**: plan.md, concerns.md

### Disaster Recovery Plan
- **Question**: How to recover from complete system failure?
- **Impact**: Users may lose data or systems
- **Workaround**: NixOS generations provide some rollback capability
- **Source**: plan.md, concerns.md

### Secret Rotation Procedures
- **Question**: How should secrets be rotated?
- **Impact**: Security best practice not documented
- **Workaround**: Manual re-encryption with agenix
- **Source**: concerns.md

### VM Testing Procedures
- **Question**: How to test modules in VMs before deploying?
- **Impact**: No safe testing environment documented
- **Workaround**: Mentioned in runbook but not detailed
- **Source**: runbook.md

### Performance Benchmarks
- **Question**: What are expected performance characteristics?
- **Impact**: Cannot identify performance regressions
- **Source**: plan.md, concerns.md

### Health Check Implementations
- **Question**: Are there health check scripts for services?
- **Impact**: Cannot monitor service health proactively
- **Source**: concerns.md

## Domain Knowledge Gaps
[Business logic or domain concepts that aren't clear from code]

### Target User Base Size
- **Question**: How many users is axiOS designed for?
- **Context**: Library project, but scale unclear
- **SME Needed**: Project maintainer
- **Source**: Inferred from code, not explicit

### Production Deployment Patterns
- **Question**: What are typical downstream usage patterns?
- **Context**: Library used by others, but how?
- **SME Needed**: User testimonials or case studies
- **Source**: discovery-report.md

### Module Interaction Patterns
- **Question**: Are there recommended module combinations?
- **Context**: Modules are independent, but some may work better together
- **SME Needed**: Project maintainer or experienced users
- **Source**: Inferred from module structure

## Data Model Uncertainties
[Unclear aspects of data model]

### Immich Database Schema
- **Question**: What is the database schema and migration strategy?
- **Tables/Fields**: Unknown
- **Impact**: Cannot document data model or plan migrations
- **Source**: plan.md

### MCP Server State Storage
- **Question**: Where do MCP servers store state?
- **Context**: Some servers may maintain cache or state
- **Impact**: Affects data management and cleanup
- **Source**: spec.md (MCP server details)

### systemd Service Dependencies
- **Question**: What are the complete dependency graphs?
- **Context**: Some services depend on others
- **Impact**: Affects startup order and reliability
- **Source**: plan.md, concerns.md

## Integration Uncertainties
[Unclear external system interactions]

### Google Drive API Limits
- **Question**: What are the API rate limits and quotas?
- **System**: Google Drive (via rclone)
- **Risk**: Sync failures if limits exceeded
- **Source**: spec.md (Google Drive sync)

### Tailscale Certificate Expiration
- **Question**: How often do certs renew and what's the failure mode?
- **System**: Tailscale TLS certificates
- **Risk**: Service outage if cert renewal fails
- **Source**: concerns.md

### GitHub API Rate Limits
- **Question**: How are GitHub API limits handled by MCP server?
- **System**: GitHub MCP server
- **Risk**: MCP server failures during development
- **Source**: spec.md (MCP servers)

## Test Coverage Gaps
[Areas where test behavior is unclear or missing]

### Module Interaction Tests
- **Question**: How are interactions between modules tested?
- **Area**: Desktop + AI + Networking combinations
- **Risk**: Medium - Modules designed to be independent, but may interact
- **Source**: constitution.md

### DevShell Tests
- **Question**: Are DevShells tested for completeness?
- **Area**: rust, zig, qml environments
- **Risk**: Low - Isolated environments
- **Source**: discovery-report.md

### Init Script Edge Cases
- **Question**: Is init script tested with all module combinations?
- **Area**: Configuration generator
- **Risk**: Medium - Critical first-user experience
- **Source**: runbook.md

### Secrets Integration Tests
- **Question**: How is agenix integration tested?
- **Area**: Secrets management across modules
- **Risk**: Medium - Security-critical functionality
- **Source**: spec.md (secrets)

## Ambiguous Patterns
[Places where multiple patterns exist and correct approach is unclear]

### Module Import Location
- **Pattern A**: Import in flake.nix
- **Pattern B**: Import in configuration.nix
- **Question**: Which is the recommended pattern for users?
- **Recommendation**: Document both with use cases
- **Source**: Inferred from examples

## Deprecated/Legacy Code
[Old patterns that may need migration]

### Custom Immich Package
- **Description**: Temporary v2.3.1 package while nixpkgs lags
- **Evidence**: pkgs/immich/, CHANGELOG.md
- **Question**: When will nixpkgs update? What's the removal timeline?
- **Source**: spec.md, concerns.md

### System Reference Pattern
- **Description**: Old `${system}` pattern deprecated
- **Evidence**: .claude/project.md documents correct pattern
- **Question**: Are there any remaining uses of old pattern?
- **Source**: constitution.md ADR-004

## Missing Documentation
[Documentation that should exist but doesn't]

### Per-Module READMEs
- **Type**: Module documentation
- **Topic**: Each module's purpose, options, and usage
- **Priority**: Medium
- **Impact**: Users must read code to understand modules
- **Source**: concerns.md (anti-patterns)

### API Documentation
- **Type**: Library function documentation
- **Topic**: Functions in lib/
- **Priority**: Medium
- **Impact**: Unclear how to use library helpers
- **Source**: discovery-report.md

### Deployment Guide
- **Type**: User documentation
- **Topic**: How downstream users deploy axiOS-based systems
- **Priority**: Medium
- **Impact**: Users may misunderstand deployment model
- **Source**: discovery-report.md

### Troubleshooting Guide
- **Type**: Runbook
- **Topic**: Per-module troubleshooting steps
- **Priority**: Low
- **Impact**: Harder to debug module issues
- **Source**: runbook.md

### Architecture Decision Records
- **Type**: ADR documentation
- **Topic**: Detailed rationale for architectural choices
- **Priority**: Low
- **Impact**: Future developers may not understand design decisions
- **Source**: constitution.md (has some ADRs inline, but could be expanded)

## Security Gaps
[Security-related items that need clarification]

### PII in Logs
- **Question**: Is PII logged by any services?
- **Risk Level**: High - Privacy violation
- **Verification Needed**: Audit systemd journal logs from each service
- **Source**: concerns.md

### Secrets in Git History
- **Question**: Have secrets ever been committed?
- **Risk Level**: Critical
- **Verification Needed**: Git history audit
- **Source**: Security best practice

### Certificate Pinning
- **Question**: Are TLS certificates pinned or validated?
- **Risk Level**: Medium - MITM risk
- **Verification Needed**: Check Tailscale and Caddy configurations
- **Source**: Security best practice

### Service User Permissions
- **Question**: What are the minimal permissions for each service?
- **Risk Level**: Medium - Privilege escalation
- **Verification Needed**: Audit systemd service configurations
- **Source**: concerns.md

## Performance Unknowns
[Performance-related items needing clarification]

### Nix Evaluation Performance
- **Question**: How long does full evaluation take?
- **Impact**: Development workflow speed
- **Measurement Needed**: Benchmark `nix flake check` time
- **Source**: plan.md

### Build Times
- **Question**: How long do fresh builds take with/without cache?
- **Impact**: User onboarding experience
- **Measurement Needed**: Benchmark init-to-rebuild workflow
- **Source**: plan.md

### Memory Usage
- **Question**: What is typical memory usage per module?
- **Impact**: Resource planning for users
- **Measurement Needed**: Profile running systems
- **Source**: plan.md

## Next Steps for Resolution
1. **License Check**: Verify LICENSE file exists and document terms
2. **Module Deep Dive**: Read all module default.nix files for complete package inventories
3. **Service Configuration Audit**: Review systemd service configs for restart policies, dependencies
4. **Security Audit**: Check for PII in logs, secrets in git history, minimal service permissions
5. **Documentation Sprint**: Create per-module READMEs and troubleshooting guides
6. **Test Strategy**: Design and implement integration test framework
7. **Performance Baseline**: Establish benchmarks for evaluation, build, and runtime performance
8. **Backup Documentation**: Write recommended backup and disaster recovery procedures
9. **PR Process Documentation**: Create CONTRIBUTING.md with PR requirements and review process
10. **User Testimonials**: Gather downstream usage patterns to inform documentation

## Review Checklist
Before marking baseline as complete:
- [ ] License terms documented
- [ ] All module package lists inventoried
- [ ] Service configuration details documented
- [ ] Security audit completed (PII, permissions, secrets)
- [ ] Per-module READMEs created
- [ ] Integration test strategy defined
- [ ] Backup and disaster recovery procedures documented
- [ ] Performance benchmarks established
- [ ] CONTRIBUTING.md created
- [ ] User deployment patterns documented
- [ ] All critical unknowns resolved

## Prioritized Action Items

### High Priority (Blockers)
1. Verify and document LICENSE
2. Security audit (PII in logs, git history, permissions)
3. Document PR review process and contribution guidelines

### Medium Priority (Important but not blocking)
4. Complete module package inventories
5. Document service configuration details (restart policies, dependencies)
6. Create per-module READMEs
7. Document backup and disaster recovery procedures
8. Establish performance benchmarks

### Low Priority (Nice to have)
9. Expand architecture decision records
10. Create comprehensive troubleshooting guides
11. Document downstream deployment patterns
12. Design integration test framework

## Confidence Assessment
**Current Documentation Confidence**: 75%

**High Confidence Areas** (>90%):
- Module structure and patterns
- Code style and formatting standards
- Core feature set and capabilities
- Flake architecture and outputs
- AI/MCP integration

**Medium Confidence Areas** (60-90%):
- Service configurations
- Security patterns
- Performance characteristics
- Operational procedures

**Low Confidence Areas** (<60%):
- Complete package inventories
- Module interaction behaviors
- Downstream usage patterns
- Test coverage adequacy
- Security audit status

**Confidence Blockers**:
- Missing LICENSE information
- Incomplete security audit
- No contribution guidelines
- Limited module deep-dive
