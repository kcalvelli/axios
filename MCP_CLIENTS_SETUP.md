# MCP Client Options Setup

Two ways to use your MCP servers with local Ollama models have been configured in your NixOS setup.

## Quick Start

After running `nixos-rebuild switch` and `home-manager switch`, you'll have access to:

1. **mcp-chat** - Simple CLI (ready to use)
2. **LM Studio** - Desktop app (ready to use)

---

## 1. mcp-chat (Custom CLI) ✅ Ready

**Location:** Packaged in `/home/keith/Projects/axios/pkgs/mcp-chat/`

### Usage

```bash
# Start chat with default model (qwen2.5-coder:7b)
mcp-chat

# Use a different model
mcp-chat --model llama3.1:8b

# Custom Ollama/mcpo URLs
mcp-chat --ollama-url http://localhost:11434 --mcpo-url http://localhost:8000
```

### Features
- ✅ Works immediately after rebuild
- ✅ Uses all 5 MCP servers via mcpo
- ✅ Color-coded output
- ✅ Shows tool calls and results
- ✅ Works with any Ollama model that supports tools
- ✅ Properly packaged as a Nix application

### Testing
```bash
# Make sure mcpo is running
systemctl --user status mcpo

# Try asking it to use a tool:
mcp-chat
> Search NixOS packages for python
> Show me recent systemd logs
```

---

## 2. LM Studio (Desktop App) ✅ Ready

**Location:** Installed via `/home/keith/Projects/axios/home/ai/default.nix`

### Launch

```bash
# LM Studio should be available in your application menu
# Or launch from terminal:
lmstudio
```

### MCP Configuration

LM Studio has native MCP support. To configure your servers:

1. Launch LM Studio
2. Go to Settings → Developer → MCP Servers
3. Add each server manually or create a config file

**Example MCP config for LM Studio:**
```json
{
  "mcpServers": {
    "journal": {
      "command": "/run/current-system/sw/bin/mcp-journal",
      "args": []
    },
    "mcp-nixos": {
      "command": "nix",
      "args": ["run", "github:utensils/mcp-nixos", "--"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp", "/home/keith/Projects"]
    }
  }
}
```

### Advantages
- Native MCP support (not via mcpo - direct stdio communication)
- Professional desktop UI
- Easy model management
- Built-in MCP debugging tools
- Best tool calling support
- Model download and management interface

---

## Comparison

| Feature | mcp-chat | LM Studio |
|---------|----------|-----------|
| **Setup** | ✅ Ready | ✅ Ready |
| **Interface** | CLI | Desktop GUI |
| **MCP Method** | via mcpo (REST) | Native (stdio) |
| **Tool Support** | Good | Best |
| **Cost** | Free | Free |
| **Updates** | Nix rebuild | Auto-update |
| **Packaging** | Custom | nixpkgs |

---

## Troubleshooting

### mcp-chat

**Problem:** No tools available
```bash
# Check mcpo status
systemctl --user status mcpo
journalctl --user -u mcpo.service -f

# Restart mcpo
systemctl --user restart mcpo
```

**Problem:** Model doesn't use tools
- Try qwen2.5-coder:7b instead of llama3.1:8b
- Be explicit: "Use the journal tool to show me logs"

### LM Studio

**Problem:** MCP servers not detected
- Verify MCP config in Settings → Developer → MCP Servers
- Check LM Studio logs (Help → Show Logs)
- Ensure npx and nix commands are in PATH
- Restart LM Studio after config changes

**Problem:** npx commands fail
- LM Studio may need explicit PATH
- Try absolute paths instead: `/run/current-system/sw/bin/npx`

---

## Files Modified

### System Level
- No changes to system modules

### Home Manager (`/home/keith/Projects/axios/home/ai/`)
- `default.nix` - Added lmstudio package
- `mcp.nix` - Updated to use packaged mcp-chat

### Packages (`/home/keith/Projects/axios/pkgs/`)
- `mcp-chat/` - **New:** Properly packaged Python CLI application
  - `default.nix` - Nix package definition
  - `mcp-chat.py` - Python implementation

---

## Next Steps

1. **Rebuild your system:**
   ```bash
   sudo nixos-rebuild switch
   home-manager switch
   ```

2. **Try mcp-chat first** (quickest to test):
   ```bash
   mcp-chat
   ```

3. **Launch LM Studio** for the best desktop experience:
   ```bash
   lmstudio
   ```
   Then configure MCP servers in Settings → Developer → MCP Servers

---

## Recommendations

- **For quick testing:** Use `mcp-chat`
- **For regular use:** Use **LM Studio** (best tool support, native MCP, professional UI)
- **For scripts/automation:** Use `mcp-chat` (easier to script and integrate)

**Best model for tools:** `qwen2.5-coder:7b` has excellent tool calling capabilities.

---

## Architecture Notes

### mcp-chat Architecture
```
User Input → mcp-chat (Python) → Ollama (tool decisions)
                ↓
              mcpo (REST API)
                ↓
        MCP Servers (stdio)
```

### LM Studio Architecture
```
User Input → LM Studio → Ollama (tool decisions)
                ↓
        MCP Servers (stdio, direct)
```

**Key Difference:** LM Studio talks directly to MCP servers via stdio protocol, while mcp-chat goes through mcpo's REST API layer. This makes LM Studio more efficient and reliable for MCP tool calling.
