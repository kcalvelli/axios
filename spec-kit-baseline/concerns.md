# Cross-Cutting Concerns

## Purpose
This document captures architectural patterns that span multiple modules and affect the entire system. These patterns should be consistently applied across all new development.

## Security

### Authentication
**Mechanism**: [VARIES] Per-service authentication

**Implementation**:
- **Immich**: Built-in user authentication (username/password)
- **Tailscale**: OAuth via Tailscale account
- **Google Drive Sync**: OAuth via rclone (`setup-gdrive-sync` script)
- **System**: UNIX user authentication (PAM)

**Evidence**: modules/services/immich.nix, modules/networking/tailscale.nix, home/desktop/gdrive-sync.nix

**Protected Resources**:
- NixOS system: sudo/wheel group membership
- Immich: User account required for web/mobile app access
- Tailscale network: Tailscale authentication key
- Google Drive: OAuth token (stored in rclone config)

### Authorization
**Pattern**: [MIXED] UNIX permissions + service-specific authorization

**Implementation**:
- **System Level**: UNIX file permissions, user/group membership
- **systemd Services**: DynamicUser, service isolation
- **Immich**: Role-based access (admin/user)
- **Samba**: User-level authentication with samba-add-user

**Evidence**: modules/users.nix, modules/networking/samba.nix

**Permission Model**:
- System admin: wheel group membership (sudo access)
- Regular users: Standard UNIX permissions
- Service users: systemd DynamicUser with minimal permissions

### Input Validation & Sanitization
**Validation Library**: Nix type system (build-time validation)

**Validation Points**:
- **Build-Time**: Nix type system validates all configuration
- **Module Options**: Type-checked via lib.mkOption
- **Runtime**: Service-specific validation (Immich, Caddy, etc.)

**Patterns**:
- **Required Fields**: lib.mkOption with no default
- **Type Checking**: Nix types (str, int, bool, listOf, attrsOf)
- **Format Validation**: String patterns in module options
- **Custom Rules**: lib.mkAssert for business logic validation

**Security Validations**:
- **Input Sanitization**: Nix string interpolation escaping
- **Path Validation**: Nix path types ensure valid file paths
- **Configuration Validation**: Flake check validates entire configuration

**Evidence**: All module default.nix files with option definitions

### Secrets Management
**Strategy**: [EXPLICIT] agenix (age encryption)

**Implementation**:
- **Encryption**: age-encrypted files in secrets/ directory
- **Decryption**: Automatic at system activation time
- **Storage**: `/run/secrets/` (tmpfs, cleared on reboot)
- **Access Control**: File permissions (owner, mode)

**Secret Types**:
- API keys (Brave Search, Tavily)
- OAuth tokens (GitHub, Google Drive)
- Service credentials (database passwords)
- SSH keys
- TLS certificates (managed by Tailscale)

**Evidence**: modules/secrets/, home/secrets/, flake.nix:27-30, .claude/project.md:178-205

**Configuration Example**:
```nix
age.secrets.brave-api-key = {
  file = ./secrets/brave-api-key.age;
  owner = "username";
  mode = "0400";
};
```

**Secret Rotation**: [TBD] Manual process, no automated rotation

### Secure Communication
**HTTPS Enforcement**: [EXPLICIT] Yes, via Tailscale TLS certificates

**Security Headers**:
- [TBD] Caddy default security headers (likely includes HSTS, X-Frame-Options, etc.)

**Certificate Management**:
- **Method**: Automatic via Tailscale (evidence: modules/networking/tailscale.nix)
- **Renewal**: Automatic (Tailscale manages)
- **Storage**: System certificate store

**Evidence**: modules/services/caddy.nix, modules/networking/tailscale.nix

## Performance

### Caching Strategy

#### Binary Caching (Nix Store)
**Technology**: Nix store + Cachix

**Cached Data**:
- **Built Packages**: All Nix packages (TTL: until garbage collected)
- **Build Results**: Derivation outputs (TTL: configurable via nix.gc)

**Cache Configuration**:
- **Substituters**: niri.cachix.org, numtide.cachix.org
- **Fallback**: Build from source if cache unavailable
- **Evidence**: flake.nix:112-124

**Invalidation**: Automatic (content-addressed)

#### Application-Level Caching
**[TBD]** Service-specific caching:
- Immich: Database query caching (built-in)
- Caddy: HTTP caching headers

### Rate Limiting
**Implementation**: [TBD] Service-specific

**Likely Configurations**:
- **Caddy**: May have built-in rate limiting
- **Immich**: Application-level rate limiting
- **System**: No global rate limiting (desktop use case)

**Evidence**: [TBD] Not explicitly configured in reviewed files

### Database Optimization

#### Immich Database
**Database**: [ASSUMED] PostgreSQL

**Indexing**: [TBD] Managed by Immich schema migrations

**Connection Pooling**: [TBD] Immich configuration

**Query Patterns**: [TBD] Immich-internal

**Evidence**: modules/services/immich.nix

### Asset Optimization
**N/A** - Desktop application, not web application requiring optimization

**Binary Size**: Managed by Nix (shared dependencies in /nix/store)

### Asynchronous Processing

#### Background Services
**Technology**: systemd services and timers

**Processing**:
- **Google Drive Sync**: systemd timer-triggered rclone bisync
- **Immich Background Jobs**: Immich job queue (internal)
- **System Updates**: [TBD] User-managed

**Evidence**: home/desktop/gdrive-sync.nix (systemd services)

**Job Types**:
- **Periodic Sync**: Google Drive bidirectional sync
- **Photo Processing**: Immich thumbnail generation, ML processing
- **System Maintenance**: Nix garbage collection (user-configured)

## Error Handling & Resilience

### Error Handling Strategy

#### Error Types
**Error Hierarchy**:
```
Nix Evaluation Errors (build-time)
├── Type Errors
├── Infinite Recursion
└── Undefined Variables

Runtime Errors (systemd)
├── Service Start Failures
├── Dependency Failures
└── Configuration Errors
```

**Evidence**: Standard Nix and systemd error handling

#### Error Propagation
**Pattern**: Fail-fast at build time, systemd restart at runtime

**Handling Layers**:
1. **Nix Evaluation**: Errors prevent system build
2. **NixOS Activation**: Errors prevent system switch
3. **systemd Services**: Restart on failure (configurable)

#### User-Facing Errors
**Format**:
- Build-time: Nix error messages with traces
- Runtime: systemd journal logs

**Access**: `journalctl -u <service>` or `systemctl status <service>`

#### Error Logging
**What Gets Logged**:
- Evaluation errors: Nix stderr
- Service errors: systemd journal
- Application errors: Service-specific logs

**Log Level Mapping**:
- Critical: Evaluation failures (prevent build)
- Error: Service failures
- Warning: Deprecated options
- Info: Normal operation

**Evidence**: systemd journal, mcp-journal MCP server

### Retry Logic

#### systemd Service Retries
**Configuration**: Per-service restart policies

**Default Pattern**:
- **Restart**: on-failure (most services)
- **RestartSec**: Configurable delay
- **StartLimitBurst**: Maximum retries before giving up

**Evidence**: Standard systemd service configurations

#### HTTP Client Retries
**rclone (Google Drive Sync)**:
- **Max Retries**: rclone built-in retry logic
- **Backoff Strategy**: Exponential backoff
- **Retryable Errors**: Network errors, rate limits

**Evidence**: home/desktop/gdrive-sync.nix (rclone configuration)

### Circuit Breakers
**Implementation**: [NONE] No explicit circuit breaker pattern

**Service Isolation**: systemd provides process isolation

### Graceful Degradation

#### Fallback Behaviors
- **Cachix Unavailable**: Build from source
- **MCP Server Missing Key**: Disable server, continue without it
- **Tailscale Down**: Services unavailable but system functional

#### Feature Flags for Degradation
- Module enable options allow disabling problematic features
- Example: Disable `desktop.enable` if desktop issues occur

**Evidence**: Module enable options throughout codebase

### Timeout Configuration

#### HTTP Timeouts
**rclone**: Built-in timeout configuration
**Caddy**: Default HTTP timeouts

#### Database Timeouts
**Immich**: [TBD] Application-configured

**Evidence**: [TBD] Service-specific configurations

## Compliance & Governance

### Licensing

#### Project License
**License**: [TBD] Not checked (LICENSE file existence unknown)

**Evidence**: [TBD] Root LICENSE file

#### Dependency Licenses
**Analysis**: Nix packages include license metadata

**Nixpkgs**: Mixed licenses (per package)

**Compliance**: User responsibility to ensure compliance

### Data Governance

#### PII Handling
**PII Identified**:
- User accounts (username, email)
- Immich photos (potentially contains faces, locations)
- Google Drive documents (user data)

**Protection Measures**:
- **Encryption at Rest**: Filesystem encryption (user-configured)
- **Encryption in Transit**: TLS (Tailscale), rclone encrypted transfer
- **Access Controls**: UNIX permissions, service isolation
- **Logging**: [TBD] PII in logs not analyzed

**Evidence**: modules/users.nix, home/desktop/gdrive-sync.nix, modules/networking/tailscale.nix

#### Data Retention
**Retention Policies**: User-configured
- **Photos**: Immich retention settings
- **Logs**: systemd journal retention (systemd configuration)
- **Backups**: User responsibility

**Deletion Procedures**: User-managed file deletion

#### Audit Logging
**Implementation**: [ASSUMED] systemd journal provides audit trail

**Audit Events**:
- systemd service starts/stops
- User login/logout (via PAM)
- sudo commands (via sudo logging)

**Audit Storage**: systemd journal

**Retention**: Configurable via systemd

#### Privacy Regulations
**GDPR Considerations**: [TBD]
- **Right to Access**: Manual export (Immich supports)
- **Right to Deletion**: Manual deletion
- **Data Portability**: Export features (user-managed)
- **Consent Management**: N/A (self-hosted, user-owned data)

### Code Quality

#### Static Analysis
**Tools Configured**:
- **nixpkgs-fmt**: Nix code formatting - [ERROR on non-compliance]

**Evidence**: .github/workflows/formatting.yml, flake.nix:137

#### Code Review
**Requirements**: [TBD] Not explicitly documented

**Review Checklist**: [TBD] CONTRIBUTING.md not found

#### Technical Debt Tracking
**TODO/FIXME Analysis**: [TBD] Not performed

**Issue Tracking**: GitHub Issues

### Documentation Standards

#### Code Comments
**Pattern**: [INFERRED] Minimal in Nix (declarative code is self-documenting)

**Documentation Comments**: Inline comments in complex logic

**Coverage**: [ASSUMED] Low to medium based on sampling

#### API Documentation
**Format**: Module option descriptions

**Location**: Module default.nix option definitions

**Up-to-date**: [ASSUMED] Maintained with code

#### Architecture Documentation
**Existing Docs**:
- README.md: User-facing overview
- .claude/project.md: Development guidelines
- docs/: Installation and usage guides
- CHANGELOG.md: Change history

**Completeness**: [INFERRED] Medium - covers main concepts, some gaps

## Observability & Debugging

### Logging

#### Logging Framework
**Library**: systemd journal (system-level)

**Configuration**: Per-service logging via systemd

#### Log Levels
**Levels Used**: Standard systemd/syslog levels
- DEBUG (7)
- INFO (6)
- NOTICE (5)
- WARNING (4)
- ERR (3)
- CRIT (2)
- ALERT (1)
- EMERG (0)

#### Structured Logging
**Format**: journald structured fields

**Standard Fields**:
- `_SYSTEMD_UNIT`: Service unit name
- `_PID`: Process ID
- `_HOSTNAME`: System hostname
- `MESSAGE`: Log message
- Custom fields per service

**Context Propagation**: [INFERRED] Service-specific

#### Sensitive Data Handling
**Redaction**: [TBD] Not explicitly configured

**PII in Logs**: [WARNING] Should be audited per service

#### Log Aggregation
**System**: Local only (systemd journal)

**Access**:
```bash
journalctl -u <service>
journalctl -f  # Follow
journalctl --since "1 hour ago"
```

**MCP Integration**: mcp-journal MCP server provides programmatic access

**Evidence**: flake.nix:98 (mcp-journal input)

### Metrics
**System**: [NONE] No explicit metrics collection configured

**Available Data**:
- systemd service status
- System resource usage (via standard tools)

**Potential Tools** (not configured):
- Prometheus
- Grafana
- systemd metrics

### Tracing
**System**: [NONE] No distributed tracing

**Context**: Single-system desktop application

### Debugging Capabilities

#### Debug Endpoints
**N/A** - Not a web service

#### Debug Mode
**Activation**:
- Nix: `--show-trace` flag for evaluation traces
- Verbose logging: Per-service systemd configuration

**Effects**:
- Detailed error traces
- Verbose service output

**Production Safety**: [ASSUMED] Debug mode not enabled by default

#### Profiling
**Nix Evaluation**: No built-in profiling

**System Performance**: Standard Linux tools (perf, strace, etc.)

**Evidence**: Standard tooling, not project-specific

## Patterns & Anti-Patterns

### Positive Patterns Observed
1. **Conditional Evaluation with mkIf**: All packages wrapped in `config = lib.mkIf cfg.enable` prevents disabled modules from evaluating (evidence: all module default.nix files)
2. **Module Independence**: Modules are independently importable with no inter-module dependencies (evidence: modules/default.nix, module structure)
3. **Declarative Secrets**: agenix integration for encrypted secrets management (evidence: modules/secrets/)
4. **Home-Manager Integration**: Clean separation between system and user configuration (evidence: home/ directory structure)
5. **Calendar Versioning**: Clear versioning scheme that communicates recency (evidence: CHANGELOG.md, git tags)
6. **Automated Dependency Updates**: Weekly flake.lock updates via CI (evidence: .github/workflows/flake-lock-updater.yml)
7. **Directory-Based Modules**: Consistent module structure pattern (evidence: .claude/project.md:60-66)
8. **Aspect Files**: Clean separation of concerns within modules (e.g., networking/samba.nix, networking/tailscale.nix)

### Anti-Patterns Identified
1. **Custom Package Override**: Immich 2.3.1 custom package due to nixpkgs lag - increases maintenance burden (evidence: pkgs/immich/, CHANGELOG.md:13-18) - [RECOMMENDATION]: Remove once nixpkgs updates
2. **[POTENTIAL] Missing Tests**: No module interaction testing beyond flake check (evidence: no test infrastructure found) - [RECOMMENDATION]: Consider NixOS VM tests
3. **[TBD] Incomplete Documentation**: Some modules lack detailed documentation (evidence: no README in most module directories) - [RECOMMENDATION]: Add per-module README files

### Inconsistencies
- [NONE IDENTIFIED] Module pattern consistently applied across all modules

## Recommendations

### Security Improvements
1. **Secret Rotation**: Implement documented secret rotation procedures
2. **Audit PII Logging**: Ensure no PII in systemd logs
3. **Security Headers**: Document Caddy security headers configuration
4. **Certificate Monitoring**: Add expiration monitoring for Tailscale certs (though auto-renewed)

### Performance Improvements
1. **Build Caching**: Already optimal with Cachix
2. **Evaluation Caching**: Consider using `nix.conf` settings for faster evaluation
3. **Lazy Evaluation**: Already using mkIf extensively

### Reliability Improvements
1. **Service Dependencies**: Ensure proper systemd service ordering
2. **Restart Policies**: Review and document per-service restart policies
3. **Health Checks**: Add health check scripts for critical services
4. **Backup Procedures**: Document backup strategies for Immich and user data

### Observability Improvements
1. **Metrics Collection**: Consider optional Prometheus exporter modules
2. **Log Retention**: Document recommended journal retention settings
3. **MCP Integration**: Excellent journal access via mcp-journal
4. **Error Dashboards**: Consider optional Grafana module for system monitoring

## Unknowns
- [TBD] Complete systemd service restart policies per module
- [TBD] Caddy security headers configuration
- [TBD] PII in logs audit results
- [TBD] Secret rotation procedures
- [TBD] Service dependency graph (systemd After/Requires)
- [TBD] Health check implementations
- [TBD] Rate limiting configurations
- [TBD] Database connection pool settings (Immich)
- [TBD] Backup and restore procedures
- [TBD] Disaster recovery plan
- [TBD] Performance benchmarks
- [TBD] Load testing results
