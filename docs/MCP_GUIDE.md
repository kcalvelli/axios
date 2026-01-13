# MCP (Model Context Protocol) Guide for axiOS

Complete guide to using MCP servers in axiOS for enhanced AI capabilities with Claude Code and other AI tools.

## Table of Contents

- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [MCP Architecture](#mcp-architecture)
- [Available MCP Servers](#available-mcp-servers)
- [Configuration Guide](#configuration-guide)
- [mcp-cli Usage](#mcp-cli-usage)
- [Real-World Workflows](#real-world-workflows)
- [Secrets Management](#secrets-management)
- [Troubleshooting](#troubleshooting)

## Introduction

### What is MCP?

Model Context Protocol (MCP) is a standard protocol that allows AI models to access external tools and data sources. axiOS provides a declarative, pre-configured MCP setup that enables Claude Code and other AI assistants to:

- Access your filesystem, git repositories, and systemd logs
- Search the web with Brave Search
- Query documentation with Context7
- Control hardware like Ultimate64 C64 emulators
- Enhance reasoning with sequential-thinking
- And much more!

### What You Get with axiOS

When you enable `services.ai` in axiOS, you automatically get:

1. **10 Pre-configured MCP Servers** - No manual setup required
2. **mcp-cli** - Dynamic tool discovery (99% token reduction)
3. **Auto-generated configs** - `~/.mcp.json` for Claude Code
4. **System prompts** - Auto-injected into `~/.claude.json`
5. **Pre-packaged servers** - No runtime npm installs

### Token Efficiency

**Traditional MCP**: Loads all tool schemas upfront
- 10 servers = 47,000 tokens per message
- 5-turn conversation = 242,450 total tokens
- Cost: $0.73 per session

**axiOS with mcp-cli**: Discovers tools on-demand
- Initial load = 2,000 tokens (system prompt only)
- Discovery as-needed = ~500 tokens
- 5-turn conversation = 7,850 total tokens
- Cost: $0.02 per session

**Result: 96.8% token reduction, 30x more efficient**

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
# List all MCP servers
mcp-cli

# Test dynamic discovery
mcp-cli grep "file"

# View axios system prompt
cat ~/.config/ai/prompts/axios.md

# Check Claude Code MCP config
cat ~/.mcp.json | jq '.mcpServers | keys'
```

### First Use

1. Restart Claude Code to load the new configuration
2. The axios system prompt is automatically injected
3. Use mcp-cli commands to discover and use tools
4. Tools are loaded on-demand, not upfront

## MCP Architecture

### How It Works

```
┌─────────────────┐
│   Claude Code   │
│   (AI Agent)    │
└────────┬────────┘
         │
         ├──────────┐
         │          │
    ┌────▼───┐  ┌──▼──────┐
    │ Native │  │ mcp-cli │  Dynamic discovery
    │  MCP   │  │ (Bash)  │  (99% token savings)
    └────┬───┘  └──┬──────┘
         │         │
         └────┬────┘
              │
     ┌────────▼─────────┐
     │  MCP Servers     │
     │  (10 configured) │
     └──────────────────┘
              │
     ┌────────▼─────────┐
     │  External APIs   │
     │  File System     │
     │  System Services │
     └──────────────────┘
```

### Configuration Files

axiOS automatically generates these files:

- **`~/.mcp.json`**: Claude Code MCP configuration (native integration)
- **`~/.config/mcp/mcp_servers.json`**: mcp-cli configuration (same servers)
- **`~/.config/ai/prompts/axios.md`**: Comprehensive system prompt
- **`~/.claude.json`**: Claude Code config (auto-injected with axios prompt)

All files are generated from a single source: `home/ai/mcp.nix`

### Declarative Configuration

axiOS uses a declarative approach:

```nix
# home/ai/mcp.nix
programs.claude-code.mcpServers = {
  git = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [ "-y" "@modelcontextprotocol/server-git" ];
  };
  # ... more servers ...
};
```

Benefits:
- **Single source of truth**: Define once, use everywhere
- **Nix-packaged**: No runtime downloads or version conflicts
- **Reproducible**: Same config across all machines
- **Type-safe**: Nix validates configuration

## Available MCP Servers

When `services.ai.enable = true`, these MCP servers are automatically configured:

| Server | Purpose | Setup Required | Confidence |
|--------|---------|----------------|------------|
| **git** | Git operations | None | Ready |
| **github** | GitHub API access | `gh auth login` | Requires auth |
| **filesystem** | File read/write | None | Ready |
| **journal** | systemd logs | None | Ready |
| **nix-devshell-mcp** | Nix dev environments | None | Ready |
| **sequential-thinking** | Enhanced AI reasoning | None | Ready |
| **context7** | Library documentation | None | Ready |
| **time** | Date/time utilities | None | Ready |
| **brave-search** | Web search | API key via env var | Requires key |
| **ultimate64** | C64 emulator control | Hardware on LAN | Requires hardware |

### Server Details

#### Core Tools (No Setup)

- **git**: Git status, diffs, commits, branches
- **filesystem**: Read/write files (restricted to safe paths)
- **time**: Timezones, date calculations
- **journal**: Query systemd logs

#### Development (No Setup)

- **nix-devshell-mcp**: Nix devshell integration
- **github**: Requires `gh auth login` (uses gh CLI for auth)

#### AI Enhancement (No Setup)

- **sequential-thinking**: Chain-of-thought reasoning for complex problems
- **context7**: Query official documentation for any library

#### Search (Requires API Key)

- **brave-search**: Web search via Brave Search API
  - Get key: https://brave.com/search/api/
  - Configure via `environment.sessionVariables.BRAVE_API_KEY`

#### Hardware (Requires Hardware)

- **ultimate64**: Control Ultimate64 C64 emulator
  - Requires Ultimate64 device on local network
  - Stream video/audio, transfer files, execute programs

## Configuration Guide

### Adding New MCP Servers

axiOS includes 100+ example MCP server configurations in `home/ai/mcp-examples.nix`. Here's how to add new servers:

#### Example: Add SQLite and Docker Servers

Edit `home/ai/mcp.nix`:

```nix
# Add to existing settings.servers block
settings.servers = {
  # ... existing servers ...

  sqlite = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sqlite"
      "--db-path"
      "${config.home.homeDirectory}/.local/share/myapp/db.sqlite"
    ];
  };

  docker = {
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
home-manager switch
mcp-cli  # Verify new servers appear
```

#### Example: Add Notion Server

```nix
notion = {
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

Set the API key:
```nix
environment.sessionVariables = {
  NOTION_API_KEY = "your-notion-api-key";
};
```

### Server Types

#### NPM-based Servers (Most Common)

```nix
server-name = {
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"  # Auto-confirm install
    "@modelcontextprotocol/server-name"
    # ... additional args ...
  ];
};
```

#### Custom Binary Servers

```nix
custom-server = {
  command = "${pkgs.myPackage}/bin/mcp-server";
  args = [ "--config" "/path/to/config" ];
};
```

#### Packaged Nix Servers

```nix
nix-server = {
  command = "${inputs.some-mcp-server.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/server";
  args = [];
};
```

## mcp-cli Usage

### Basic Commands

```bash
# List all MCP servers
mcp-cli

# Search for tools by name
mcp-cli grep "file"
mcp-cli grep "github"

# List tools for a specific server
mcp-cli github
mcp-cli filesystem

# Get tool schema
mcp-cli github/create_repository
mcp-cli filesystem/read_file

# Execute a tool
mcp-cli github/search_repositories '{"query": "axios"}'
mcp-cli filesystem/list_directory '{"path": "/tmp"}'
```

### Advanced Usage

**Add `-d` for detailed descriptions:**
```bash
mcp-cli github -d  # Include tool descriptions
```

**Use stdin for complex JSON:**
```bash
echo '{"query": "test"}' | mcp-cli server/tool -
```

**Pipe output for processing:**
```bash
mcp-cli filesystem/list_directory '{"path": "/tmp"}' | jq '.files'
```

## Real-World Workflows

### Workflow 1: Adding SQLite MCP Server

**Task**: Add SQLite database access for AI agents

**Traditional Approach** (242K tokens, $0.73):
1. Load all 10 servers with full schemas (47K tokens/turn)
2. Agent searches through all tools
3. Multiple round trips with full context each time

**axiOS Approach** (7.8K tokens, $0.02):

```bash
# Turn 1: User request (2K tokens)
"Add SQLite MCP server to axios"

# Turn 2: Agent uses mcp-cli to discover servers (600 tokens)
mcp-cli

# Turn 3: Agent reads mcp.nix (3K tokens)
# Proposes configuration

# Turn 4: Agent edits file (600 tokens)
# Adds SQLite server config

# Turn 5: Agent verifies (450 tokens)
mcp-cli sqlite
```

**Result**: 96.8% token savings, $0.71 saved per session

### Workflow 2: Debugging with Logs

```bash
# Agent discovers journal tool
mcp-cli grep "log"

# Agent gets schema
mcp-cli journal/query_logs

# Agent queries nginx logs
mcp-cli journal/query_logs '{"unit": "nginx", "priority": "err"}'
```

### Workflow 3: GitHub Operations

```bash
# Search repositories
mcp-cli github/search_repositories '{"query": "nix MCP"}'

# Create issue
mcp-cli github/create_issue '{"repo": "owner/repo", "title": "Bug report"}'

# Get PR details
mcp-cli github/get_pull_request '{"repo": "owner/repo", "pr_number": 123}'
```

## Secrets Management

### Environment Variables (Current Approach)

axios uses environment variables for MCP API keys:

```nix
# In your NixOS configuration
{
  environment.sessionVariables = {
    BRAVE_API_KEY = "your-api-key-here";
    GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_your_token";  # Optional, gh CLI handles this
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
  - Alternatively, set `GITHUB_PERSONAL_ACCESS_TOKEN`

## Troubleshooting

### Issue: brave-search server fails

**Symptoms**: Server not appearing in mcp-cli or failing to execute

**Solutions**:
1. Verify API key is set: `echo $BRAVE_API_KEY`
2. Check that you rebuilt system: `sudo nixos-rebuild switch`
3. Log out and log back in to load new environment variables
4. Restart Claude Code

### Issue: github server unavailable

**Symptoms**: GitHub tools not working

**Solutions**:
1. Run `gh auth login` to authenticate
2. Verify authentication: `gh auth status`
3. Alternatively, set `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable

### Issue: MCP servers not appearing in Claude Code

**Symptoms**: Claude Code doesn't see MCP tools

**Solutions**:
1. Verify config exists: `cat ~/.mcp.json`
2. Check server list: `mcp-cli`
3. Restart Claude Code completely
4. Check system prompt injected: `grep -q "mcp-cli" ~/.claude.json && echo "✅ Enabled"`

### Issue: mcp-cli command not found

**Symptoms**: `mcp-cli: command not found`

**Solutions**:
1. Ensure `services.ai.enable = true` in your configuration
2. Rebuild: `home-manager switch`
3. Verify installation: `which mcp-cli`
4. Check PATH includes ~/.nix-profile/bin

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

**Test a server manually**:
```bash
npx -y @modelcontextprotocol/server-git
```

**Check axios system prompt**:
```bash
cat ~/.config/ai/prompts/axios.md | less
```

**Verify home-manager service**:
```bash
systemctl --user status home-manager.service
```

## Further Reading

- **MCP Examples**: See `home/ai/mcp-examples.nix` for 100+ server configurations
- **Quick Reference**: See `docs/MCP_REFERENCE.md` for command reference
- **Anthropic Beta Features**: See `docs/advanced-tool-use.md` for upcoming API features
- **System Prompts**: See `~/.config/ai/prompts/axios.md` for complete AI assistant guide

## Contributing

Found a useful MCP server? Add it to `home/ai/mcp-examples.nix` with a pull request!

---

**Need help?** Open an issue at https://github.com/kcalvelli/axios/issues
