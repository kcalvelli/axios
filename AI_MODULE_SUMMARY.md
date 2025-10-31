# AI Module Implementation Summary

## Overview
Comprehensive AI module for axiOS providing local and cloud AI capabilities with MCP (Model Context Protocol) server integration for Claude CLI.

## What Was Created

### NixOS Module (`modules/ai/`)
- **`default.nix`** - Main module with `services.ai.enable` option
  - Auto-adds all users to `systemd-journal` group for mcp-journal access
  - Configures Caddy reverse proxy for OpenWebUI
  
- **`ollama.nix`** - GPU-accelerated AI inference
  - AMD ROCm + OpenCL support
  - Ollama service with ROCm acceleration (rocmOverrideGfx: 10.3.0)
  - OpenWebUI on port 8080
  - **Auto-pulls default models**: `qwen2.5-coder:7b` and `llama3.1:8b`
  - Systemd service for model management
  
- **`packages.nix`** - AI development tools
  - copilot (GitHub Copilot CLI from nix-ai-tools)
  - claude (Claude Code CLI from nix-ai-tools)
  - whisper-cli (Voice transcription)

### Home-Manager Module (`home/ai/`)
- **`default.nix`** - Conditionally imports AI tools when `services.ai.enable` is true
- **`claude-code.nix`** - Claude CLI MCP configuration
  - Creates `~/.mcp.json.template` configuration file
  - MCP servers configured:
    - **journal** - Journal log access via custom mcp-journal server
    - **mcp-nixos** - NixOS package/option search
    - **sequential-thinking** - Enhanced reasoning
    - **context7** - Advanced context management
    - **filesystem** - Restricted to `/tmp` and `~/Projects`
  - Exports scripts to `~/scripts/`:
    - `update-material-code-theme` - Theme updater
    - `init-claude-mcp` - Initialize Claude CLI MCP config for projects

## Usage

### Enable AI Module in Host Config
```nix
# In hosts/yourhost.nix
modules = {
  ai = true;  # Enable AI services
  # ... other modules
};
```

### What Gets Enabled
When `services.ai.enable = true`:
- ✅ Ollama with ROCm acceleration (port 11434)
- ✅ **Auto-pulls default models**: `qwen2.5-coder:7b` (7B, ~4.7GB) and `llama3.1:8b` (8B, ~4.7GB)
- ✅ OpenWebUI accessible at `http://edge.taile0fb4.ts.net/` (main domain via Caddy)
- ✅ copilot, claude, whisper-cli installed system-wide
- ✅ All users added to `systemd-journal` group
- ✅ `~/.mcp.json.template` configuration file for Claude CLI
- ✅ `update-material-code-theme` script in `~/scripts/`
- ✅ `init-claude-mcp` script in `~/scripts/`
- ✅ Caddy reverse proxy enabled for OpenWebUI

### Using Ollama Models

After enabling AI and rebuilding, use Ollama directly or through OpenWebUI:

```bash
# With local Ollama CLI
ollama run qwen2.5-coder:7b  # Best for coding
ollama run llama3.1:8b       # General purpose

# Or use OpenWebUI at http://edge.taile0fb4.ts.net/
```

**Default Ollama Models:**
- `qwen2.5-coder:7b` - Specialized for code generation, debugging, and NixOS
- `llama3.1:8b` - General purpose, good at coding and conversation

These are automatically pulled on first boot. No manual setup required!

### Using Claude CLI with MCP Servers

Claude CLI has native MCP server support with all 5 MCP servers configured:
- **journal** - System log access via mcp-journal
- **mcp-nixos** - NixOS package search
- **sequential-thinking** - Enhanced reasoning
- **context7** - Context management
- **filesystem** - File operations in `/tmp` and `~/Projects`

Initialize MCP config for your projects:

```bash
# Initialize Claude MCP config for current project
~/scripts/init-claude-mcp

# Or for a specific project
~/scripts/init-claude-mcp ~/Projects/myproject

# Verify MCP servers are loaded
claude mcp list
```

This creates a `.mcp.json` file with all 5 MCP servers configured. The servers are automatically loaded when you start Claude CLI in that project directory.

### GitHub Copilot CLI

```bash
# GitHub Copilot CLI (requires GitHub account)
copilot
```

**Note**: GitHub Copilot CLI does **not** support MCP servers. MCP support is only available in the Copilot coding agent (VS Code, JetBrains, etc.).

## Architecture

### Module Flow
```
Host Config (services.ai.enable = true)
  ↓
NixOS AI Module
  ├─ Adds users to systemd-journal group
  ├─ Enables ollama + ROCm + OpenWebUI
  ├─ Auto-pulls qwen2.5-coder:7b and llama3.1:8b
  ├─ Installs AI packages (copilot, claude, whisper)
  └─ Configures Caddy reverse proxy for OpenWebUI

Home-Manager Profiles (workstation/laptop)
  ├─ Import home/ai module
  ├─ Create ~/.mcp.json.template for Claude CLI
  └─ Export utility scripts to ~/scripts/
```

### MCP Server Architecture
```
Claude CLI
  ↓
MCP Protocol (stdio)
  ├─ journal → journalctl queries via mcp-journal
  ├─ mcp-nixos → nix package/option search
  ├─ sequential-thinking → enhanced reasoning
  ├─ context7 → context management
  └─ filesystem → file operations (restricted paths)
```

### GPU Acceleration
```
AMD GPU (RX 6700 XT)
  ↓
ROCm + OpenCL
  ↓
Ollama (rocmOverrideGfx: 10.3.0)
  ↓
Local Model Inference
  ├─ qwen2.5-coder:7b
  └─ llama3.1:8b
```

## Breaking Changes

### Removed Services
- ❌ `services.openwebui.enable` - Use `services.ai.enable` instead
- ❌ Manual `claude mcp add` commands - Now uses declarative `.mcp.json` config

### Moved Packages
- `copilot-cli` moved from development.nix to AI module
- `whisper-cpp` moved from development.nix to AI module

### New Dependencies
- Added `mcp-journal` flake input (custom MCP server)

## Implementation Details

### Auto-Pull Ollama Models
A systemd oneshot service (`ollama-pull-models`) runs on first boot:
- Waits for Ollama service to be ready (30s timeout)
- Checks if models already exist
- Pulls missing models automatically
- Runs as root with `HOME=/root` and `OLLAMA_HOST=http://localhost:11434`
- `RemainAfterExit=true` prevents re-runs on subsequent boots

### MCP Configuration Files

#### Claude CLI Template Configuration (`~/.mcp.json.template`)
Declaratively created in Claude CLI's format:
```json
{
  "mcpServers": {
    "journal": {
      "type": "stdio",
      "command": "/nix/store/.../mcp-journal",
      "args": [],
      "env": {}
    },
    "mcp-nixos": {
      "type": "stdio",
      "command": "nix",
      "args": ["run", "github:utensils/mcp-nixos", "--"],
      "env": {
        "MCP_NIXOS_CLEANUP_ORPHANS": "true"
      }
    }
    // ... other servers
  }
}
```

The `init-claude-mcp` script copies this template to your project as `.mcp.json`.

## Files Changed/Created
```
New files:
+ home/ai/claude-code.nix (Claude CLI MCP configuration)
+ home/ai/default.nix
+ modules/ai/default.nix
+ modules/ai/ollama.nix (with auto-pull service)
+ modules/ai/packages.nix
+ scripts/init-claude-mcp.sh (Claude CLI MCP initializer)
+ AI_MODULE_SUMMARY.md (this file)

Modified files:
~ flake.nix (added mcp-journal input)
~ flake.lock (locked mcp-journal)
~ home/default.nix (exported ai module)
~ home/laptop.nix (imported ai module)
~ home/workstation.nix (imported ai module)
~ lib/default.nix (added ai module support)
~ modules/default.nix (exported ai module)
~ modules/development.nix (removed AI packages)
~ modules/services/caddy.nix (simplified)
~ modules/services/default.nix (removed openwebui)
~ docs/ENABLING_SERVICES.md (updated AI services section)

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

# Check model download status
systemctl status ollama-pull-models
journalctl -u ollama-pull-models -f

# Test Claude CLI with MCP servers
cd ~/Projects/your-project
~/scripts/init-claude-mcp
claude mcp list
```

## Hardware Requirements

### Minimum
- **GPU**: AMD GPU with ROCm support (GFX 10.x+)
- **VRAM**: 8GB for 7B models
- **RAM**: 16GB system RAM
- **Disk**: 20GB for models and dependencies

### Recommended (Current Setup)
- **GPU**: AMD RX 6700 XT (12GB VRAM)
- **RAM**: 32GB system RAM
- **Disk**: NVMe SSD with 50GB+ free space
- **CPU**: Modern multi-core CPU (Ryzen 5000+)

## Completed Improvements (from "Future Enhancements")
- ✅ Integration with local models (Ollama + auto-pull)
- ✅ Configurable ollama models (qwen2.5-coder:7b, llama3.1:8b)
- ✅ Declarative MCP configuration for Claude CLI

## Future Enhancements
- [ ] Add more MCP servers (GitHub, GitLab, Brave Search, database access)
- [ ] Optional larger models (qwen2.5-coder:14b, llama3.1:70b)
- [ ] Rate limiting and security policies for MCP servers
- [ ] Custom model configuration options
- [ ] Integration with DeepSeek Coder models
- [ ] Voice interaction with Whisper + TTS
- [ ] Multi-GPU support

## References
- [MCP Journal](https://github.com/kcalvelli/mcp-journal) - Custom MCP server for journalctl
- [nix-ai-tools](https://github.com/numtide/nix-ai-tools) - AI development tools (copilot, claude)
- [Ollama](https://ollama.ai) - Local LLM inference
- [OpenWebUI](https://github.com/open-webui/open-webui) - Web interface for Ollama
- [Model Context Protocol](https://modelcontextprotocol.io) - MCP specification
