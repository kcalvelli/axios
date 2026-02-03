# MCP Server Configuration Examples

This document contains ready-to-use examples of popular MCP servers for axiOS.
Copy relevant sections to `home/ai/mcp.nix` to enable them.

## Usage

1. Choose servers you want from examples below
2. Copy server config to `servers = { ... }` in `home/ai/mcp.nix`
3. Set up required secrets/authentication (see comments)
4. Rebuild: `home-manager switch`
5. Test: `mcp-cli <server-name>`

---

## Official Anthropic Servers

### SQLite Database Access

No setup required - provide database path in args.

```nix
sqlite = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-sqlite"
    "--db-path"
    "${config.home.homeDirectory}/.local/share/myapp/database.sqlite"
  ];
};
```

### Memory/KV Store

In-memory key-value storage. No setup required.

```nix
memory = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-memory"
  ];
};
```

### Fetch Web Content

HTTP requests for web content. No setup required.

```nix
fetch = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-fetch"
  ];
};
```

### Puppeteer Browser Automation

May need Chrome/Chromium installed.

```nix
puppeteer = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-puppeteer"
  ];
};
```

### PostgreSQL Database Access

Requires PostgreSQL connection string.

```nix
postgres = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-postgres"
    "postgresql://username:password@localhost:5432/dbname"
  ];
};
```

### Google Drive Integration

**Setup:**
1. Create project at https://console.cloud.google.com
2. Enable Google Drive API
3. Create OAuth2 credentials
4. Add credentials to agenix secrets

```nix
gdrive = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-gdrive"
  ];
  env = {
    GDRIVE_CLIENT_ID = "\${GDRIVE_CLIENT_ID}";
    GDRIVE_CLIENT_SECRET = "\${GDRIVE_CLIENT_SECRET}";
  };
  passwordCommand = {
    GDRIVE_CLIENT_ID = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/gdrive-client-id"
    ];
    GDRIVE_CLIENT_SECRET = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/gdrive-client-secret"
    ];
  };
};
```

### Google Maps

**Setup:**
1. Enable Google Maps API
2. Create API key
3. Add to agenix secrets

```nix
google-maps = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-google-maps"
  ];
  env = {
    GOOGLE_MAPS_API_KEY = "\${GOOGLE_MAPS_API_KEY}";
  };
  passwordCommand = {
    GOOGLE_MAPS_API_KEY = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/google-maps-key"
    ];
  };
};
```

### Slack Integration

**Setup:**
1. Create Slack app: https://api.slack.com/apps
2. Add bot token scopes
3. Install to workspace
4. Add credentials to agenix secrets

```nix
slack = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-slack"
  ];
  env = {
    SLACK_BOT_TOKEN = "\${SLACK_BOT_TOKEN}";
    SLACK_TEAM_ID = "\${SLACK_TEAM_ID}";
  };
  passwordCommand = {
    SLACK_BOT_TOKEN = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/slack-token"
    ];
  };
};
```

### EverArt (AI Image Generation)

Requires EverArt API key.

```nix
everart = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-everart"
  ];
  env = {
    EVERART_API_KEY = "\${EVERART_API_KEY}";
  };
};
```

---

## Cloud Providers

### AWS

Uses AWS CLI credentials (`~/.aws/credentials`). Setup: `aws configure`

```nix
aws = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-aws" ];
};
```

### Google Cloud

Setup: `gcloud auth application-default login`

```nix
gcp = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-gcp" ];
  env = {
    GOOGLE_APPLICATION_CREDENTIALS = "${config.home.homeDirectory}/.config/gcloud/application_default_credentials.json";
  };
};
```

### Azure

Setup: `az login`

```nix
azure = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-azure" ];
};
```

### Cloudflare

Requires Cloudflare API token.

```nix
cloudflare = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@cloudflare/mcp-server-cloudflare"
  ];
  env = {
    CLOUDFLARE_API_TOKEN = "\${CLOUDFLARE_API_TOKEN}";
  };
};
```

---

## Databases

### MySQL

```nix
mysql = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [
    "mcp-server-mysql"
    "--host"
    "localhost"
    "--port"
    "3306"
    "--database"
    "mydb"
    "--user"
    "username"
  ];
  env = {
    MYSQL_PASSWORD = "\${MYSQL_PASSWORD}";
  };
};
```

### MongoDB

```nix
mongodb = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "mcp-server-mongodb"
  ];
  env = {
    MONGODB_URI = "mongodb://localhost:27017/mydb";
  };
};
```

### Redis

```nix
redis = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-redis" ];
  env = {
    REDIS_URL = "redis://localhost:6379";
  };
};
```

---

## Development Tools

### Docker

Requires Docker daemon running.

```nix
docker = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-docker"
  ];
};
```

### Kubernetes

Requires kubectl configured.

```nix
kubernetes = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-kubernetes" ];
};
```

### Sentry Error Tracking

```nix
sentry = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-sentry" ];
  env = {
    SENTRY_AUTH_TOKEN = "\${SENTRY_AUTH_TOKEN}";
    SENTRY_ORG = "my-organization";
  };
};
```

### GitLab

```nix
gitlab = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-gitlab"
  ];
  env = {
    GITLAB_PERSONAL_ACCESS_TOKEN = "\${GITLAB_PERSONAL_ACCESS_TOKEN}";
    GITLAB_URL = "https://gitlab.com"; # Or self-hosted URL
  };
};
```

### Linear Issue Tracker

```nix
linear = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-linear" ];
  env = {
    LINEAR_API_KEY = "\${LINEAR_API_KEY}";
  };
};
```

### Jira

```nix
jira = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-jira" ];
  env = {
    JIRA_URL = "https://mycompany.atlassian.net";
    JIRA_EMAIL = "user@example.com";
    JIRA_API_TOKEN = "\${JIRA_API_TOKEN}";
  };
};
```

---

## Productivity Tools

### Notion

```nix
notion = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@notionhq/mcp-server-notion"
  ];
  env = {
    NOTION_API_KEY = "\${NOTION_API_KEY}";
  };
};
```

### Obsidian Vault Access

```nix
obsidian = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "mcp-obsidian"
    "${config.home.homeDirectory}/Documents/ObsidianVault"
  ];
};
```

### Apple Notes (macOS only)

```nix
apple-notes = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "mcp-server-apple-notes"
  ];
};
```

### Todoist Task Management

```nix
todoist = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-todoist" ];
  env = {
    TODOIST_API_TOKEN = "\${TODOIST_API_TOKEN}";
  };
};
```

---

## AI & ML Tools

### Raycast AI

Requires Raycast Pro subscription.

```nix
raycast = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@raycast/mcp"
  ];
};
```

### E2B Code Execution Sandbox

```nix
e2b = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@e2b/mcp-server"
  ];
  env = {
    E2B_API_KEY = "\${E2B_API_KEY}";
  };
};
```

### OpenAI

```nix
openai = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-openai" ];
  env = {
    OPENAI_API_KEY = "\${OPENAI_API_KEY}";
  };
};
```

---

## Media & Entertainment

### YouTube Transcript Access

No setup required.

```nix
youtube-transcript = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-youtube-transcript" ];
};
```

### Spotify

```nix
spotify = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "mcp-server-spotify"
  ];
  env = {
    SPOTIFY_CLIENT_ID = "\${SPOTIFY_CLIENT_ID}";
    SPOTIFY_CLIENT_SECRET = "\${SPOTIFY_CLIENT_SECRET}";
  };
};
```

---

## Communication

### Email (IMAP)

```nix
email = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-email" ];
  env = {
    IMAP_HOST = "imap.example.com";
    IMAP_PORT = "993";
    IMAP_USER = "user@example.com";
    IMAP_PASSWORD = "\${IMAP_PASSWORD}";
  };
};
```

### Discord

```nix
discord = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "mcp-server-discord"
  ];
  env = {
    DISCORD_BOT_TOKEN = "\${DISCORD_BOT_TOKEN}";
  };
};
```

### Telegram

```nix
telegram = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-telegram" ];
  env = {
    TELEGRAM_BOT_TOKEN = "\${TELEGRAM_BOT_TOKEN}";
  };
};
```

---

## Search & Discovery

### Exa Search (Semantic Web Search)

```nix
exa = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@upstash/mcp-server-exa"
  ];
  env = {
    EXA_API_KEY = "\${EXA_API_KEY}";
  };
};
```

### Perplexity AI Search

```nix
perplexity = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-perplexity" ];
  env = {
    PERPLEXITY_API_KEY = "\${PERPLEXITY_API_KEY}";
  };
};
```

### Tavily Search

```nix
tavily = {
  enable = true;
  command = "${pkgs.python3}/bin/uvx";
  args = [ "mcp-server-tavily" ];
  env = {
    TAVILY_API_KEY = "\${TAVILY_API_KEY}";
  };
};
```
