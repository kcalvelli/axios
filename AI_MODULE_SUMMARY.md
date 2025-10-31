# AI Module Implementation Summary

## Overview
Successfully implemented a comprehensive AI module for axiOS that consolidates all AI-related tools and services with a "convention over configuration" approach.

## What Was Created

### NixOS Module (`modules/ai/`)
- **`default.nix`** - Main module with `services.ai.enable` option
  - Auto-adds all users to `systemd-journal` group for mcp-journal access
  - Configures Caddy reverse proxy for OpenWebUI at `${hostname}.${tailnet}/ai/*`
  
- **`ollama.nix`** - GPU-accelerated AI inference
  - AMD ROCm + OpenCL support
  - Ollama service with ROCm acceleration (rocmOverrideGfx: 10.3.0)
  - OpenWebUI on port 8080
  
- **`packages.nix`** - AI development tools
  - copilot-cli (from nix-ai-tools)
  - claude-code (from nix-ai-tools)
  - whisper-cpp

### Home-Manager Module (`home/ai/`)
- **`default.nix`** - Conditionally imports AI tools when `services.ai.enable` is true
- **`claude-code.nix`** - Configuration for both Claude Code and GitHub Copilot CLI
  - Shared MCP server configuration for both tools
  - MCP servers configured:
    - **mcp-journal** - Journal log access via custom server
    - **nixos** - NixOS package/option search
    - **sequential-thinking** - Enhanced reasoning (TypeScript version via npx)
    - **context7** - Advanced context management
    - **filesystem** - Restricted to `/tmp` and `~/Projects`
  - Creates `~/.claude/.claude.json` for Claude Code
  - Creates `~/.copilot/mcp-config.json` for GitHub Copilot CLI

## Usage

### Enable AI Module in Host Config
```nix
# In hosts/yourhost.nix
modules = {
  ai = true;  # Enable AI services
  # ... other modules
};

# Or in extraConfig
services.ai.enable = true;
```

### What Gets Enabled
When `services.ai.enable = true`:
- ✅ Ollama with ROCm acceleration (port 11434)
- ✅ OpenWebUI accessible at `http://edge.taile0fb4.ts.net/` (main domain via Caddy)
- ✅ copilot-cli, claude-code, whisper-cpp installed system-wide
- ✅ All users added to `systemd-journal` group
- ✅ Claude-code configured with MCP servers for all users
- ✅ Caddy reverse proxy enabled for OpenWebUI

## Breaking Changes

### Removed Services
- ❌ `services.openwebui.enable` - Use `services.ai.enable` instead
- ❌ `services.caddy-proxy.enable` - Caddy now always enabled when services module is loaded

### Moved Packages
- `copilot-cli` moved from development.nix to AI module
- `whisper-cpp` moved from development.nix to AI module

## Architecture

### Module Flow
```
Host Config (services.ai.enable = true)
  ↓
NixOS AI Module
  ├─ Adds users to systemd-journal group
  ├─ Enables ollama + ROCm + OpenWebUI
  ├─ Installs AI packages
  └─ Configures Caddy reverse proxy
  
Home-Manager Profiles (workstation/laptop)
  ├─ Import home/ai module
  └─ Conditionally enable claude-code if services.ai.enable
```

### MCP Server Architecture
```
claude-code (CLI)
  ↓
MCP Protocol (stdio)
  ├─ mcp-journal → journalctl queries
  ├─ nixos → nix package search
  ├─ sequential-thinking → reasoning
  ├─ context7 → context management
  └─ filesystem → file operations
```

## Files Changed
```
16 files changed, 310 insertions(+), 106 deletions(-)

New files:
+ home/ai/claude-code.nix
+ home/ai/default.nix
+ modules/ai/default.nix
+ modules/ai/ollama.nix
+ modules/ai/packages.nix

Modified files:
~ flake.nix (added mcp-journal input)
~ flake.lock (locked mcp-journal)
~ home/default.nix (exported ai module)
~ home/laptop.nix (imported ai module)
~ home/workstation.nix (imported ai module)
~ lib/default.nix (added ai module support)
~ modules/default.nix (exported ai module)
~ modules/development.nix (removed AI packages)
~ modules/services/caddy.nix (always enabled)
~ modules/services/default.nix (removed openwebui)

Deleted files:
- modules/services/openwebui.nix (moved to ai module)
```

## Testing
```bash
# Check flake
nix flake check --no-build

# Enable in host config
# Update your host's modules section with ai = true

# Rebuild and test
sudo nixos-rebuild switch --flake .#yourhost
```

## Future Enhancements
- [ ] Add more MCP servers (GitHub, GitLab, Brave Search)
- [ ] Support for multiple claude-code account tiers (max, pro)
- [ ] Configurable ollama models
- [ ] Rate limiting and security policies for MCP servers
- [ ] Integration with more AI services (OpenAI, local models)

## References
- [MCP Journal](https://github.com/kcalvelli/mcp-journal) - Custom MCP server for journalctl
- [nix-ai-tools](https://github.com/numtide/nix-ai-tools) - AI development tools
- [Claude Code Reference](https://github.com/timblaktu/nixcfg/tree/main/home/modules/claude-code) - Configuration reference
