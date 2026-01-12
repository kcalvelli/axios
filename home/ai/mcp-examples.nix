# Example MCP Server Configurations for axiOS
#
# This file contains ready-to-use examples of popular MCP servers.
# Copy relevant sections to home/ai/mcp.nix to enable them.
#
# USAGE:
# 1. Choose servers you want from examples below
# 2. Copy server config to settings.servers in home/ai/mcp.nix
# 3. Set up required secrets/authentication (see comments)
# 4. Rebuild: home-manager switch
# 5. Test: mcp-cli <server-name>

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # OFFICIAL ANTHROPIC SERVERS
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.anthropic = {
    # SQLite database access
    # REQUIRES: No setup (provide database path in args)
    sqlite = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sqlite"
        "--db-path"
        "${config.home.homeDirectory}/.local/share/myapp/database.sqlite"
      ];
    };

    # Memory/KV store (in-memory key-value storage)
    # REQUIRES: No setup
    memory = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
    };

    # Fetch web content (HTTP requests)
    # REQUIRES: No setup
    fetch = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-fetch"
      ];
    };

    # Puppeteer browser automation
    # REQUIRES: No setup (may need to install Chrome/Chromium)
    puppeteer = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-puppeteer"
      ];
    };

    # PostgreSQL database access
    # REQUIRES: PostgreSQL connection string
    # SETUP: Replace with your database URL
    postgres = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-postgres"
        "postgresql://username:password@localhost:5432/dbname"
      ];
    };

    # Google Drive integration
    # REQUIRES: OAuth2 credentials
    # SETUP:
    #   1. Create project at https://console.cloud.google.com
    #   2. Enable Google Drive API
    #   3. Create OAuth2 credentials
    #   4. Add credentials to secrets
    gdrive = {
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

    # Google Maps
    # REQUIRES: Google Maps API key
    # SETUP:
    #   1. Enable Google Maps API
    #   2. Create API key
    #   3. Add to secrets
    google-maps = {
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

    # Slack integration
    # REQUIRES: Slack bot token and team ID
    # SETUP:
    #   1. Create Slack app: https://api.slack.com/apps
    #   2. Add bot token scopes
    #   3. Install to workspace
    #   4. Add credentials to secrets
    slack = {
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

    # EverArt (AI image generation)
    # REQUIRES: EverArt API key
    everart = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-everart"
      ];
      env = {
        EVERART_API_KEY = "\${EVERART_API_KEY}";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # CLOUD PROVIDERS
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.cloud = {
    # AWS (uses AWS CLI credentials)
    # REQUIRES: AWS CLI configured (~/.aws/credentials)
    # SETUP: aws configure
    aws = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-aws" ];
    };

    # Google Cloud
    # REQUIRES: GCP credentials JSON
    # SETUP: gcloud auth application-default login
    gcp = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-gcp" ];
      env = {
        GOOGLE_APPLICATION_CREDENTIALS = "${config.home.homeDirectory}/.config/gcloud/application_default_credentials.json";
      };
    };

    # Azure
    # REQUIRES: Azure CLI authentication
    # SETUP: az login
    azure = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-azure" ];
    };

    # Cloudflare
    # REQUIRES: Cloudflare API token
    cloudflare = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@cloudflare/mcp-server-cloudflare"
      ];
      env = {
        CLOUDFLARE_API_TOKEN = "\${CLOUDFLARE_API_TOKEN}";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # DATABASES
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.databases = {
    # MySQL
    # REQUIRES: MySQL connection details
    mysql = {
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

    # MongoDB
    # REQUIRES: MongoDB connection string
    mongodb = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "mcp-server-mongodb"
      ];
      env = {
        MONGODB_URI = "mongodb://localhost:27017/mydb";
      };
    };

    # Redis
    # REQUIRES: Redis connection details
    redis = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-redis" ];
      env = {
        REDIS_URL = "redis://localhost:6379";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # DEVELOPMENT TOOLS
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.devtools = {
    # Docker
    # REQUIRES: Docker daemon running
    docker = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-docker"
      ];
    };

    # Kubernetes
    # REQUIRES: kubectl configured
    kubernetes = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-kubernetes" ];
    };

    # Sentry error tracking
    # REQUIRES: Sentry auth token
    sentry = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-sentry" ];
      env = {
        SENTRY_AUTH_TOKEN = "\${SENTRY_AUTH_TOKEN}";
        SENTRY_ORG = "my-organization";
      };
    };

    # GitLab
    # REQUIRES: GitLab personal access token
    gitlab = {
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

    # Linear issue tracker
    # REQUIRES: Linear API key
    linear = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-linear" ];
      env = {
        LINEAR_API_KEY = "\${LINEAR_API_KEY}";
      };
    };

    # Jira
    # REQUIRES: Jira API token
    jira = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-jira" ];
      env = {
        JIRA_URL = "https://mycompany.atlassian.net";
        JIRA_EMAIL = "user@example.com";
        JIRA_API_TOKEN = "\${JIRA_API_TOKEN}";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # PRODUCTIVITY TOOLS
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.productivity = {
    # Notion
    # REQUIRES: Notion API key
    notion = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@notionhq/mcp-server-notion"
      ];
      env = {
        NOTION_API_KEY = "\${NOTION_API_KEY}";
      };
    };

    # Obsidian vault access
    # REQUIRES: Path to Obsidian vault
    obsidian = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "mcp-obsidian"
        "${config.home.homeDirectory}/Documents/ObsidianVault"
      ];
    };

    # Apple Notes (macOS only)
    # REQUIRES: macOS
    apple-notes = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "mcp-server-apple-notes"
      ];
    };

    # Todoist task management
    # REQUIRES: Todoist API token
    todoist = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-todoist" ];
      env = {
        TODOIST_API_TOKEN = "\${TODOIST_API_TOKEN}";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # AI & ML TOOLS
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.ai = {
    # Raycast AI
    # REQUIRES: Raycast Pro subscription
    raycast = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@raycast/mcp"
      ];
    };

    # E2B code execution sandbox
    # REQUIRES: E2B API key
    e2b = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@e2b/mcp-server"
      ];
      env = {
        E2B_API_KEY = "\${E2B_API_KEY}";
      };
    };

    # OpenAI (requires API key)
    openai = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-openai" ];
      env = {
        OPENAI_API_KEY = "\${OPENAI_API_KEY}";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # MEDIA & ENTERTAINMENT
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.media = {
    # YouTube transcript access
    # REQUIRES: No setup
    youtube-transcript = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-youtube-transcript" ];
    };

    # Spotify
    # REQUIRES: Spotify API credentials
    spotify = {
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
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # COMMUNICATION
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.communication = {
    # Email (IMAP)
    # REQUIRES: Email credentials
    email = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-email" ];
      env = {
        IMAP_HOST = "imap.example.com";
        IMAP_PORT = "993";
        IMAP_USER = "user@example.com";
        IMAP_PASSWORD = "\${IMAP_PASSWORD}";
      };
    };

    # Discord
    # REQUIRES: Discord bot token
    discord = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "mcp-server-discord"
      ];
      env = {
        DISCORD_BOT_TOKEN = "\${DISCORD_BOT_TOKEN}";
      };
    };

    # Telegram
    # REQUIRES: Telegram bot token
    telegram = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-telegram" ];
      env = {
        TELEGRAM_BOT_TOKEN = "\${TELEGRAM_BOT_TOKEN}";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # SEARCH & DISCOVERY
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  examples.search = {
    # Exa search (semantic web search)
    # REQUIRES: Exa API key
    exa = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@upstash/mcp-server-exa"
      ];
      env = {
        EXA_API_KEY = "\${EXA_API_KEY}";
      };
    };

    # Perplexity AI search
    # REQUIRES: Perplexity API key
    perplexity = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-perplexity" ];
      env = {
        PERPLEXITY_API_KEY = "\${PERPLEXITY_API_KEY}";
      };
    };

    # Tavily search
    # REQUIRES: Tavily API key
    tavily = {
      command = "${pkgs.python3}/bin/uvx";
      args = [ "mcp-server-tavily" ];
      env = {
        TAVILY_API_KEY = "\${TAVILY_API_KEY}";
      };
    };
  };

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # USAGE EXAMPLE
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  # To enable servers, copy relevant sections to home/ai/mcp.nix:
  #
  # settings.servers = {
  #   # Copy from examples above
  #   sqlite = examples.anthropic.sqlite;
  #   docker = examples.devtools.docker;
  #   notion = examples.productivity.notion;
  # };
}
