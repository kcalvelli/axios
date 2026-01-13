markdown

~~~markdown
# Spec-Kit Baseline Reverse Engineering Prompt

**Role & Goal**
You are working inside an existing code repository with access to file-system tools (e.g., `mkdir`, `find`, `tree`, file read/write).  

**Goal:** Reverse-engineer the current codebase to generate comprehensive foundational documentation for GitHub Spec Kit / spec-driven-development workflow. Create the necessary specification files in a dedicated `spec-kit-baseline/` directory that fully describe the project's *current* state, rules, architecture, and operational characteristics to enable AI-driven development and support.

---

## Global Constraints

- **Do not modify any existing source code or config files.**  
- **Base all conclusions strictly on the repository content.** Never guess or hallucinate.
- **Confidence Markers**: Prefix assertions with:
  - `[EXPLICIT]` - Found directly in config/documentation
  - `[INFERRED]` - Derived from code patterns with high confidence
  - `[ASSUMED]` - Best guess based on standard conventions
  - `[TBD]` - Insufficient evidence, requires human input
- **Evidence Linking**: Reference specific files for major claims:
  - Format: `(evidence: path/to/file:line-range)` or `(evidence: path/to/file)`
- **Version Sensitivity**: Note when patterns vary across codebase (may indicate migration or legacy subsystems)
- **Ambiguity Documentation**: When multiple patterns coexist, document all variants
- **All documents must be formatted for GitHub Spec Kit compatibility**: Clear markdown structure, declarative statements, actionable sections

---

## Phase 0: Repository Reconnaissance

### 0.1 Initial Survey
1. Execute repository structure analysis:
````bash
   # Get overview
   find . -type f -name "package.json" -o -name "Cargo.toml" -o -name "pyproject.toml" -o -name "go.mod" -o -name "pom.xml" -o -name "build.gradle*" -o -name "flake.nix" -o -name "*.sln"
   
   # Identify documentation
   find . -type f \( -iname "readme*" -o -iname "architecture*" -o -iname "contributing*" \) -not -path "*/node_modules/*" -not -path "*/.git/*"
   
   # Configuration files
   find . -maxdepth 3 -type f \( -name ".*rc*" -o -name "*.config.*" -o -name "*.yml" -o -name "*.yaml" -o -name "*.toml" -o -name "*.json" \) -not -path "*/node_modules/*" -not -path "*/.git/*"
````

2. **Detect Repository Type**:
   - **Monorepo indicators**: Multiple package manifests, workspace configurations, tools like Nx/Turborepo/Lerna
   - **Polyrepo indicators**: Single package manifest at root
   - Document finding in discovery report

3. **Catalog File System**:
   - Source directories by language
   - Test directories and frameworks
   - Documentation locations
   - Configuration file categories (build, lint, format, CI/CD, deployment)
   - Infrastructure-as-code files

### 0.2 Dependency Analysis
1. **Language Ecosystems Present**:
   - List each with version (Node 18, Python 3.11, Rust 1.75, etc.)
   - Package managers identified
   - Lock file presence and currency

2. **Build System Mapping**:
   - Build tools (Make, npm scripts, Cargo, Gradle, Bazel, Nix, etc.)
   - Build pipeline stages
   - Artifact outputs

3. **External Dependencies**:
   - Major frameworks and their versions
   - Database clients and ORMs
   - HTTP/API clients
   - Message queue libraries
   - Cloud SDK usage

### 0.3 Git History Analysis
1. **Repository Metadata**:
   - Creation date: `git log --reverse --format="%ai" | head -1`
   - Commit frequency pattern: `git log --format="%ai" | cut -d- -f1-2 | uniq -c`
   - Active branches: `git branch -a`
   - Tag/release pattern: `git tag --sort=-creatordate | head -20`

2. **Evolution Patterns**:
   - Major refactoring events (large file moves/renames)
   - Technology migrations (framework changes evident in history)
   - Growth areas (which directories changed most)
   - Contributor patterns (team size, commit distribution)

3. **Change Velocity**:
   - Files changed most frequently: `git log --format= --name-only | sort | uniq -c | sort -rn | head -20`
   - Stability indicators (files rarely changed in critical paths)

### 0.4 Entry Point Discovery
1. **Executables & Services**:
   - Main functions, entry scripts
   - Server startup files
   - CLI command definitions
   - Background workers/daemons

2. **API Surfaces**:
   - REST route definitions
   - GraphQL schemas
   - gRPC proto files
   - WebSocket handlers
   - CLI argument parsers

### 0.5 Generate `spec-kit-baseline/discovery-report.md`

Structure:
````markdown
# Discovery Report

## Repository Overview
- **Type**: [Single Repository | Monorepo]
- **Primary Languages**: [List with percentages if discoverable]
- **Repository Age**: [First commit date]
- **Activity Level**: [Commit frequency summary]

## Technology Stack Inventory
### Languages & Runtimes
- [Language]: [Version] (evidence: [file])

### Frameworks & Libraries
- [Framework]: [Version] - [Purpose]

### Build & Development Tools
- [Tool]: [Version/Config file]

### Infrastructure & Deployment
- [Tool/Platform]: [Usage evidence]

## Repository Metrics
- **Total Files**: [count]
- **Lines of Code**: [by language if discoverable]
- **Test Files**: [count and locations]
- **Documentation Files**: [count and locations]

## Entry Points
### Services/Servers
- [Service name]: [Entry file] - [Purpose]

### CLI Commands
- [Command]: [Implementation] - [Purpose]

### APIs
- [API type]: [Definition location] - [Endpoint count if discoverable]

## Module Structure
[For monorepos, list all packages/workspaces]
[For single repos, list major modules/directories]

- `[path/]`: [Purpose] - [Primary language]

## Dependency Graph Summary
### Internal Dependencies
[Module A] → [Module B, Module C]

### External Service Dependencies
- [Service/API]: [Integration points]

## Test Coverage Indicators
- **Test Frameworks**: [List discovered]
- **Test Directories**: [Locations]
- **Coverage Tooling**: [If configured]

## Change Hotspots
Top 10 most frequently modified files:
1. [File]: [Change count]

## Unknowns & Ambiguities
- [TBD] [Description of what's unclear]
````

---

## Phase 1: Constitution Analysis & Generation

### 1.1 Code Style & Standards
1. **Linting Configuration**:
   - ESLint, Pylint, Clippy, golangci-lint, etc.
   - Rules enabled/disabled
   - Custom rules defined

2. **Formatting Standards**:
   - Prettier, Black, rustfmt, gofmt configs
   - EditorConfig presence
   - Indentation (spaces/tabs, width)
   - Line length limits
   - Trailing comma policies

3. **Naming Conventions**:
   - Infer from codebase patterns:
     - File naming (kebab-case, snake_case, PascalCase)
     - Variable/function naming
     - Class/type naming
     - Constant naming
   - Document with confidence markers

### 1.2 Testing Requirements
1. **Testing Frameworks**:
   - Unit test tools (Jest, pytest, cargo test, go test)
   - Integration test tools
   - E2E test tools (Cypress, Playwright, Selenium)

2. **Test Organization**:
   - Directory structure (co-located vs. separate test dirs)
   - Naming patterns (*_test.go, *.test.ts, test_*.py)
   - Fixture/mock patterns

3. **CI Testing Requirements**:
   - Which tests run in CI
   - Coverage thresholds (if configured)
   - Performance test suites

### 1.3 Architecture & Tech Stack Rules
1. **Architectural Patterns**:
   - Layering (MVC, clean architecture, hexagonal, etc.)
   - Service boundaries (if microservices)
   - Module dependencies (allowed/forbidden)

2. **Technology Choices**:
   - Approved languages per context
   - Mandated frameworks
   - Database technologies
   - Infrastructure requirements

3. **Inferred Architecture Decision Records**:
   - Major technology choices with evidence
   - Structural patterns with rationale (if discoverable)

### 1.4 Process & Workflow
1. **Version Control**:
   - Branch protection rules (from .github/ or docs)
   - Branching strategy (GitFlow, trunk-based, etc.)
   - Commit message format (Conventional Commits, etc.)

2. **Pull Request Requirements**:
   - Required reviewers
   - Required checks
   - Merge strategies

3. **CI/CD Pipeline**:
   - Stages defined in workflows
   - Deployment triggers
   - Environment progression

### 1.5 Monorepo-Specific Policies (if applicable)
1. **Workspace Management**:
   - Workspace definition files
   - Inter-package dependency rules
   - Versioning strategy (independent vs. fixed)

2. **Shared Configuration**:
   - Root-level configs vs. package-level
   - Configuration inheritance patterns

3. **Build Orchestration**:
   - Task dependencies
   - Caching strategies
   - Affected file detection

### 1.6 Generate `spec-kit-baseline/constitution.md`

Structure:
````markdown
# Constitution

## Purpose
This document defines the non-negotiable rules, standards, and architectural constraints that govern this codebase. All changes must comply with these policies.

## Code Style Standards

### Formatting
- **Indentation**: [EXPLICIT] [Details] (evidence: [file])
- **Line Length**: [EXPLICIT] [Details]
- **Trailing Commas**: [Details]
- **Quote Style**: [Details]

### Naming Conventions
- **Files**: [INFERRED] [Pattern]
- **Variables/Functions**: [Pattern]
- **Classes/Types**: [Pattern]
- **Constants**: [Pattern]

### Linting Rules
- **Primary Linter**: [Tool + version]
- **Critical Rules**: [List enforced rules]
- **Disabled Rules**: [List with rationale if documented]

## Testing Requirements

### Test Framework Standards
- **Unit Tests**: [Framework] - [Location pattern]
- **Integration Tests**: [Framework] - [Location pattern]
- **E2E Tests**: [Framework] - [Location pattern]

### Coverage Requirements
- [EXPLICIT|ASSUMED] [Threshold if configured]

### CI Test Requirements
- All PRs must pass: [List test suites]
- Performance benchmarks: [If present]

## Architecture & Tech Stack

### Architectural Style
[INFERRED] [Pattern description with evidence]

### Approved Technologies
- **Languages**: [List with contexts]
- **Frameworks**: [List with purposes]
- **Databases**: [List with usage]
- **Infrastructure**: [List platforms/tools]

### Architecture Decision Records
#### [Decision Topic]
- **Pattern**: [Current implementation]
- **Evidence**: [Files demonstrating this choice]
- **Constraints**: [What this enables/prevents]
- **Confidence**: [EXPLICIT|INFERRED|ASSUMED]

[Repeat for major decisions]

### Module Boundaries
[For monorepos: workspace isolation rules]
- [Module A] → MAY depend on → [Module B, Module C]
- [Module A] → MUST NOT depend on → [Module D]

### Data Flow Constraints
- [Directional dependency rules]
- [Layer isolation requirements]

## Process & Workflow

### Version Control Rules
- **Branch Strategy**: [EXPLICIT] [Strategy name]
- **Protected Branches**: [List]
- **Commit Format**: [Convention if enforced]

### Pull Request Requirements
- **Minimum Reviewers**: [Count]
- **Required Checks**: [List CI checks]
- **Merge Strategy**: [Squash|Merge|Rebase]

### CI/CD Pipeline Stages
1. [Stage]: [Actions] - [Triggers]
2. [Stage]: [Actions] - [Triggers]

### Deployment Rules
- **Environments**: [List: dev, staging, prod, etc.]
- **Promotion Path**: [Environment progression]
- **Rollback Policy**: [If documented]

## Monorepo Governance [if applicable]

### Workspace Structure
- **Workspace Definition**: (evidence: [file])
- **Package Naming**: [Convention]

### Versioning Strategy
[EXPLICIT] [Independent | Fixed | Hybrid]

### Inter-Package Dependencies
- **Allowed**: [Patterns]
- **Prohibited**: [Patterns]

### Shared Tooling Configuration
- **Root-level**: [List configs]
- **Package-level Override Policy**: [Rules]

## Non-Negotiable Constraints

### Security
- [Any security patterns that must be maintained]

### Performance
- [Any performance budgets or requirements]

### Compatibility
- [Browser/platform support requirements]
- [API version compatibility rules]

### Data Handling
- [Privacy/compliance patterns if evident]

## Configuration Management
- **Environment Variables**: [How defined, example files]
- **Secrets Management**: [Pattern if discoverable]
- **Feature Flags**: [System if present]

## Deprecation & Migration Policies
[If evident from codebase or docs]

## Unknowns
- [TBD] [Aspect requiring human clarification]
````

---

## Phase 2: Specification Generation

### 2.1 Core Purpose Identification
1. **Project Goal**:
   - Synthesize from README, docs, package.json description
   - One-sentence statement of system purpose

2. **Primary Users/Stakeholders**:
   - Infer from feature set and API design
   - Document user types served

### 2.2 Feature Inventory
1. **User-Facing Capabilities**:
   - List 5-10 major features currently implemented
   - Identify from route handlers, CLI commands, UI components

2. **System Capabilities**:
   - Background processing
   - Data synchronization
   - Integration capabilities
   - Administrative functions

### 2.3 User Journey Mapping
1. **Primary Workflows**:
   - Map end-to-end user flows evident in code
   - Include both happy paths and error scenarios

2. **Integration Patterns**:
   - How external systems interact with this system
   - Webhook patterns, API consumption, event subscriptions

### 2.4 API Contract Documentation
1. **REST Endpoints** (if applicable):
   - Method, path, purpose
   - Request/response shapes (from types or validation)
   - Authentication requirements

2. **GraphQL Schema** (if applicable):
   - Queries, mutations, subscriptions
   - Type definitions

3. **CLI Commands** (if applicable):
   - Command structure
   - Arguments and flags
   - Subcommands

4. **Event/Message Schemas** (if applicable):
   - Event types produced/consumed
   - Message formats

### 2.5 Data Model Summary
1. **Primary Entities**:
   - List 10-15 core domain objects
   - Key relationships
   - Source: database schemas, ORM models, type definitions

2. **Data Flow Patterns**:
   - Create/Read/Update/Delete patterns
   - Caching strategies
   - Data validation rules

### 2.6 Generate `spec-kit-baseline/spec.md`

Structure:
````markdown
# Specification

## Goal
[One-sentence project purpose]

## System Overview
[2-3 paragraph description of what this system does, who uses it, and why it exists]

## User Types
1. **[User Type]**: [Description and primary goals]
2. **[User Type]**: [Description and primary goals]

## Core Features (Current Implementation)

### [Feature Category]
#### [Feature Name]
- **Purpose**: [What it does]
- **Implementation Evidence**: [Key files/modules]
- **Confidence**: [EXPLICIT|INFERRED]

[Repeat for 5-10 major features]

## User Journeys

### [Journey Name]
**Actor**: [User type]
**Goal**: [What they're trying to accomplish]

**Steps**:
1. [Action] - [System response]
2. [Action] - [System response]
3. [Action] - [System response]

**Success Criteria**: [How to know it worked]
**Error Scenarios**: [What can go wrong]

[Repeat for 3-5 key journeys]

## API Surface

### REST API [if applicable]
#### [Endpoint Group]
- `[METHOD] /path` - [Purpose]
  - **Request**: [Shape/type]
  - **Response**: [Shape/type]
  - **Auth**: [Requirements]
  - **Evidence**: [Route definition file]

### GraphQL API [if applicable]
[Schema documentation based on schema files]

### CLI Interface [if applicable]
````
[command] [subcommand] [flags] - [Purpose]
  --flag: [Description]
````

### Events/Messages [if applicable]
#### Produced Events
- `[EventType]`: [When emitted] - [Payload shape]

#### Consumed Events
- `[EventType]`: [Handler] - [Action taken]

## Data Model

### Core Entities
#### [Entity Name]
**Purpose**: [What this represents]
**Key Fields**:
- `[field]`: [Type] - [Purpose]
- `[field]`: [Type] - [Purpose]

**Relationships**:
- [Relation type] to [Other Entity]

**Source**: [Schema file or model definition]

[Repeat for 10-15 key entities]

### Data Flow Patterns
- **Creation**: [How entities are created]
- **Validation**: [Validation rules and enforcement points]
- **Persistence**: [Storage mechanisms]
- **Caching**: [If applicable, caching strategy]
- **Deletion**: [Soft/hard delete patterns]

## Integration Points

### External Services
- **[Service Name]**: [Purpose] - [Integration method]
  - **Auth**: [How authenticated]
  - **Failure Handling**: [Retry/fallback patterns]
  - **Evidence**: [Client code location]

### Webhooks/Callbacks [if applicable]
- **[Hook Type]**: [When triggered] - [Payload format]

## Acceptance Criteria (Current Behavior)

### Functional Criteria
- [✓] [Verifiable behavioral statement about what system does]
- [✓] [Verifiable behavioral statement about what system does]
- [✓] [Verifiable behavioral statement about what system does]
- [✓] [Verifiable behavioral statement about what system does]

### Non-Functional Criteria
- [✓] [Performance characteristic, if measurable]
- [✓] [Reliability characteristic, if evident]
- [✓] [Security characteristic, if evident]

### Known Limitations
- [Scope boundaries or known issues]

## Feature Flags [if present]
- `[flag-name]`: [What it controls] - [Current default]

## Unknowns
- [TBD] [Unclear behavior requiring clarification]
````

---

## Phase 3: Technical Planning & Architecture

### 3.1 Architecture Documentation
1. **System Decomposition**:
   - High-level component diagram (text description)
   - Component responsibilities
   - Communication patterns between components

2. **Layer Architecture**:
   - Presentation layer (UI, API handlers)
   - Business logic layer
   - Data access layer
   - Infrastructure layer

3. **Deployment Architecture**:
   - How components are deployed
   - Process model (single process, microservices, serverless, etc.)
   - Scaling characteristics

### 3.2 Module Breakdown
1. **Module Inventory**:
   - List all significant modules/packages
   - Purpose and responsibilities
   - Primary dependencies
   - Exposed interfaces

2. **Module Dependencies**:
   - Dependency graph (text representation)
   - Circular dependencies (flag as issues)
   - Coupling analysis

### 3.3 Data Architecture
1. **Storage Systems**:
   - Primary database(s) with schema overview
   - Cache layers
   - File storage
   - Message queues

2. **Data Lifecycle**:
   - How data enters the system
   - Transformation pipelines
   - Archival/retention policies (if evident)

3. **Migration Strategy**:
   - Database migration tool
   - Migration history analysis
   - Schema versioning approach

### 3.4 Infrastructure & Operations
1. **Runtime Dependencies**:
   - Required services (databases, caches, queues)
   - Environment variables and configuration
   - External API dependencies

2. **Build & Deployment**:
   - Build process steps
   - Artifact generation
   - Deployment method (containers, FaaS, traditional servers)
   - Infrastructure-as-code tools

3. **Observability**:
   - Logging framework and patterns
   - Metrics collection (if present)
   - Tracing instrumentation (if present)
   - Health check endpoints

### 3.5 Extension Points & Patterns
1. **Plugin Architecture** (if present):
   - How plugins are defined
   - Plugin discovery mechanism
   - Plugin lifecycle

2. **Configuration Injection**:
   - How behavior is configured
   - Configuration sources (files, env vars, remote config)

3. **Event/Hook Systems**:
   - Internal event buses
   - Extensibility hooks

### 3.6 Generate `spec-kit-baseline/plan.md`

Structure:
````markdown
# Technical Plan

## Architecture Overview

### System Type
[INFERRED] [Monolith | Microservices | Serverless | Hybrid] - [Justification]

### Component Architecture
[Text-based component diagram showing major system parts and their relationships]
````
[Component A] ←→ [Component B]
      ↓              ↓
[Database]    [Message Queue]
````

**Components**:
- **[Component Name]**: [Responsibility] - [Implementation location]

### Deployment Model
- **Process Model**: [How system runs]
- **Scaling Strategy**: [Horizontal/vertical, stateless/stateful]
- **High Availability**: [If patterns evident]

## Module Breakdown

### [Module/Package Name]
- **Path**: `[directory]`
- **Purpose**: [One-sentence description]
- **Language**: [Primary language]
- **Dependencies**:
  - Internal: [List internal dependencies]
  - External: [Key external libraries]
- **Exposed Interface**: [Public API/exports]
- **Entry Points**: [Main files/functions]
- **Test Coverage**: [If discoverable]

[Repeat for all major modules]

### Module Dependency Graph
````
[Module A] → [Module B], [Module C]
[Module B] → [Module D]
[Module C] → [Module D]
````

**Dependency Issues**:
- [Any circular dependencies or concerning coupling]

## Data Architecture

### Storage Systems

#### [Database Name/Type]
- **Technology**: [PostgreSQL, MongoDB, etc.]
- **Purpose**: [What data it holds]
- **Schema Summary**: [Table/collection count, key entities]
- **Connection**: [Connection pooling, ORM used]
- **Evidence**: [Config files, client initialization]

#### [Cache System] [if present]
- **Technology**: [Redis, Memcached, in-memory]
- **Purpose**: [What's cached]
- **Invalidation**: [Strategy if evident]

#### [File Storage] [if present]
- **Location**: [Local filesystem, S3, etc.]
- **Purpose**: [Asset types stored]

#### [Message Queue] [if present]
- **Technology**: [RabbitMQ, Kafka, SQS, etc.]
- **Queues/Topics**: [List with purposes]
- **Producers**: [What writes messages]
- **Consumers**: [What processes messages]

### Data Model Summary

#### Primary Entities
[List 10-15 core domain objects with key fields - cross-reference spec.md]

#### Relationships
- [Entity A] has-many [Entity B]
- [Entity B] belongs-to [Entity A]

### State Management

#### Application State
- **Where**: [In-memory, database, cache]
- **Lifecycle**: [Request-scoped, session-scoped, global]
- **Persistence**: [How state survives restarts]

#### Session Management [if applicable]
- **Storage**: [Cookies, JWT, server-side sessions]
- **Duration**: [Timeout policies]

### Data Migration

#### Migration Tool
- **System**: [Flyway, Liquibase, Alembic, golang-migrate, etc.]
- **Migration Files**: [Location and naming pattern]
- **Version**: [Current schema version if discoverable]

#### Migration History
- **Total Migrations**: [Count]
- **Recent Migrations**: [Last 5 with dates if from git history]

## Build & Deployment

### Build Process

#### Build Tools
- **Primary**: [npm, cargo, go build, gradle, make, nix, etc.]
- **Build Scripts**: [Commands available]
- **Build Stages**: [Compile, test, package, etc.]

#### Build Outputs
- **Artifacts**: [Binaries, containers, bundles, etc.]
- **Artifact Repository**: [Where artifacts are stored, if evident]

### Continuous Integration

#### CI Platform
- **System**: [GitHub Actions, GitLab CI, Jenkins, CircleCI, etc.]
- **Workflows**: [List workflows and their triggers]

#### Pipeline Stages
1. **[Stage Name]**: [Actions] - [Trigger conditions]
2. **[Stage Name]**: [Actions] - [Trigger conditions]

### Deployment

#### Deployment Method
- **Strategy**: [Blue-green, rolling, canary, direct]
- **Automation**: [How deployments are triggered]

#### Environments
- **[Environment]**: [Purpose] - [Deployment trigger]

#### Infrastructure-as-Code
- **Tools**: [Terraform, CloudFormation, Pulumi, NixOps, etc.]
- **Resources Managed**: [High-level summary]
- **Evidence**: [Config file locations]

### Runtime Configuration

#### Environment Variables
[List required and optional environment variables with purposes]

**Required**:
- `[VAR_NAME]`: [Purpose] - [Example format]

**Optional**:
- `[VAR_NAME]`: [Purpose] - [Default value]

#### Configuration Files
- `[file]`: [What it configures] - [Format]

#### Secrets Management
[INFERRED|ASSUMED] [How secrets are managed]

## Operational Considerations

### Observability

#### Logging
- **Framework**: [Log4j, Winston, slog, etc.]
- **Log Levels**: [Used levels]
- **Structured Logging**: [Yes/No - format]
- **Log Aggregation**: [If configured: Datadog, CloudWatch, etc.]
- **Evidence**: [Logger initialization files]

#### Metrics [if present]
- **System**: [Prometheus, StatsD, CloudWatch, etc.]
- **Metrics Collected**: [List key metrics if discoverable]

#### Tracing [if present]
- **System**: [Jaeger, Zipkin, X-Ray, etc.]
- **Instrumentation**: [Automatic/manual, coverage]

#### Health Checks
- **Endpoints**: [List health check URLs and their purposes]
- **Dependencies Checked**: [What health checks verify]

### Error Handling & Resilience

#### Error Handling Patterns
- **Strategy**: [Error types, propagation patterns]
- **User-Facing Errors**: [How errors are presented]
- **Error Logging**: [What gets logged on errors]

#### Retry Logic
[INFERRED] [Where retry logic is implemented]
- **[Operation]**: [Retry strategy] - [Evidence]

#### Circuit Breakers [if present]
- **Protected Operations**: [List]
- **Configuration**: [Thresholds, timeouts]

#### Graceful Degradation
[Examples of fallback behavior if evident]

### Performance Considerations

#### Caching Strategy
- **Application-Level**: [In-memory caches, cache libraries]
- **HTTP Caching**: [Headers used, CDN integration]
- **Database Query Caching**: [If ORM caching enabled]

#### Rate Limiting [if present]
- **Endpoints**: [Which APIs are rate-limited]
- **Strategy**: [Token bucket, fixed window, etc.]
- **Limits**: [Configured thresholds]

#### Database Optimization
- **Indexing**: [Critical indexes if discoverable in migrations]
- **Connection Pooling**: [Configuration]
- **Query Patterns**: [N+1 detection, lazy loading, eager loading]

#### Asset Optimization [if web application]
- **Bundling**: [Webpack, Vite, etc.]
- **Minification**: [Enabled/disabled]
- **CDN**: [If configured]

### Maintenance & Operations

#### Background Jobs [if applicable]
- **Scheduler**: [Cron, celery, sidekiq, etc.]
- **Jobs Defined**: [List with purposes and schedules]

#### Database Maintenance
- **Backups**: [If evident from configs or scripts]
- **Vacuum/Optimize**: [Scheduled maintenance tasks]

#### Dependency Updates
- **Automation**: [Dependabot, Renovate, etc. if configured]
- **Update Strategy**: [If documented]

## Extension Points & Customization

### Plugin Architecture [if present]
- **Plugin Interface**: [How plugins are defined]
- **Discovery**: [How plugins are loaded]
- **Examples**: [Existing plugins]

### Configuration Injection
- **Feature Flags**: [System used, flag locations]
- **Runtime Configuration**: [Hot reload capability]

### Webhooks [if present]
- **Outbound Webhooks**: [Events that trigger webhooks]
- **Inbound Webhooks**: [Endpoints that receive webhooks]

### API Extensibility
- **Versioning Strategy**: [How API versions are managed]
- **Backward Compatibility**: [Policies if documented]

## Dependencies

### Critical External Dependencies
1. **[Service/Library]**: [Purpose] - [Version] - [Criticality]

[List 10-15 most critical dependencies]

### Dependency Management
- **Lock Files**: [package-lock.json, Cargo.lock, etc.]
- **Update Policy**: [If documented]
- **Security Scanning**: [Tools configured]

### Internal Service Dependencies [if microservices]
- **[Service A]** depends on **[Service B]** for [purpose]

## Security Patterns [if discoverable]

### Authentication
[INFERRED] [Method: JWT, sessions, OAuth, etc.]
- **Implementation**: [Library/framework used]
- **Token Storage**: [Where auth tokens live]

### Authorization
[INFERRED] [Pattern: RBAC, ABAC, permission-based]
- **Implementation**: [How permissions are checked]
- **Evidence**: [Middleware, decorators, guard files]

### Input Validation
- **Validation Library**: [Joi, Yup, Pydantic, etc.]
- **Validation Points**: [Where validation occurs]

### Security Headers [if web application]
- **Configured Headers**: [CORS, CSP, HSTS, etc.]
- **Evidence**: [Middleware configuration]

## Risk Assessment

### Critical Path Components
[Top 3 components whose failure would break core functionality]
1. **[Component]**: [Why it's critical]

### Single Points of Failure
- [Components with no redundancy or fallback]

### Technical Debt Indicators
- [Outdated dependencies, deprecated APIs, TODO/FIXME concentration]

### Scalability Concerns
- [Potential bottlenecks evident in architecture]

## Unknowns
- [TBD] [Technical details requiring clarification]
````

---

## Phase 4: Operational Knowledge Capture

### 4.1 Build & Run Instructions
1. **Development Setup**:
   - Prerequisites (language versions, system dependencies)
   - Installation steps
   - Configuration setup

2. **Build Commands**:
   - Development build
   - Production build
   - Watch/hot-reload mode

3. **Run Commands**:
   - Start development server
   - Run production server
   - Run background workers

### 4.2 Testing Procedures
1. **Running Tests**:
   - Unit test command
   - Integration test command
   - E2E test command
   - Coverage report generation

2. **Test Data Management**:
   - Fixtures/seed data
   - Test database setup
   - Mock/stub patterns

### 4.3 Deployment Procedures
1. **Manual Deployment** (if applicable):
   - Step-by-step deployment guide
   - Pre-deployment checklist
   - Post-deployment verification

2. **Automated Deployment**:
   - Trigger methods
   - Deployment monitoring
   - Rollback procedures

### 4.4 Common Operations
1. **Database Operations**:
   - Running migrations
   - Rolling back migrations
   - Creating new migrations
   - Seeding data
   - Backup/restore

2. **Cache Management**:
   - Cache warming
   - Cache invalidation
   - Cache inspection

3. **Background Job Management**:
   - Viewing job queues
   - Retrying failed jobs
   - Clearing job queues

### 4.5 Debugging & Troubleshooting
1. **Local Debugging**:
   - Debug configurations
   - Breakpoint usage
   - REPL access

2. **Log Analysis**:
   - Where logs are written
   - Log format parsing
   - Common error patterns

3. **Common Issues**:
   - Known problems and solutions
   - FAQ from docs or issues

### 4.6 Generate `spec-kit-baseline/runbook.md`

Structure:
````markdown
# Operational Runbook

## Development Environment Setup

### Prerequisites
**System Requirements**:
- OS: [Supported operating systems]
- [Language]: [Version requirement] - [Installation guide reference]
- [Tool]: [Version requirement] - [Installation guide reference]

**Required External Services**:
- [Service]: [Purpose] - [How to install/access locally]

### Installation Steps
1. **Clone Repository**:
```bash
   git clone [repository-url]
   cd [directory]
```

2. **Install Dependencies**:
```bash
   [command from package manager]
```
   Evidence: [package manager files]

3. **Configuration Setup**:
```bash
   # Copy example configuration
   cp .env.example .env
   
   # Required configuration
   [VAR_NAME]=[description of what to set]
```

4. **Database Setup** [if applicable]:
```bash
   [command to create database]
   [command to run migrations]
   [command to seed data if present]
```

5. **Verify Installation**:
```bash
   [command to run tests or health check]
```

## Build & Run

### Development Mode
**Build** [if build step required]:
```bash
[build command]
```

**Run**:
```bash
[run command]
```

**Access**:
- Web UI: [URL if applicable]
- API: [URL if applicable]
- Ports: [List ports used]

### Production Mode
**Build**:
```bash
[production build command]
```

**Run**:
```bash
[production run command]
```

### Background Services [if applicable]
**Workers**:
```bash
[command to start workers]
```

**Scheduled Jobs**:
- Managed by: [cron, scheduler, etc.]
- Configuration: [where schedules are defined]

## Testing

### Unit Tests
```bash
[unit test command]
```
- Location: [test directories]
- Frameworks: [test frameworks]

### Integration Tests
```bash
[integration test command]
```
- Requirements: [external services needed]
- Setup: [how to prepare test environment]

### End-to-End Tests
```bash
[e2e test command]
```
- Browser: [which browsers used]
- Configuration: [e2e config files]

### Test Coverage
```bash
[coverage command]
```
- Report Location: [where coverage reports are generated]
- Threshold: [if configured]

### Watching Tests
```bash
[watch command if available]
```

## Database Operations

### Migrations

**Check Migration Status**:
```bash
[command to view migration status]
```

**Run Migrations**:
```bash
[command to run pending migrations]
```

**Rollback Migration**:
```bash
[command to rollback last migration]
```

**Create New Migration**:
```bash
[command to generate migration]
```
- Migration files: [directory location]
- Naming convention: [pattern]

### Seeding Data [if applicable]
```bash
[seed command]
```
- Seed files: [location]

### Database Console Access
```bash
[command to access database CLI]
```

### Backup & Restore [if documented]
**Backup**:
```bash
[backup command or script]
```

**Restore**:
```bash
[restore command or script]
```

## Cache Management [if applicable]

### Clear Cache
```bash
[cache clear command]
```

### Warm Cache [if applicable]
```bash
[cache warming command]
```

### Inspect Cache
- Tool: [redis-cli, memcached client, etc.]
- Connection: [how to connect]

## Background Job Management [if applicable]

### View Job Status
```bash
[command to view job queues]
```

### Retry Failed Jobs
```bash
[retry command]
```

### Clear Job Queues
```bash
[clear command]
```

### Job Dashboard [if applicable]
- URL: [dashboard URL]
- Access: [credentials or authentication method]

## Deployment

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Database migrations reviewed
- [ ] Environment variables updated
- [ ] Dependencies updated in lock files
- [ ] [Other checks from CI/docs]

### Deployment Methods

#### Automated Deployment [if CI/CD present]
**Trigger**:
- [How to trigger deployment: merge to main, tag creation, etc.]

**Monitor**:
- CI/CD Dashboard: [URL]
- Deployment Status: [where to check]

**Workflow**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

#### Manual Deployment [if applicable]
```bash
[deployment command or script]
```

**Steps**:
1. [Manual step 1]
2. [Manual step 2]
3. [Manual step 3]

### Post-Deployment Verification
```bash
[health check command or URL to verify]
```

**Verification Checklist**:
- [ ] Health check endpoint responding
- [ ] Critical user flows functional
- [ ] No error spike in logs
- [ ] [Other verification steps]

### Rollback Procedure
```bash
[rollback command or steps]
```

**Emergency Contact** [if documented]:
- [Contact information for deployment issues]

## Debugging

### Local Debugging

**IDE Debug Configuration** [if present]:
- Configuration: [location of debug config files]
- Breakpoints: [how to set breakpoints]

**REPL Access** [if applicable]:
```bash
[command to start REPL]
```

**Debug Logging**:
```bash
# Enable verbose logging
[environment variable or flag to enable debug logs]
```

### Log Analysis

**Log Locations**:
- **Development**: [stdout, file location]
- **Production**: [log aggregation system, file location]

**Log Format**:
````
[example log line with format explanation]
~~~

**Common Log Patterns**:

- **Error**: `[error pattern to search for]`
- **Warning**: `[warning pattern]`
- **Request**: `[request log pattern]`

**Searching Logs**:

bash

```bash
# Local
[grep/awk command examples]

# Production [if documented]
[log search query examples]
```

### Performance Profiling [if tools present]

**CPU Profiling**:

bash

```bash
[profiling command]
```

**Memory Profiling**:

bash

```bash
[memory profiling command]
```

**Database Query Analysis**:

- Tool: [query analyzer, EXPLAIN usage]
- How to enable: [configuration]

## Troubleshooting

### Common Issues

#### [Problem Description]

**Symptoms**:

- [Observable symptoms]

**Diagnosis**:

bash

```bash
[command to diagnose issue]
```

**Solution**:

bash

```bash
[command or steps to fix]
```

[Repeat for common issues found in docs or issue tracker]

### Health Checks

**Application Health**:

bash

```bash
curl [health check endpoint]
```

**Database Connection**:

bash

~~~bash
[command to test database connectivity]
````

**External Service Dependencies**:
- [Service]: `[command to verify connectivity]`

### Getting Help
- **Documentation**: [link to docs]
- **Issue Tracker**: [link to issues]
- **Team Contacts**: [if documented]
- **Runbook Source**: Generated from repository analysis - may be incomplete

## Monitoring & Alerts [if configured]

### Dashboards
- [Dashboard name]: [URL] - [What it shows]

### Key Metrics [if discoverable]
- [Metric name]: [What it measures] - [Normal range]

### Alerts [if configured]
- [Alert name]: [Trigger condition] - [Response procedure]

## Operational Procedures

### Routine Maintenance
- **[Task]**: [Frequency] - [Procedure]
- **Dependency Updates**: [How often] - [Process]
- **Log Rotation**: [If configured] - [Policy]

### Incident Response [if documented]
1. [Step 1 in incident response]
2. [Step 2]
3. [Step 3]

### Data Management
- **Retention Policy**: [If documented]
- **Data Export**: [If tools/procedures exist]
- **GDPR/Data Deletion**: [If procedures exist]

## Unknowns
- [TBD] [Operational procedure requiring clarification]
````

---

## Phase 5: Cross-Cutting Analysis

### 5.1 Security Patterns
1. **Authentication Mechanisms**:
   - How users/systems authenticate
   - Token generation and validation
   - Session management

2. **Authorization Patterns**:
   - Permission models (RBAC, ABAC, ACL)
   - Where permissions are checked
   - Admin vs. user capabilities

3. **Secrets Management**:
   - How secrets are stored
   - Environment variable usage
   - Secret rotation (if configured)

4. **Input Validation & Sanitization**:
   - Where validation occurs
   - Validation libraries used
   - SQL injection prevention
   - XSS prevention

5. **Secure Communication**:
   - TLS/HTTPS enforcement
   - Certificate management
   - Secure cookie flags

### 5.2 Performance Patterns
1. **Caching Strategies**:
   - What is cached and where
   - Cache invalidation logic
   - TTL policies

2. **Rate Limiting**:
   - Where rate limits are applied
   - Limit values
   - Rate limit storage (Redis, in-memory)

3. **Database Optimization**:
   - Index usage
   - Query optimization patterns
   - N+1 query prevention
   - Connection pooling configuration

4. **Asset Optimization** (web apps):
   - Bundling and minification
   - Lazy loading
   - CDN integration

5. **Async Processing**:
   - Job queues
   - Event-driven patterns
   - Background workers

### 5.3 Error Handling & Resilience
1. **Error Handling Strategy**:
   - Error types and hierarchy
   - Error propagation patterns
   - User-facing vs. internal errors

2. **Retry Logic**:
   - Where retries are implemented
   - Retry strategies (exponential backoff, fixed delay)
   - Max retry limits

3. **Circuit Breakers** (if present):
   - Protected operations
   - Failure thresholds
   - Recovery behavior

4. **Graceful Degradation**:
   - Fallback behaviors
   - Feature flags for disabling functionality
   - Partial outage handling

5. **Timeout Configuration**:
   - HTTP client timeouts
   - Database query timeouts
   - Job execution timeouts

### 5.4 Compliance & Governance
1. **License Compliance**:
   - Project license
   - Dependency licenses
   - License conflicts (if any)

2. **Data Governance**:
   - PII handling patterns
   - Data retention policies (if evident)
   - Audit logging
   - GDPR considerations (if applicable)

3. **Code Quality**:
   - Static analysis tools
   - Code review requirements
   - Technical debt tracking

4. **Documentation Standards**:
   - Code comment patterns
   - API documentation
   - Architecture documentation

### 5.5 Observability & Debugging
1. **Logging Strategy**:
   - Log levels and usage
   - Structured logging format
   - Sensitive data redaction
   - Log aggregation

2. **Metrics Collection** (if present):
   - Metrics library/framework
   - Key metrics collected
   - Metrics storage/visualization

3. **Distributed Tracing** (if present):
   - Tracing system
   - Trace context propagation
   - Instrumentation coverage

4. **Debugging Tools**:
   - Debug endpoints
   - Feature flags for debug mode
   - Profiling capabilities

### 5.6 Generate `spec-kit-baseline/concerns.md`

Structure:
````markdown
# Cross-Cutting Concerns

## Purpose
This document captures architectural patterns that span multiple modules and affect the entire system. These patterns should be consistently applied across all new development.

## Security

### Authentication
**Mechanism**: [INFERRED] [JWT | Session-based | OAuth | API Keys | etc.]

**Implementation**:
- **Library/Framework**: [Auth library used]
- **Token Type**: [Bearer token, session cookie, etc.]
- **Token Storage**: [Where tokens are stored: localStorage, httpOnly cookie, etc.]
- **Token Lifetime**: [If configured: duration]
- **Refresh Strategy**: [If present: how tokens are refreshed]

**Evidence**: [Files implementing auth]

**Login Flow**:
1. [Step 1 in authentication process]
2. [Step 2]
3. [Step 3]

**Protected Resources**:
- [How protected routes/endpoints are marked]
- [Middleware/decorator/guard used]

### Authorization
**Pattern**: [INFERRED] [RBAC | ABAC | Permission-based | ACL]

**Implementation**:
- **Permission Storage**: [Database tables, config files, in-code]
- **Permission Check Points**: [Middleware, decorators, guards]
- **Roles**: [List discovered roles if evident]

**Evidence**: [Files implementing authz]

**Permission Model**:
- [Description of how permissions are structured]
- [Relationship between users, roles, and permissions]

### Input Validation & Sanitization
**Validation Library**: [Joi, Yup, Zod, Pydantic, etc.]

**Validation Points**:
- **API Layer**: [Where request validation occurs]
- **Database Layer**: [ORM validations, constraints]
- **Client Layer**: [Frontend validation if present]

**Patterns**:
- **Required Fields**: [How enforced]
- **Type Checking**: [How ensured]
- **Format Validation**: [Email, URL, date formats]
- **Range Validation**: [Min/max values]
- **Custom Rules**: [Business logic validation]

**Security Validations**:
- **SQL Injection Prevention**: [Parameterized queries, ORM usage]
- **XSS Prevention**: [Output escaping, CSP]
- **CSRF Prevention**: [Token usage, SameSite cookies]

**Evidence**: [Validation middleware, schema files]

### Secrets Management
**Strategy**: [INFERRED] [Environment variables | Secret management service | Encrypted config]

**Implementation**:
- **Development**: [How secrets are provided locally]
- **Production**: [How secrets are injected: AWS Secrets Manager, Vault, etc.]
- **Rotation**: [TBD if not evident]

**Secret Types**:
- Database credentials
- API keys
- Encryption keys
- [Other sensitive configuration]

**Evidence**: [.env.example, secret loading code]

### Secure Communication
**HTTPS Enforcement**: [Yes/No - where configured]

**Security Headers** [if web application]:
- `[Header Name]`: [Value] - [Purpose]
- **CORS**: [Policy if configured]
- **CSP**: [Policy if configured]

**Certificate Management**: [TBD if not evident]

**Evidence**: [Server configuration, middleware]

## Performance

### Caching Strategy

#### Application-Level Caching
**Technology**: [Redis, Memcached, in-memory, etc.]

**Cached Data**:
- **[Data Type]**: [TTL] - [Invalidation strategy]
- **[Data Type]**: [TTL] - [Invalidation strategy]

**Cache Patterns**:
- **Cache-Aside**: [If used - examples]
- **Write-Through**: [If used - examples]
- **Write-Behind**: [If used - examples]

**Evidence**: [Cache client initialization, caching middleware]

#### HTTP Caching [if web application]
**Headers Used**:
- `Cache-Control`: [Values seen]
- `ETag`: [Usage pattern]
- `Last-Modified`: [Usage pattern]

**CDN Integration**: [If present - service used]

#### Database Query Caching
**ORM Caching**: [If enabled - configuration]
**Query Result Caching**: [If implemented - patterns]

### Rate Limiting [if present]
**Implementation**: [Library/middleware used]

**Rate-Limited Operations**:
- **[Endpoint/Operation]**: [Limit] - [Window] - [Strategy]

**Storage**: [Where rate limit state is stored: Redis, in-memory]

**Response**: [How rate limit exceeded is communicated: 429 status, headers]

**Evidence**: [Middleware configuration]

### Database Optimization

#### Indexing Strategy
**Discovered Indexes**:
- **[Table].[Column(s)]**: [Index type] - [Purpose if evident]

**Evidence**: [Migration files, schema definitions]

#### Connection Pooling
**Configuration**:
- **Pool Size**: [Min/max if configured]
- **Timeout**: [Connection timeout]
- **Retry**: [Connection retry logic]

**Evidence**: [Database client configuration]

#### Query Patterns
**Optimization Patterns Observed**:
- **Eager Loading**: [Where used to prevent N+1]
- **Lazy Loading**: [Where used]
- **Batch Operations**: [Bulk insert/update patterns]
- **Pagination**: [How large result sets are handled]

**Concerns**:
- [Potential N+1 queries identified]
- [Missing indexes for frequent queries]

### Asset Optimization [if web application]

#### Bundling
**Bundler**: [Webpack, Vite, Parcel, esbuild, etc.]
**Configuration**: [Key settings]

#### Minification
**Enabled**: [Yes/No]
**Tools**: [Terser, uglify, etc.]

#### Code Splitting [if present]
**Strategy**: [Route-based, component-based]
**Evidence**: [Dynamic imports in code]

#### Image Optimization [if applicable]
**Strategy**: [Compression, responsive images, lazy loading]
**Tools**: [Image optimization libraries]

### Asynchronous Processing

#### Job Queues [if present]
**Technology**: [Celery, Sidekiq, Bull, SQS, etc.]

**Job Types**:
- **[Job Name]**: [Purpose] - [Trigger] - [Priority if configured]

**Processing**:
- **Workers**: [How workers are configured]
- **Concurrency**: [Worker concurrency settings]
- **Retry**: [Job retry policy]

**Evidence**: [Job definitions, worker startup]

#### Event-Driven Patterns [if present]
**Event Bus**: [Technology used]
**Event Types**: [List key events]
**Publishers/Subscribers**: [Key components]

## Error Handling & Resilience

### Error Handling Strategy

#### Error Types
**Error Hierarchy**: [How errors are categorized]
````
[Base Error Class]
├── [Domain Error 1]
├── [Domain Error 2]
└── [Domain Error 3]
~~~

**Evidence**: [Error class definitions]

#### Error Propagation

**Pattern**: [Exceptions | Error values | Result types]

**Handling Layers**:

1. **[Layer]**: [What errors are caught/transformed here]
2. **[Layer]**: [What errors are caught/transformed here]

#### User-Facing Errors

**Format**: [Error response structure]

json

~~~json
{
  "error": "...",
  "message": "...",
  "code": "..."
}
````

**Status Codes**: [How HTTP status codes map to error types]

**Localization**: [If error messages are localized]

#### Error Logging
**What Gets Logged**:
- [Stack traces]
- [Request context]
- [User context (anonymized)]

**Log Level Mapping**:
- **[Error Type]**: [Log level]

**Evidence**: [Error handling middleware, global error handlers]

### Retry Logic

#### HTTP Client Retries
**Library**: [Retry library or built-in retry]

**Configuration**:
- **Max Retries**: [Count]
- **Backoff Strategy**: [Exponential | Linear | Fixed]
- **Retryable Status Codes**: [List]

**Evidence**: [HTTP client configuration]

#### Database Operation Retries
**Transient Error Handling**: [How deadlocks, timeouts are retried]

**Evidence**: [Database client or ORM configuration]

#### Job Retries [if applicable]
**Retry Policy**:
- **Max Attempts**: [Count]
- **Backoff**: [Strategy and values]
- **Retry Conditions**: [Which errors trigger retry]

### Circuit Breakers [if present]

#### Protected Operations
- **[Operation/Service]**: 
  - **Failure Threshold**: [Count or percentage]
  - **Timeout**: [Duration]
  - **Recovery**: [Half-open state behavior]

**Library**: [Circuit breaker library used]

**Evidence**: [Circuit breaker configuration]

### Graceful Degradation

#### Fallback Behaviors
- **[Feature]**: [Fallback when dependency fails]

#### Feature Flags for Degradation
- **[Flag]**: [What it disables] - [Fallback behavior]

**Evidence**: [Feature flag usage, fallback implementations]

### Timeout Configuration

#### HTTP Timeouts
- **Connection Timeout**: [Duration]
- **Request Timeout**: [Duration]

#### Database Timeouts
- **Query Timeout**: [Duration]
- **Connection Timeout**: [Duration]

#### Job Timeouts [if applicable]
- **Execution Timeout**: [Duration per job type]

**Evidence**: [Client configurations, environment variables]

## Compliance & Governance

### Licensing

#### Project License
**License**: [License type]
**Evidence**: [LICENSE file]

#### Dependency Licenses
**Analysis**: [If license checking is configured]

**Concerning Licenses**: [If any incompatible licenses found]

**Evidence**: [Package metadata, license files]

### Data Governance

#### PII Handling
**PII Identified**: [Types of PII in system]

**Protection Measures** [if evident]:
- **Encryption at Rest**: [How PII is encrypted]
- **Encryption in Transit**: [TLS enforcement]
- **Access Controls**: [Who can access PII]
- **Logging**: [Whether PII is logged (should not be)]

**Evidence**: [Data models, encryption code]

#### Data Retention [if evident]
**Retention Policies**: [TBD if not documented]

**Deletion Procedures**: [If implemented - how users can delete data]

#### Audit Logging [if present]
**Audit Events**:
- [Event type]: [What's logged]

**Audit Storage**: [Where audit logs go]

**Retention**: [How long audits are kept]

**Evidence**: [Audit middleware, audit log tables]

#### Privacy Regulations [if applicable]
**GDPR Considerations**:
- **Right to Access**: [Implementation if present]
- **Right to Deletion**: [Implementation if present]
- **Data Portability**: [Implementation if present]
- **Consent Management**: [If implemented]

**Evidence**: [Privacy-related endpoints, data export features]

### Code Quality

#### Static Analysis
**Tools Configured**:
- **[Tool]**: [Rules enabled] - [Enforcement: warning/error]

**Evidence**: [Config files, CI integration]

#### Code Review
**Requirements**: [PR review requirements from GitHub settings or docs]

**Review Checklist**: [If documented in CONTRIBUTING]

#### Technical Debt Tracking
**TODO/FIXME Analysis**:
- **Count**: [Number of TODOs/FIXMEs in codebase]
- **Hotspots**: [Files with most technical debt markers]

**Issue Tracking**: [If tech debt issues are labeled/tracked]

### Documentation Standards

#### Code Comments
**Pattern**: [Comment style observed]

**Documentation Comments**: [JSDoc, GoDoc, Rustdoc, docstrings, etc.]

**Coverage**: [INFERRED] [High/Medium/Low based on sampling]

#### API Documentation
**Format**: [OpenAPI/Swagger, GraphQL schema docs, etc.]

**Location**: [Where API docs are generated/stored]

**Up-to-date**: [TBD - requires manual verification]

#### Architecture Documentation
**Existing Docs**: [List significant architecture docs found]

**Completeness**: [INFERRED] [Assessment of documentation coverage]

## Observability & Debugging

### Logging

#### Logging Framework
**Library**: [Winston, Log4j, slog, etc.]

**Configuration**: [Config file location]

#### Log Levels
**Levels Used**: [DEBUG, INFO, WARN, ERROR, FATAL]

**Level Distribution** [if analyzable]:
- [Percentage breakdown of log level usage]

#### Structured Logging
**Format**: [JSON, key-value, plain text]

**Standard Fields**:
- `[field]`: [Purpose]

**Context Propagation**: [Request ID, trace ID, user ID]

#### Sensitive Data Handling
**Redaction**: [If present - what fields are redacted]

**PII in Logs**: [WARNING if PII found in logs]

#### Log Aggregation [if configured]
**System**: [Datadog, Splunk, CloudWatch, ELK, etc.]

**Configuration**: [How logs are shipped]

**Evidence**: [Logging agent config, SDK initialization]

### Metrics [if present]

#### Metrics System
**Technology**: [Prometheus, StatsD, CloudWatch, etc.]

**Library**: [Client library used]

#### Metrics Collected
**Application Metrics**:
- `[metric_name]`: [What it measures] - [Type: counter/gauge/histogram]

**System Metrics**: [CPU, memory, etc. if collected]

**Business Metrics**: [If any business KPIs are tracked]

#### Metrics Visualization
**Dashboards**: [Grafana, CloudWatch, Datadog - if configured]

**Alerting**: [If alerts are configured on metrics]

**Evidence**: [Metrics instrumentation code, dashboard configs]

### Distributed Tracing [if present]

#### Tracing System
**Technology**: [Jaeger, Zipkin, X-Ray, etc.]

**Library**: [OpenTelemetry, service-specific SDK]

#### Instrumentation
**Coverage**: [Which components are instrumented]

**Automatic vs. Manual**: [How tracing is added]

**Trace Context**: [How context is propagated across services]

**Evidence**: [Tracing initialization, instrumented functions]

### Debugging Capabilities

#### Debug Endpoints [if present]
- **[Endpoint]**: [What it reveals] - [Protected: yes/no]

#### Debug Mode
**Activation**: [How to enable: env var, flag, etc.]

**Effects**: [What changes in debug mode]

**Production Safety**: [Can debug mode run in production?]

#### Profiling [if available]
**CPU Profiling**: [Tool/method]
**Memory Profiling**: [Tool/method]
**Access**: [How to trigger profiling]

**Evidence**: [Profiling endpoints, configuration]

## Patterns & Anti-Patterns

### Positive Patterns Observed
1. **[Pattern Name]**: [Description and where it's used well]
2. **[Pattern Name]**: [Description and where it's used well]

### Anti-Patterns Identified
1. **[Anti-Pattern]**: [Description and location] - [Recommendation]
2. **[Anti-Pattern]**: [Description and location] - [Recommendation]

### Inconsistencies
- [Area where pattern is not applied consistently]

## Recommendations

### Security Improvements
1. [Recommendation based on findings]
2. [Recommendation based on findings]

### Performance Improvements
1. [Recommendation based on findings]
2. [Recommendation based on findings]

### Reliability Improvements
1. [Recommendation based on findings]
2. [Recommendation based on findings]

### Observability Improvements
1. [Recommendation based on findings]
2. [Recommendation based on findings]

## Unknowns
- [TBD] [Cross-cutting concern requiring clarification]
````

---

## Phase 6: Glossary & Knowledge Consolidation

### 6.1 Domain Terminology Extraction
1. **Code Analysis**:
   - Extract type/class names
   - Extract key function/method names
   - Extract database table/column names
   - Extract API endpoint names

2. **Documentation Mining**:
   - Extract terms from README
   - Extract terms from code comments
   - Extract terms from ADRs or design docs

3. **Pattern Recognition**:
   - Identify domain-specific acronyms
   - Identify business concepts
   - Identify technical concepts unique to this project

### 6.2 Generate `spec-kit-baseline/glossary.md`

Structure:
````markdown
# Glossary

## Purpose
This glossary defines domain-specific terms, acronyms, and technical concepts used throughout this codebase. Understanding these terms is essential for working with the system.

## Domain Terminology

### [Term]
**Definition**: [What this term means in this project context]

**Usage**: [Where this appears: code, UI, API, database]

**Related Terms**: [Cross-references to related glossary entries]

**Evidence**: [Where term is defined or used prominently]

[Repeat for all significant domain terms - aim for 20-50 entries]

## Technical Terminology

### [Technical Term]
**Definition**: [What this means]

**Context**: [How it's used in this project]

**Related Terms**: [Cross-references]

## Acronyms

### [ACRONYM]
**Expansion**: [What it stands for]

**Definition**: [What it means]

**Usage**: [Where it appears]

## Business Concepts

### [Business Concept]
**Definition**: [Business meaning]

**Technical Representation**: [How this is modeled in code/database]

**Evidence**: [Code locations]

## Deprecated Terms
[If evident from code comments or documentation]

### [Old Term]
**Status**: Deprecated

**Replaced By**: [New term]

**Migration**: [When/why it changed if documented]

## Term Relationships

### Hierarchies
- [Parent Term]
  - [Child Term 1]
  - [Child Term 2]

### Synonyms
- [Term A] = [Term B] (used interchangeably)

## Common Abbreviations in Code
- `[abbrev]`: [Full term] - [Where used]

## Unknowns
- [Term] - [TBD: Unclear meaning, requires subject matter expert]
````

---

## Phase 7: Unknowns Consolidation

### 7.1 Generate `spec-kit-baseline/unknowns.md`

Structure:
````markdown
# Unknowns & Questions

## Purpose
This document consolidates all items marked as `[TBD]` or unclear during reverse engineering. These require human review and input before the baseline is considered complete.

## Critical Unknowns
[Items that block full understanding of the system]

### [Category]
- **Question**: [What's unclear]
- **Context**: [Where this appears, why it matters]
- **Impact**: [What we can't do without this information]
- **Source**: [Which baseline document needs this: constitution.md, spec.md, etc.]

## Configuration Unknowns
[Missing or unclear configuration details]

### [Configuration Item]
- **Question**: [What's unclear]
- **Current State**: [What we can see]
- **Needed Info**: [What we need to know]

## Architecture Unknowns
[Unclear architectural decisions or patterns]

### [Architecture Question]
- **Question**: [What's unclear]
- **Evidence**: [Conflicting or ambiguous patterns seen]
- **Hypothesis**: [Best guess based on available info]
- **Verification**: [How to confirm]

## Operational Unknowns
[Unclear operational procedures]

### [Operational Question]
- **Question**: [What's unclear]
- **Impact**: [What operations this affects]
- **Workaround**: [Temporary approach if available]

## Domain Knowledge Gaps
[Business logic or domain concepts that aren't clear from code]

### [Domain Question]
- **Question**: [What's unclear]
- **Context**: [Where this concept appears]
- **SME Needed**: [What kind of expert can answer]

## Data Model Uncertainties
[Unclear aspects of data model]

### [Data Question]
- **Question**: [What's unclear]
- **Tables/Fields**: [Which data structures involved]
- **Impact**: [What queries or operations are affected]

## Integration Uncertainties
[Unclear external system interactions]

### [Integration Question]
- **Question**: [What's unclear]
- **System**: [Which external system]
- **Risk**: [What could go wrong without this info]

## Test Coverage Gaps
[Areas where test behavior is unclear or missing]

### [Test Gap]
- **Question**: [What's unclear]
- **Area**: [Feature or module]
- **Risk**: [Confidence level without this info]

## Ambiguous Patterns
[Places where multiple patterns exist and correct approach is unclear]

### [Ambiguity Description]
- **Pattern A**: [Description] - [Where used]
- **Pattern B**: [Description] - [Where used]
- **Question**: [Which is the standard going forward?]
- **Recommendation**: [Suggested resolution]

## Deprecated/Legacy Code
[Old patterns that may need migration]

### [Legacy Pattern]
- **Description**: [What the old pattern is]
- **Evidence**: [Where it still exists]
- **Question**: [Is this being migrated? Timeline?]

## Missing Documentation
[Documentation that should exist but doesn't]

### [Missing Doc]
- **Type**: [ADR, Runbook, API Doc, etc.]
- **Topic**: [What it should cover]
- **Priority**: [High/Medium/Low]
- **Impact**: [What's harder without it]

## Security Gaps
[Security-related items that need clarification]

### [Security Question]
- **Question**: [What's unclear]
- **Risk Level**: [Potential security impact]
- **Verification Needed**: [What to check]

## Next Steps for Resolution
1. [Action item to resolve unknowns]
2. [Action item to resolve unknowns]
3. [Action item to resolve unknowns]

## Review Checklist
Before marking baseline as complete:
- [ ] All critical unknowns resolved
- [ ] Configuration clarified
- [ ] Architecture questions answered
- [ ] Operational procedures documented
- [ ] Domain expert review completed
- [ ] Security audit performed
- [ ] [Other verification steps]
````

---

## Phase 8: Monorepo-Specific Processing (If Applicable)

### 8.1 Monorepo Detection & Processing
**If repository type was determined to be "Monorepo" in Phase 0**:

1. **Create Root-Level Documentation**:
   - Generate all baseline documents at repository root as described above
   - Add `spec-kit-baseline/monorepo-map.md` (structure below)

2. **Generate Per-Package Baselines**:
   - For each significant workspace/package:
     - Create `[package-path]/spec-kit-baseline/` directory
     - Generate scoped versions of:
       - `constitution.md` (package-specific rules)
       - `spec.md` (package features and APIs)
       - `plan.md` (package architecture)
       - `runbook.md` (package operations)
     - Reference root-level shared documentation

3. **Cross-Link Documentation**:
   - Root docs should reference package docs
   - Package docs should reference root and sibling packages

### 8.2 Generate `spec-kit-baseline/monorepo-map.md` (Monorepos Only)

Structure:
````markdown
# Monorepo Structure Map

## Overview
This monorepo contains multiple packages/workspaces with shared tooling and dependencies.

## Workspace Configuration
**Tool**: [Yarn workspaces, npm workspaces, pnpm, Nx, Turborepo, Cargo workspace, etc.]

**Configuration**: (evidence: [workspace config file])

## Package Inventory

### [Package Name]
- **Path**: `[relative/path]`
- **Type**: [Application | Library | Tool]
- **Language**: [Primary language]
- **Purpose**: [One-sentence description]
- **Baseline Docs**: [Link to package-specific spec-kit-baseline]
- **Public API**: [Yes/No - if library]
- **Deployable**: [Yes/No - if application]
- **Dependencies** (internal): [List internal package dependencies]

[Repeat for each package]

## Package Dependency Graph
````
[App Package A] → [Library B], [Library C]
[App Package D] → [Library C], [Library E]
[Library B] → [Library C]
~~~

**Circular Dependencies**: [List any - these are issues]

## Shared Infrastructure

### Shared Tooling

- **Linting**: [Root vs. package-level config]
- **Testing**: [Shared test infrastructure]
- **Build**: [Shared build configuration]

### Shared Libraries

[Internal libraries used by multiple packages]

### Shared Configuration

- **TypeScript**: [Shared tsconfig]
- **ESLint**: [Shared config]
- **Prettier**: [Shared config]
- **[Other shared configs]**

## Versioning Strategy

**Approach**: [Independent | Fixed | Hybrid]

**Current Versions**:

- 

**Version Pinning**: [How internal dependencies are versioned]

## Build Orchestration

### Build Order

1. [Package]([Version]) (no dependencies)
2. [Package]([Version]) (depends on 1)
3. [Package]([Version]) (depends on 1, 2)

### Task Dependencies

[How build tasks are orchestrated]

### Caching Strategy

[If build caching is configured: Nx, Turborepo]

### Affected Detection

[How the system determines which packages are affected by changes]

## Development Workflow

### Setup

bash

~~~bash
# Root-level setup command
[command]
````

### Per-Package Development
[How to work on individual packages]

### Cross-Package Changes
[How to develop across package boundaries]

## Testing Strategy

### Unit Tests
- **Scope**: Per-package
- **Command**: [How to run all tests]

### Integration Tests
- **Scope**: [Cross-package or per-package]
- **Command**: [How to run]

### E2E Tests
- **Scope**: [Application-level]
- **Command**: [How to run]

## Deployment

### Independent Deployments [if applicable]
[Which packages deploy independently]

### Coordinated Deployments [if applicable]
[Packages that must deploy together]

### Deployment Triggers
[How deployments are triggered per package]

## Governance

### Code Ownership
[If CODEOWNERS file exists - ownership structure]

### Change Impact Policy
[Requirements for changes affecting multiple packages]

### Breaking Change Policy
[How breaking changes in internal packages are managed]

## Migration Notes [if applicable]
[If this was migrated to monorepo - history and rationale]

## Unknowns
- [TBD] [Monorepo-specific unclear items]
````

---

## Final Phase: Summary & Validation

### Validation Checklist
Before considering the baseline complete, verify:

- [ ] All specified markdown files created
- [ ] All confidence markers applied consistently
- [ ] All evidence links point to real files
- [ ] No [TBD] items without explanation
- [ ] Unknowns consolidated in unknowns.md
- [ ] Cross-references between documents are valid
- [ ] Monorepo handling appropriate for repository type
- [ ] Git history analysis completed
- [ ] No source code or config files modified

### Generate Summary Output

After generating all baseline documents, provide:
````markdown
## Spec-Kit Baseline Generation Complete

### Files Created

#### Root Level: `spec-kit-baseline/`
1. `discovery-report.md` - Repository reconnaissance
2. `constitution.md` - Non-negotiable rules and standards
3. `spec.md` - Current features and acceptance criteria
4. `plan.md` - Technical architecture and design
5. `runbook.md` - Operational procedures
6. `concerns.md` - Cross-cutting patterns
7. `glossary.md` - Domain terminology
8. `unknowns.md` - Items requiring human review
9. [Monorepo only] `monorepo-map.md` - Workspace structure

#### Package Level [if monorepo]:
[List package-specific baseline directories created]

### Summary Statistics
- **Repository Type**: [Single | Monorepo]
- **Languages**: [List]
- **Total Files Analyzed**: [Count]
- **Lines of Code**: [Approximate]
- **Packages** [if monorepo]: [Count]
- **Confidence Score**: [HIGH|MEDIUM|LOW based on TBD count]
- **Unknowns Count**: [Number of TBD items]

### Critical Findings

#### Architecture
**Style**: [Architectural pattern identified]

**Key Insight**: [Most important architectural finding]

#### Most Critical Constraint [from constitution.md]
[2-3 sentence summary of the most important non-negotiable rule or pattern]

#### Critical Path Components [from plan.md]
1. [Component name] - [Why it's critical]
2. [Component name] - [Why it's critical]
3. [Component name] - [Why it's critical]

#### Biggest Risk Identified
[Most significant unknown, inconsistency, or technical debt issue discovered]

### Handoff Readiness Assessment

**AI Support Capability Score**: [1-10]

**Rationale**: [Brief explanation of score]

**Blockers to Full AI Support**:
1. [Issue preventing full autonomous operation]
2. [Issue preventing full autonomous operation]

**Recommended Next Steps**:
1. [Action item]
2. [Action item]
3. [Action item]

### Human Review Required
Priority review items from unknowns.md:
1. [Highest priority unknown]
2. [Second priority unknown]
3. [Third priority unknown]

### Repository Confidence Matrix
| Aspect | Confidence | Notes |
|--------|-----------|-------|
| Architecture | [HIGH/MED/LOW] | [Brief note] |
| Tech Stack | [HIGH/MED/LOW] | [Brief note] |
| Data Model | [HIGH/MED/LOW] | [Brief note] |
| Operations | [HIGH/MED/LOW] | [Brief note] |
| Security | [HIGH/MED/LOW] | [Brief note] |
| Testing | [HIGH/MED/LOW] | [Brief note] |

### Next Phase Recommendations
[Suggested next steps for spec-driven development based on what was found]
````

---

## Usage Notes

### Iterative Refinement
- After initial generation, humans should:
  1. Review unknowns.md and provide clarifications
  2. Verify inferred patterns against actual intent
  3. Correct any misunderstandings
  4. Fill in gaps in operational knowledge

### Maintenance
- These baseline documents should be:
  1. Kept in sync with code changes
  2. Updated when architectural decisions change
  3. Enhanced as operational knowledge grows
  4. Used as the foundation for all new spec-driven work

### Spec-Kit Integration
- Once validated, these documents can be:
  1. Used with `specify` command workflows
  2. Referenced in feature specifications
  3. Cited in architecture decision records
  4. Used to guide AI agents in code modifications

---

## Adaptations for Repository Types

### Single Application Repository
- Focus on single spec-kit-baseline/ directory
- Deep dive into application architecture
- Detailed operational procedures for the one deployment

### Library Repository
- Emphasize API documentation in spec.md
- Focus on public vs. internal interfaces
- Document semantic versioning strategy
- Emphasize backward compatibility in constitution

### Microservices Repository (Polyrepo)
- Document inter-service dependencies in plan.md
- Emphasize service contracts in spec.md
- Include service mesh/API gateway patterns
- Document service discovery mechanisms

### Monorepo
- Generate root + per-package baselines
- Create monorepo-map.md
- Document workspace dependencies
- Emphasize build orchestration

### Infrastructure Repository
- Focus on infrastructure resources in discovery
- Document Terraform/Pulumi/CloudFormation modules
- Emphasize operational procedures
- Include disaster recovery procedures
~~~