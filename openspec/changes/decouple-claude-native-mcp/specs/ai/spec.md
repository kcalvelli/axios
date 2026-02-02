# AI & Development Assistance — Delta

## MODIFIED Requirements

### Model Context Protocol (MCP)

**Was:**
- Claude Code spawns MCP servers natively via `~/.mcp.json`
- `mcp-cli` binary provided by axios (`modules/ai/default.nix`)
- mcp-cli system prompt deployed to `~/.config/ai/prompts/mcp-cli.md`
- axios system prompt contains mcp-cli usage instructions

**Now:**
- Claude Code uses built-in tools only; MCP servers accessed via `/mcp-cli` skill
- `~/.mcp.json` generation disabled by default (`generateClaudeConfig = false`)
- `mcp-cli` binary provided by mcp-gateway module (`home.packages`)
- `/mcp-cli` skill installed to `~/.claude/commands/mcp-cli.md` by mcp-gateway
- mcp-cli prompt removed from axios (superseded by skill)
- axios system prompt trimmed to PIM domain hints only

#### Scenario: Claude Code discovers MCP tools on demand
- **Given**: Claude Code is running without native MCP servers
- **When**: The user asks to perform an action requiring an MCP tool
- **Then**: Claude Code invokes the `/mcp-cli` skill
- **And**: The skill guides discovery via `mcp-cli` commands in Bash

#### Scenario: mcp-cli binary is available after rebuild
- **Given**: `services.mcp-gateway.enable = true` (via `services.ai.mcp.enable`)
- **When**: The system is rebuilt
- **Then**: `mcp-cli` is available in PATH (provided by mcp-gateway module)

### System Prompt Management

**Was:**
- Unified prompt at `~/.config/ai/prompts/axios.md` contained mcp-cli usage section
- Separate mcp-cli prompt at `~/.config/ai/prompts/mcp-cli.md`

**Now:**
- Unified prompt contains PIM domain hints and custom user instructions only
- mcp-cli prompt removed (functionality moved to `/mcp-cli` skill)

### MCP Gateway (External Repository)

**Was:**
- Generates `~/.mcp.json` by default for Claude Code native MCP
- Does not provide mcp-cli binary or skill

**Now:**
- `generateClaudeConfig` defaults to `false` (no `~/.mcp.json`)
- New option `generateClaudeSkill` (default: `true`) installs `/mcp-cli` skill
- Provides `mcp-cli` binary via `home.packages`

Updated architecture diagram:
```
┌─────────────────────────────────────────────────────────────────┐
│                   axios (home/ai/mcp.nix)                       │
│  - Imports mcp-gateway's home-manager module                    │
│  - Provides server definitions with resolved nix store paths    │
│  - Adds system prompts (PIM hints), commands, ~/.claude/CLAUDE.md│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    mcp-gateway module                           │
│  - Evaluates server declarations                                │
│  - Generates ~/.config/mcp/mcp_servers.json                     │
│  - Installs mcp-cli binary + /mcp-cli skill for Claude Code    │
│  - Configures systemd service                                   │
└─────────────────────────────────────────────────────────────────┘
```
