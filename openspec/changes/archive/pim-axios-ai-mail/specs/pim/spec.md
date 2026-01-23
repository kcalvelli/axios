# Personal Information Management (PIM)

## Purpose

Provides AI-powered email management for axiOS desktop users through axios-ai-mail.

## Components

### Email: axios-ai-mail

**axios-ai-mail** is an AI-powered email management system designed for NixOS users.

#### Features
- **Multi-Account Support**: Gmail (OAuth2), IMAP/SMTP, Outlook (planned)
- **AI Classification**: Local LLM-powered tagging via Ollama with 35-tag default taxonomy
- **Privacy-First**: All data stored locally in SQLite; AI runs locally via Ollama
- **Modern UI**: Responsive web interface with PWA support, dark mode, keyboard shortcuts
- **Real-Time Sync**: WebSocket updates, systemd timer background sync
- **Declarative Config**: Email accounts and AI settings configured in Nix

#### Architecture
```
Web UI (React/Material-UI)
    ↓ HTTP/WebSocket
FastAPI Backend (Python)
    ↓
Email Providers (Gmail/IMAP) + Ollama AI + SQLite
```

#### Implementation
- **NixOS Module**: `modules/pim/default.nix` (system services)
- **Home Module**: `home/pim/default.nix` (user configuration)
- **External Flake**: `inputs.axios-ai-mail`

### Calendar

Calendar functionality uses a layered approach (unchanged from previous architecture):

1. **Sync**: vdirsyncer for CalDAV synchronization
2. **CLI/Widget**: khal (bundled with DMS) for terminal access and shell widget
3. **GUI**: PWA apps (Google Calendar, Fastmail, etc.) for graphical interface

#### Implementation
- **Home Module**: `home/calendar/default.nix` (systemd services)
- **Manual Config**: `~/.config/vdirsyncer/config` (user must configure)

### Contacts

Contacts are managed through external services:

- **Cloud Providers**: Gmail, iCloud, Outlook (web UI)
- **Future**: axios-ai-mail contacts module (planned)

## Configuration

### NixOS Module Options

```nix
pim = {
  enable = lib.mkEnableOption "Personal Information Management (axios-ai-mail)";

  role = lib.mkOption {
    type = lib.types.enum [ "server" "client" ];
    default = "server";
    description = ''
      PIM deployment role:
      - "server": Run axios-ai-mail backend service (requires AI module)
      - "client": PWA desktop entry only (connects to server on tailnet)
    '';
  };

  # Server-only options (ignored when role = "client")
  port = lib.mkOption {
    type = lib.types.port;
    default = 8080;
    description = "Port for axios-ai-mail web UI (server role only)";
  };

  user = lib.mkOption {
    type = lib.types.str;
    description = "User to run axios-ai-mail service as (server role only)";
  };

  tailscaleServe = {
    enable = lib.mkEnableOption "Expose axios-ai-mail via Tailscale HTTPS";
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
    };
  };

  sync = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable background sync service (server role only)";
    };
    frequency = lib.mkOption {
      type = lib.types.str;
      default = "5m";
      description = "Sync frequency (systemd timer format)";
    };
  };

  # PWA options (both roles)
  pwa = {
    enable = lib.mkEnableOption "Generate axios-ai-mail PWA desktop entry";
    serverHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "edge";
      description = ''
        Hostname of axios-ai-mail server on tailnet.
        - null: Use local hostname (for server role)
        - "edge": Connect to edge.tailnet.ts.net (for client role)
      '';
    };
    tailnetDomain = lib.mkOption {
      type = lib.types.str;
      example = "taile0fb4.ts.net";
      description = ''
        Tailscale tailnet domain for PWA URL generation.
        Required when pwa.enable = true.
      '';
    };
    httpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "HTTPS port of the axios-ai-mail server";
    };
  };
};
```

### Home-Manager Module Options

```nix
programs.axios-ai-mail = {
  enable = lib.mkEnableOption "axios-ai-mail email client";

  accounts.<name> = {
    provider = lib.mkOption {
      type = lib.types.enum [ "gmail" "imap" "outlook" ];
    };
    email = lib.mkOption { type = lib.types.str; };
    realName = lib.mkOption { type = lib.types.str; };

    # OAuth accounts (Gmail/Outlook)
    oauthTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to OAuth token (e.g., agenix secret)";
    };

    # IMAP/SMTP accounts
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    imap = {
      host = lib.mkOption { type = lib.types.str; };
      port = lib.mkOption { type = lib.types.port; default = 993; };
      tls = lib.mkOption { type = lib.types.bool; default = true; };
    };
    smtp = {
      host = lib.mkOption { type = lib.types.str; };
      port = lib.mkOption { type = lib.types.port; default = 587; };
      tls = lib.mkOption { type = lib.types.bool; default = true; };
    };
  };

  ai = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable AI classification";
    };
    model = lib.mkOption {
      type = lib.types.str;
      default = "llama3.2";
      description = "Ollama model for classification";
    };
    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:11434";
    };
    temperature = lib.mkOption {
      type = lib.types.float;
      default = 0.3;
    };
    useDefaultTags = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use built-in 35-tag taxonomy";
    };
    labelPrefix = lib.mkOption {
      type = lib.types.str;
      default = "AI";
      description = "Prefix for AI-generated labels";
    };
  };

  sync = {
    maxMessagesPerSync = lib.mkOption {
      type = lib.types.int;
      default = 100;
    };
  };
};
```

## Requirements

### Requirement: Server/Client Role Support

PIM module SHALL support multi-host Tailnet deployments via role-based configuration.

#### Scenario: Server role (default)

- **Given**: User has `modules.pim = true`
- **And**: `pim.role = "server"` (default)
- **When**: NixOS configuration is evaluated
- **Then**: axios-ai-mail service is enabled
- **And**: AI module is required (assertion)
- **And**: Background sync is enabled
- **And**: SQLite database is local

#### Scenario: Client role (PWA only)

- **Given**: User has `modules.pim = true`
- **And**: `pim.role = "client"`
- **And**: `pim.pwa.serverHost = "edge"`
- **When**: NixOS configuration is evaluated
- **Then**: axios-ai-mail service is NOT installed
- **And**: AI module is NOT required
- **And**: PWA desktop entry points to `https://edge.${tailnetDomain}:${httpsPort}/`

### Requirement: AI Module Dependency (Server Role Only)

PIM server role REQUIRES the AI module to be enabled.

#### Scenario: Server role without AI

- **Given**: User has `modules.pim = true`
- **And**: `pim.role = "server"`
- **And**: User has `modules.ai = false`
- **When**: NixOS configuration is evaluated
- **Then**: An assertion error is raised
- **And**: Error message explains the dependency

#### Scenario: Client role without AI

- **Given**: User has `modules.pim = true`
- **And**: `pim.role = "client"`
- **And**: User has `modules.ai = false`
- **When**: NixOS configuration is evaluated
- **Then**: Configuration succeeds (no AI requirement for clients)

#### Scenario: Server role with AI (default)

- **Given**: User has `modules.pim = true`
- **And**: `pim.role = "server"`
- **And**: `modules.ai` defaults to `true`
- **When**: NixOS configuration is evaluated
- **Then**: Both modules are enabled successfully

### Requirement: AI-Powered Email Classification

axios-ai-mail SHALL provide local AI-powered email classification.

#### Scenario: New email arrives

- **Given**: User has axios-ai-mail configured with Ollama
- **And**: AI classification is enabled (`ai.enable = true`)
- **When**: A new email is synced
- **Then**: The email is classified using the configured model
- **And**: Tags are applied with confidence scores
- **And**: Classification happens locally (no cloud API calls)

### Requirement: Declarative Account Configuration

Email accounts SHALL be configurable via Nix modules.

#### Scenario: Gmail account with OAuth

- **Given**: User configures `accounts.personal.provider = "gmail"`
- **And**: User provides `oauthTokenFile` path (agenix secret)
- **When**: System activates
- **Then**: Account is available in axios-ai-mail
- **And**: OAuth token is loaded securely from file

#### Scenario: IMAP account

- **Given**: User configures `accounts.work.provider = "imap"`
- **And**: User provides IMAP/SMTP settings and `passwordFile`
- **When**: System activates
- **Then**: Account is available in axios-ai-mail
- **And**: Password is loaded securely from file

### Requirement: Background Sync

axios-ai-mail SHALL provide automated background email synchronization.

#### Scenario: Periodic sync

- **Given**: `pim.sync.enable = true` (default)
- **And**: `pim.sync.frequency = "5m"`
- **When**: System is running
- **Then**: Emails sync every 5 minutes via systemd timer
- **And**: Pending operations (mark read, delete, etc.) are processed

### Requirement: Cross-Device Access

axios-ai-mail SHALL support secure cross-device access via Tailscale.

#### Scenario: Tailscale serve enabled

- **Given**: `pim.tailscaleServe.enable = true`
- **And**: Device is connected to tailnet
- **When**: User accesses `https://hostname.tailnet.ts.net:8443`
- **Then**: User can access axios-ai-mail web UI securely

### Requirement: PWA Desktop Entry

Users SHALL be able to generate a desktop entry for axios-ai-mail.

#### Scenario: PWA on server role (local hostname)

- **Given**: `pim.role = "server"`
- **And**: `pim.pwa.enable = true`
- **And**: `pim.pwa.tailnetDomain = "taile0fb4.ts.net"`
- **And**: `pim.pwa.serverHost` is not set (null)
- **When**: Home-manager activates
- **Then**: Desktop entry is created for "Axios AI Mail"
- **And**: URL is `https://${localHostname}.${tailnetDomain}:${httpsPort}/`
- **And**: Icon is axios mail icon
- **And**: StartupWMClass matches Brave app window

#### Scenario: PWA on client role (remote server)

- **Given**: `pim.role = "client"`
- **And**: `pim.pwa.enable = true`
- **And**: `pim.pwa.serverHost = "edge"`
- **And**: `pim.pwa.tailnetDomain = "taile0fb4.ts.net"`
- **When**: Home-manager activates
- **Then**: Desktop entry is created for "Axios AI Mail"
- **And**: URL is `https://edge.${tailnetDomain}:${httpsPort}/`
- **And**: Icon is axios mail icon
- **And**: StartupWMClass matches Brave app window

#### Scenario: PWA enabled without tailnet domain

- **Given**: `pim.pwa.enable = true`
- **And**: `pim.pwa.tailnetDomain` is not set
- **When**: NixOS configuration is evaluated
- **Then**: An assertion error is raised
- **And**: Error message explains tailnetDomain is required

#### Scenario: Client role without serverHost

- **Given**: `pim.role = "client"`
- **And**: `pim.pwa.serverHost` is not set (null)
- **When**: NixOS configuration is evaluated
- **Then**: An assertion error is raised
- **And**: Error message explains serverHost is required for client role

## Constraints

- **AI Module Required (Server Only)**: PIM server role requires `modules.ai = true` (enforced via assertion)
- **Client Role Exempt**: PIM client role does NOT require AI module
- **Ollama Required (Server Only)**: AI classification requires Ollama running on server
- **Tailscale for Multi-Device**: Cross-device access requires Tailscale
- **Client Requires serverHost**: Client role requires `pim.pwa.serverHost` to be set
- **Secret Management**: Credentials MUST use file-based secrets (agenix, sops-nix)
- **No Hardcoded Accounts**: Account configuration is user-defined

## Troubleshooting

### OAuth Token Expired

**Symptom**: Gmail sync fails with authentication error

**Solution**:
```bash
axios-ai-mail auth gmail --account personal
# Follow OAuth flow in browser
```

### AI Classification Not Working

**Symptom**: Emails sync but have no AI tags

**Check**:
1. Ollama running: `systemctl status ollama`
2. Model available: `ollama list | grep llama3.2`
3. AI enabled: Check `programs.axios-ai-mail.ai.enable`

### Sync Service Not Running

**Symptom**: Emails not updating automatically

**Check**:
```bash
systemctl --user status axios-ai-mail-sync.timer
journalctl --user -u axios-ai-mail-sync
```

### PWA Not Appearing

**Symptom**: Desktop entry not showing in app launcher

**Check**:
1. `pim.pwa.enable = true` in config
2. `pim.pwa.tailnetDomain` is set
3. Run `update-desktop-database` or logout/login
