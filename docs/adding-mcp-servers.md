# Adding MCP Servers to axiOS

This guide shows how to enable additional tools for Claude Code within axiOS.

## Overview

axiOS uses a **declarative MCP configuration** approach with these benefits:

- **Single source of truth**: Define servers once in `home/ai/mcp.nix`
- **Multi-tool support**: Auto-generates configs for Claude Code, Gemini CLI, and mcp-cli
- **Nix packaging**: MCP servers installed via Nix (no runtime `npm install`)
- **Secrets management**: Integrated with agenix for API keys

## Current MCP Servers

axiOS ships with these servers pre-configured:

| Server | Purpose | Setup Required |
|--------|---------|----------------|
| git | Git operations | None |
| github | GitHub API | `gh auth login` |
| time | Date/time utilities | None |
| filesystem | File read/write | None (restricted paths) |
| journal | systemd logs | None (auto-added to group) |
| nix-devshell-mcp | Nix dev environments | None |
| sequential-thinking | Enhanced reasoning | None |
| context7 | Library documentation | None |
| brave-search | Web search | API key (agenix) |
| ultimate64 | C64 emulator control | Hardware required |

## Adding New MCP Servers

### Method 1: NPM-based Servers (Easiest)

For servers available via npm (most common), add them to `home/ai/mcp.nix`:

**Example: Adding the Slack MCP Server**

```nix
# home/ai/mcp.nix
settings.servers.slack = {
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

**Example: Adding the PostgreSQL MCP Server**

```nix
settings.servers.postgres = {
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-postgres"
    "postgresql://user:password@localhost/dbname"
  ];
};
```

**Example: Adding the Google Drive MCP Server**

```nix
settings.servers.gdrive = {
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-gdrive"
  ];
  env = {
    GDRIVE_CLIENT_ID = "\${GDRIVE_CLIENT_ID}";
    GDRIVE_CLIENT_SECRET = "\${GDRIVE_CLIENT_SECRET}";
  };
};
```

### Method 2: Python/uvx Servers

For Python-based MCP servers:

**Example: Adding a Python MCP Server**

```nix
settings.servers.python-tool = {
  command = "${pkgs.python3}/bin/uvx";
  args = [
    "mcp-server-python-tool"
  ];
};
```

### Method 3: Packaged Nix Servers

For servers packaged in nixpkgs or available via flake inputs:

**Example: Adding from Flake Input**

```nix
# 1. Add to flake.nix inputs
inputs.my-mcp-server.url = "github:username/my-mcp-server";

# 2. Pass to home-manager
home-manager.extraSpecialArgs = {
  inputs = inputs;
};

# 3. Reference in home/ai/mcp.nix
settings.servers.my-server = {
  command = "${
    inputs.my-mcp-server.packages.${pkgs.stdenv.hostPlatform.system}.default
  }/bin/my-mcp-server";
};
```

**Example: Adding from nixpkgs Package**

```nix
settings.servers.packaged-server = {
  command = "${pkgs.my-mcp-server}/bin/my-mcp-server";
  args = ["--stdio"];
};
```

### Method 4: mcp-servers-nix Modules

For servers already in mcp-servers-nix, enable them in the `programs` section:

```nix
# home/ai/mcp.nix
claude-code-servers = {
  programs = {
    git.enable = true;
    time.enable = true;
    # Add new module here
    newserver.enable = true;
  };
};
```

**Note**: Check mcp-servers-nix documentation for available modules:
- https://github.com/andythigpen/mcp-servers-nix

## Adding Secrets for MCP Servers

### Step 1: Encrypt Secret with agenix

```bash
# In your config repo (e.g., ~/.config/nixos_config)
cd secrets/
echo "your-api-key-here" | agenix -e my-service-key.age
```

### Step 2: Register Secret in NixOS Config

```nix
# configuration.nix or host-specific config
{
  age.secrets.my-service-key = {
    file = ./secrets/my-service-key.age;
  };

  # Make available to AI services
  services.ai.secrets.myServiceKeyPath = config.age.secrets.my-service-key.path;
}
```

### Step 3: Configure MCP Server to Use Secret

**For Claude Code** (use passwordCommand):

```nix
# home/ai/mcp.nix
settings.servers.myservice = {
  command = "...";
  env = {
    API_KEY = "\${API_KEY}";
  };
  passwordCommand = {
    API_KEY = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/my-service-key"
    ];
  };
};
```

**For Gemini CLI** (use wrapper script):

```nix
# home/ai/mcp.nix (in the home.packages section)
++ lib.optionals (osConfig.services.ai.gemini.enable or true) [
  (pkgs.writeShellScriptBin "axios-gemini" ''
    # Load secrets
    ${lib.optionalString (osConfig.services.ai.secrets.myServiceKeyPath != null) ''
      export MY_SERVICE_KEY=$(cat ${osConfig.services.ai.secrets.myServiceKeyPath})
    ''}
    exec ${pkgs.gemini-cli-bin}/bin/gemini "$@"
  '')
];
```

## Configuring Server-Specific Options

### Filesystem Restrictions

The filesystem server restricts access to specific paths:

```nix
# Modify allowed paths
settings.servers.filesystem = {
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-filesystem"
    "/tmp"
    "${config.home.homeDirectory}/Projects"
    "${config.home.homeDirectory}/Documents"  # Add more paths
  ];
};
```

### Server Arguments

Pass additional arguments to configure server behavior:

```nix
settings.servers.myserver = {
  command = "...";
  args = [
    "--verbose"
    "--max-results"
    "100"
    "--enable-feature"
  ];
};
```

### Environment Variables

Configure server behavior with environment variables:

```nix
settings.servers.myserver = {
  command = "...";
  env = {
    LOG_LEVEL = "debug";
    MAX_CONNECTIONS = "10";
    CACHE_DIR = "${config.home.homeDirectory}/.cache/myserver";
  };
};
```

## Real-World Examples

### Example 1: Adding Anthropic MCP Servers

```nix
# Add official Anthropic servers
settings.servers = {
  # SQLite database access
  sqlite = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sqlite"
      "--db-path"
      "${config.home.homeDirectory}/.local/share/myapp/db.sqlite"
    ];
  };

  # Memory/KV store
  memory = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-memory"
    ];
  };

  # Fetch web content
  fetch = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-fetch"
    ];
  };

  # Puppeteer browser automation
  puppeteer = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-puppeteer"
    ];
  };
};
```

### Example 2: Adding Database Servers

```nix
settings.servers = {
  # PostgreSQL
  postgres = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-postgres"
      "postgresql://localhost/mydb"
    ];
  };

  # MySQL
  mysql = {
    command = "${pkgs.python3}/bin/uvx";
    args = [
      "mcp-server-mysql"
      "--host"
      "localhost"
      "--database"
      "mydb"
    ];
    env = {
      MYSQL_PASSWORD = "\${MYSQL_PASSWORD}";
    };
  };
};
```

### Example 3: Adding Cloud Provider Tools

```nix
settings.servers = {
  # AWS
  aws = {
    command = "${pkgs.python3}/bin/uvx";
    args = ["mcp-server-aws"];
    # Uses AWS CLI credentials from ~/.aws
  };

  # Google Cloud
  gcp = {
    command = "${pkgs.python3}/bin/uvx";
    args = ["mcp-server-gcp"];
    env = {
      GOOGLE_APPLICATION_CREDENTIALS = "${config.home.homeDirectory}/.config/gcloud/credentials.json";
    };
  };

  # Docker
  docker = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-docker"
    ];
  };
};
```

### Example 4: Adding Custom Development Tools

```nix
settings.servers = {
  # Linear issue tracker
  linear = {
    command = "${pkgs.python3}/bin/uvx";
    args = ["mcp-server-linear"];
    env = {
      LINEAR_API_KEY = "\${LINEAR_API_KEY}";
    };
  };

  # Notion
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

  # Sentry error tracking
  sentry = {
    command = "${pkgs.python3}/bin/uvx";
    args = ["mcp-server-sentry"];
    env = {
      SENTRY_AUTH_TOKEN = "\${SENTRY_AUTH_TOKEN}";
      SENTRY_ORG = "my-org";
    };
  };
};
```

## Testing New Servers

### 1. Rebuild System

```bash
sudo nixos-rebuild switch
home-manager switch
```

### 2. Verify Configuration

```bash
# Check if config was generated
cat ~/.mcp.json | jq '.mcpServers | keys'

# Check mcp-cli config
cat ~/.config/mcp/mcp_servers.json | jq '.mcpServers | keys'
```

### 3. Test with mcp-cli

```bash
# List all servers (should include new server)
mcp-cli

# Test new server
mcp-cli myserver

# Execute a tool
mcp-cli myserver/some_tool '{"arg": "value"}'
```

### 4. Test with Claude Code

```bash
# Start Claude Code
claude

# In the Claude Code session, verify MCP tools are available
# Ask Claude: "What MCP servers are available?"
# Ask Claude to use the new server
```

## Troubleshooting

### Server Not Appearing

1. **Check configuration syntax**:
   ```bash
   nix-instantiate --eval --strict -A home-manager.users.youruser
   ```

2. **Verify MCP config**:
   ```bash
   cat ~/.mcp.json | jq '.mcpServers.myserver'
   ```

3. **Check Claude Code logs**:
   ```bash
   tail -f ~/.claude/logs/claude-*.log
   ```

### Server Fails to Start

1. **Test command directly**:
   ```bash
   # Copy command from ~/.mcp.json
   npx -y @modelcontextprotocol/server-myserver
   ```

2. **Check environment variables**:
   ```bash
   env | grep MY_SERVICE
   ```

3. **Verify secrets are readable**:
   ```bash
   cat /run/user/$(id -u)/agenix/my-secret
   ```

### Authentication Issues

1. **For gh-based auth**:
   ```bash
   gh auth status
   gh auth login
   ```

2. **For agenix secrets**:
   ```bash
   # Verify secret file exists
   ls -l /run/user/$(id -u)/agenix/

   # Check permissions
   stat /run/user/$(id -u)/agenix/my-secret
   ```

## Finding More MCP Servers

### Official Servers

- **Anthropic MCP Servers**: https://github.com/modelcontextprotocol/servers
  - filesystem, sqlite, postgres, brave-search, fetch, github, memory, puppeteer

### Community Servers

- **Awesome MCP Servers**: https://github.com/punkpeye/awesome-mcp-servers
  - 100+ community servers for various services

### Search npm Registry

```bash
npm search mcp-server
npm search @modelcontextprotocol
```

### Check mcp-servers-nix

```bash
# See available modules
nix flake show github:andythigpen/mcp-servers-nix
```

## Best Practices

1. **Start with official servers**: Use @modelcontextprotocol packages first
2. **Use passwordCommand**: For Claude Code, prefer passwordCommand over env vars
3. **Restrict filesystem access**: Only grant access to necessary directories
4. **Test with mcp-cli first**: Verify servers work before using in Claude
5. **Document requirements**: Add comments explaining setup requirements
6. **Update system prompt**: Add new server descriptions to extraInstructions

## Example: Complete Setup for New Server

```nix
# 1. Add to home/ai/mcp.nix
settings.servers.jira = {
  command = "${pkgs.python3}/bin/uvx";
  args = ["mcp-server-jira"];
  env = {
    JIRA_URL = "https://mycompany.atlassian.net";
    JIRA_EMAIL = "user@example.com";
    JIRA_API_TOKEN = "\${JIRA_API_TOKEN}";
  };
  passwordCommand = {
    JIRA_API_TOKEN = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "${pkgs.coreutils}/bin/cat /run/user/$(${pkgs.coreutils}/bin/id -u)/agenix/jira-token"
    ];
  };
};

# 2. Create encrypted secret
# $ echo "your-jira-api-token" | agenix -e secrets/jira-token.age

# 3. Register secret in configuration.nix
age.secrets.jira-token.file = ./secrets/jira-token.age;

# 4. Document in system prompt
services.ai.systemPrompt.extraInstructions = ''
  ## Jira Integration

  Use the jira MCP server for issue tracking:
  - List issues: mcp-cli jira/list_issues
  - Create issue: mcp-cli jira/create_issue
  - Update issue: mcp-cli jira/update_issue
'';

# 5. Rebuild and test
# $ sudo nixos-rebuild switch
# $ home-manager switch
# $ mcp-cli jira
```

## References

- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **Claude Code MCP Docs**: https://docs.claude.com/en/docs/claude-code/mcp
- **mcp-servers-nix**: https://github.com/andythigpen/mcp-servers-nix
- **Anthropic MCP Servers**: https://github.com/modelcontextprotocol/servers
- **Awesome MCP Servers**: https://github.com/punkpeye/awesome-mcp-servers
