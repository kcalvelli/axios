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
- **`claude-code.nix`** - MCP configuration using mcphost
  - Creates `~/.mcphost.yml` configuration file
  - Works with Claude, OpenAI, Gemini, and Ollama
  - MCP servers configured:
    - **journal** - Journal log access via custom mcp-journal server
    - **mcp-nixos** - NixOS package/option search
    - **sequential-thinking** - Enhanced reasoning
    - **context7** - Advanced context management
    - **filesystem** - Restricted to `/tmp` and `~/Projects`
  - Exports `update-material-code-theme` script to `~/scripts/`

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
- ✅ copilot, claude, mcphost, whisper-cli installed system-wide
- ✅ All users added to `systemd-journal` group
- ✅ `~/.mcphost.yml` configuration file created
- ✅ `update-material-code-theme` script in `~/scripts/`
- ✅ Caddy reverse proxy enabled for OpenWebUI

### Using MCP Servers with AI Models

After enabling AI and rebuilding, use `mcphost` to chat with AI models that have MCP server access:

```bash
# With Anthropic Claude
mcphost --model anthropic:claude-sonnet-4
# or
export ANTHROPIC_API_KEY="your-key"
mcphost --model anthropic:claude-sonnet-4

# With local Ollama (no API key needed!)
mcphost --model ollama:mistral

# With OpenAI
export OPENAI_API_KEY="your-key"
mcphost --model openai:gpt-4

# With Google Gemini
export GOOGLE_API_KEY="your-key"
mcphost --model google:gemini-2.0-flash-exp
```

All 5 MCP servers are automatically available:
- **journal** - System log access
- **mcp-nixos** - NixOS package search
- **sequential-thinking** - Enhanced reasoning
- **context7** - Context management  
- **filesystem** - File operations in `/tmp` and `~/Projects`

No manual setup required!

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
