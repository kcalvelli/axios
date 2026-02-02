# Decouple Claude Code from Native MCP Servers

## Motivation

Claude Code currently spawns 11 MCP servers natively via `~/.mcp.json`, consuming ~47K tokens of context window for tool definitions. Additionally, `passwordCommand` is broken in Claude Code's native MCP implementation (affecting GitHub token auth).

By removing `~/.mcp.json` and replacing it with the `/mcp-cli` skill for on-demand tool discovery, we:

1. **Reduce context usage by ~99%** (~47K tokens -> ~400 tokens)
2. **Fix GitHub auth** — `passwordCommand` works through mcp-cli -> mcp-gateway path
3. **Clean ownership boundaries** — mcp-gateway owns mcp-cli binary + skill, axios provides server definitions

## Architecture

**Before:**
```
Claude Code -> ~/.mcp.json -> spawns 11 MCP servers natively (~47K tokens)
```

**After:**
```
Claude Code -> built-in tools + /mcp-cli skill -> mcp-cli -> mcp_servers.json (~400 tokens)
```

Ownership:
- **axios**: Server definitions with Nix store paths, PIM domain hints in system prompt
- **mcp-gateway**: Config generation, mcp-cli binary, /mcp-cli skill, REST API
- **Claude Code**: Built-in tools + invokes /mcp-cli skill when external tools needed

## Changes

### mcp-gateway
- `generateClaudeConfig` default: `true` -> `false` (stop generating `~/.mcp.json`)
- New option: `generateClaudeSkill` (default: `true`) — installs `~/.claude/commands/mcp-cli.md`
- Add `mcp-cli` package to module's `home.packages` (moved from axios)
- New file: `commands/mcp-cli.md` (skill source based on upstream SKILL.md)

### axios
- Remove `mcp-cli` from `environment.systemPackages` (now in mcp-gateway module)
- Remove `~/.config/ai/prompts/mcp-cli.md` deployment from `home/ai/mcp.nix`
- Delete `home/ai/prompts/mcp-cli-system-prompt.md` (superseded by skill)
- Remove "MCP Tools via mcp-cli" section from `axios-system-prompt.md` (replaced by skill)

## What Stays the Same

- Server definitions in `home/ai/mcp.nix`
- `~/.config/mcp/mcp_servers.json` generation
- mcp-gateway REST API service
- `~/.claude/CLAUDE.md` with `@import` of axios prompt
- `GEMINI_SYSTEM_MD` env var
- OpenSpec commands (`/proposal`, `/apply`, `/archive`)
