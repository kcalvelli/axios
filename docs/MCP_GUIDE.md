# MCP (Model Context Protocol) Guide for axiOS

Complete guide to using MCP servers in axiOS for enhanced AI capabilities with Claude Code and other AI tools.

## Table of Contents

- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [MCP Architecture](#mcp-architecture)
- [Available MCP Servers](#available-mcp-servers)
- [Configuration Guide](#configuration-guide)
- [Tool Discovery](#tool-discovery)
- [Real-World Workflows](#real-world-workflows)
- [Secrets Management](#secrets-management)
- [Troubleshooting](#troubleshooting)

## Introduction

### What is MCP?

Model Context Protocol (MCP) is a standard protocol that allows AI models to access external tools and data sources. axiOS provides a declarative, pre-configured MCP setup that enables Claude Code and other AI assistants to:

- Access your filesystem, git repositories, and systemd logs
- Search the web with Brave Search
- Query documentation with Context7
- Access email and calendar/contacts via PIM tools
- Enhance reasoning with sequential-thinking
- And much more!

### What You Get with axiOS

When you enable `services.ai` in axiOS, you automatically get:

1. **11 Pre-configured MCP Servers** - No manual setup required
2. **On-demand tool discovery** - Via mcp-gateway's `mcp-gw` CLI (99% token reduction)
3. **Auto-generated configs** - `~/.mcp.json` for Claude Code
4. **System prompts** - Auto-injected into `~/.claude.json`
5. **Pre-packaged servers** - No runtime npm installs

## Quick Start

### Enable AI Tools

```nix
# In your NixOS configuration
{
  services.ai.enable = true;  # Enables all AI tools and MCP servers
}
```

Rebuild your system:
```bash
sudo nixos-rebuild switch
```

### Verify Installation

```bash
# Check mcp-gateway health
curl -s http://localhost:8085/health

# List all MCP servers via gateway API
curl -s http://localhost:8085/api/servers | jq

# List available tools
curl -s http://localhost:8085/api/tools | jq 'length'

# View axios system prompt
cat ~/.config/ai/prompts/axios.md

# Check Claude Code MCP config
cat ~/.mcp.json | jq '.mcpServers | keys'
```

### First Use

1. Restart Claude Code to load the new configuration
2. The axios system prompt is automatically injected
3. Tools are discovered on-demand via mcp-gateway

## MCP Architecture

### How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Claude Code   │     │   Claude.ai     │     │  Custom Apps    │
│   (Native MCP)  │     │  (Integrations) │     │  (REST API)     │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │                       └───────────┬───────────┘
         │                                   │
    ┌────▼───────────────────────────────────▼────┐
    │              mcp-gateway                     │
    │  - REST API (/api/tools/*)                  │
    │  - MCP HTTP Transport (/mcp)                │
    │  - Systemd user service                     │
    └────────────────────┬────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼───┐      ┌────▼───┐      ┌────▼───┐
    │  git   │      │ github │      │  ...   │
    │ server │      │ server │      │ 10 more│
    └────────┘      └────────┘      └────────┘
```

### Configuration Files

The mcp-gateway module (from `github.com/kcalvelli/mcp-gateway`) generates these files:

- **`~/.mcp.json`**: Claude Code MCP configuration (native integration)
- **`~/.config/mcp/mcp_servers.json`**: mcp-gateway configuration (used by `mcp-gw`)
- **`~/.gemini/settings.json`**: Gemini CLI configuration
- **`~/.config/ai/prompts/axios.md`**: Comprehensive system prompt
- **`~/.claude.json`**: Claude Code config (auto-injected with axios prompt)

### Declarative Configuration

axiOS uses a two-layer declarative approach:

1. **mcp-gateway** (external repo) provides the home-manager module
2. **axios** imports the module and defines servers with resolved package paths

```nix
# axios: home/ai/mcp.nix
{
  imports = [ inputs.mcp-gateway.homeManagerModules.default ];

  services.mcp-gateway = {
    enable = true;
    servers = {
      git = {
        enable = true;
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
      };
      github = {
        enable = true;
        command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
        args = [ "stdio" ];
        passwordCommand.GITHUB_PERSONAL_ACCESS_TOKEN = [ "gh" "auth" "token" ];
      };
      # ... more servers ...
    };
  };
}
```

Benefits:
- **Single source of truth**: mcp-gateway owns all config generation
- **Nix-packaged**: Pre-built MCP servers from `mcp-servers-nix` overlay
- **Reproducible**: Same config across all machines
- **Type-safe**: Nix validates configuration
- **Multi-tool**: Generates configs for Claude Code, Gemini, and mcp-gateway

## Available MCP Servers

When `services.ai.enable = true`, these MCP servers are automatically configured:

| Server | Purpose | Setup Required | Status |
|--------|---------|----------------|--------|
| **time** | Date/time utilities | None | Ready |
| **github** | GitHub API access | `gh auth login` | Requires auth |
| **journal** | systemd logs | None | Ready |
| **context7** | Library documentation | None | Ready |
| **axios-ai-mail** | AI-powered email | PIM module | Ready |
| **mcp-dav** | Calendar and contacts | PIM module | Ready |
| **brave-search** | Web search | API key | Requires key |

### Server Details

#### Core Tools (No Setup)

- **time**: Timezones, date calculations
- **journal**: Query systemd logs
- **github**: Requires `gh auth login` (uses gh CLI for auth)

#### PIM Integration (Requires `modules.pim = true`)

- **axios-ai-mail**: AI-powered email access and management
- **mcp-dav**: Calendar and contacts via CalDAV/CardDAV (from axios-dav)

#### AI Enhancement (No Setup)

- **context7**: Query official documentation for any library

#### Search (Requires API Key)

- **brave-search**: Web search via Brave Search API
  - Get key: https://brave.com/search/api/
  - Configure via agenix secret or `$BRAVE_API_KEY` env var

## Configuration Guide

### Adding New MCP Servers

Server definitions live in `home/ai/mcp.nix`. Here's how to add new servers:

#### Example: Add SQLite and Docker Servers

Edit `home/ai/mcp.nix` and add to the `servers` block:

```nix
services.mcp-gateway.servers = {
  # ... existing servers ...

  sqlite = {
    enable = true;
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sqlite"
      "--db-path"
      "${config.home.homeDirectory}/.local/share/myapp/db.sqlite"
    ];
  };

  docker = {
    enable = true;
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-docker"
    ];
  };
};
```

Rebuild:
```bash
sudo nixos-rebuild switch  # Or home-manager switch
curl -s http://localhost:8085/api/servers | jq  # Verify new servers appear
```

#### Example: Add Notion Server

```nix
notion = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-notion"
  ];
  env = {
    NOTION_API_KEY = "\${NOTION_API_KEY}";  # Escape $ for Nix
  };
};
```

Set the API key in your NixOS config:
```nix
environment.sessionVariables = {
  NOTION_API_KEY = "your-notion-api-key";
};
```

### Server Types

#### NPM-based Servers (Most Common)

```nix
server-name = {
  enable = true;
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"  # Auto-confirm install
    "@modelcontextprotocol/server-name"
    # ... additional args ...
  ];
};
```

#### Pre-packaged Servers (from mcp-servers-nix)

```nix
# These are pre-built - no runtime npm install
git = {
  enable = true;
  command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
};
```

#### Custom Binary Servers

```nix
custom-server = {
  enable = true;
  command = "${pkgs.myPackage}/bin/mcp-server";
  args = [ "--config" "/path/to/config" ];
};
```

#### Servers from External Flakes

```nix
external-server = {
  enable = true;
  command = "${inputs.some-mcp-server.packages.${system}.default}/bin/server";
};
```

## Tool Discovery

mcp-gateway provides multiple ways to discover and execute MCP tools:

### mcp-gateway REST API

```bash
# List all servers
curl -s http://localhost:8085/api/servers | jq

# List all tools
curl -s http://localhost:8085/api/tools | jq

# Execute a tool
curl -s -X POST http://localhost:8085/api/tools/github/search_repositories \
  -H "Content-Type: application/json" \
  -d '{"query": "axios"}'
```

### mcp-gw CLI (provided by mcp-gateway)

mcp-gateway also installs `mcp-gw` for CLI-based tool discovery. See the mcp-gateway documentation for usage details.

## Real-World Workflows

### Workflow 1: Debugging with Logs

```bash
# Query logs via gateway API
curl -s -X POST http://localhost:8085/api/tools/journal/query_logs \
  -H "Content-Type: application/json" \
  -d '{"unit": "nginx", "priority": "err"}'
```

### Workflow 2: GitHub Operations

```bash
# Search repositories
curl -s -X POST http://localhost:8085/api/tools/github/search_repositories \
  -H "Content-Type: application/json" \
  -d '{"query": "nix MCP"}'
```

## Secrets Management

### Environment Variables (Current Approach)

axios uses environment variables for MCP API keys:

```nix
# In your NixOS configuration
{
  environment.sessionVariables = {
    BRAVE_API_KEY = "your-api-key-here";
    GITHUB_TOKEN = "ghp_your_token";  # Optional, gh CLI handles this
  };
}
```

**Important**: Environment variables are stored in the Nix store (world-readable). This is suitable for:
- Non-critical API keys
- Development environments
- Personal machines

### Security Considerations

For sensitive keys in production:

1. **Use agenix** (not currently automated for MCP):
   ```nix
   age.secrets.api-key = {
     file = ./secrets/api-key.age;
     owner = "username";
     mode = "0400";
   };
   ```

2. **Load via script**:
   ```nix
   environment.sessionVariables = {
     BRAVE_API_KEY = "$(cat /run/secrets/brave-api-key)";
   };
   ```

3. **Use password managers**:
   ```bash
   export BRAVE_API_KEY=$(pass show brave-api-key)
   ```

### Required API Keys

- **Brave Search**: Get from https://brave.com/search/api/
  - Free tier: 2,000 queries/month
  - Set `BRAVE_API_KEY` environment variable

- **GitHub**: Use gh CLI authentication (recommended)
  ```bash
  gh auth login
  ```
  - Alternatively, set `GITHUB_TOKEN`

## Troubleshooting

### Issue: brave-search server fails

**Symptoms**: Server not appearing or failing to execute

**Solutions**:
1. Verify API key is configured via agenix or `$BRAVE_API_KEY`
2. Check that you rebuilt system: `sudo nixos-rebuild switch`
3. Log out and log back in to load new environment variables
4. Restart Claude Code

### Issue: github server unavailable

**Symptoms**: GitHub tools not working

**Solutions**:
1. Run `gh auth login` to authenticate
2. Verify authentication: `gh auth status`
3. Alternatively, set `GITHUB_TOKEN` environment variable

### Issue: MCP servers not appearing in Claude Code

**Symptoms**: Claude Code doesn't see MCP tools

**Solutions**:
1. Verify config exists: `cat ~/.mcp.json`
2. Check server list: `curl -s http://localhost:8085/api/servers | jq`
3. Restart Claude Code completely
4. Check mcp-gateway service: `systemctl --user status mcp-gateway`

### Issue: Server executes but returns errors

**Symptoms**: Tool execution fails with error messages

**Solutions**:
1. Check server logs: `journalctl --user -u mcp-*`
2. Test server directly: `npx -y @modelcontextprotocol/server-name`
3. Verify all dependencies are available
4. Check permissions for file access servers

### Debugging Tips

**View MCP server configuration**:
```bash
cat ~/.mcp.json | jq '.mcpServers'
```

**Check mcp-gateway service**:
```bash
systemctl --user status mcp-gateway
journalctl --user -u mcp-gateway -f
```

**Test mcp-gateway API**:
```bash
curl http://localhost:8085/health
curl http://localhost:8085/api/servers | jq
curl http://localhost:8085/api/tools | jq 'length'
```

**Test a server manually**:
```bash
npx -y @modelcontextprotocol/server-git
```

**Check axios system prompt**:
```bash
cat ~/.config/ai/prompts/axios.md | less
```

**Restart mcp-gateway after changes**:
```bash
systemctl --user restart mcp-gateway
```

## MCP Gateway

mcp-gateway provides additional access methods beyond native MCP:

### REST API

Access tools via HTTP:
```bash
# List all tools
curl http://localhost:8085/api/tools | jq

# Execute a tool
curl -X POST http://localhost:8085/api/tools/git/git_status \
  -H "Content-Type: application/json" \
  -d '{"repo_path": "/home/user/project"}'
```

### MCP HTTP Transport

For Claude.ai Integrations (when exposed via Tailscale):
- Endpoint: `https://your-host.tailnet.ts.net:8085/mcp`
- Protocol: MCP over HTTP/SSE (2025-06-18 spec)

### Web UI

Visual management at `http://localhost:8085`:
- Server status overview
- Tool browser with schema viewer
- Tool testing interface

## Further Reading

- **mcp-gateway Repository**: https://github.com/kcalvelli/mcp-gateway
- **Quick Reference**: See `docs/MCP_REFERENCE.md` for command reference
- **Anthropic Beta Features**: See `docs/advanced-tool-use.md` for upcoming API features
- **System Prompts**: See `~/.config/ai/prompts/axios.md` for complete AI assistant guide

## Contributing

Found a useful MCP server? Add it to `home/ai/mcp.nix` with a pull request!

---

**Need help?** Open an issue at https://github.com/kcalvelli/axios/issues
