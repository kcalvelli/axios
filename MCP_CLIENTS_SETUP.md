# MCP Client Setup Guide

This guide shows how to use the MCP (Model Context Protocol) servers provided by axios with local AI models.

## What axios provides

When you enable the axios AI module in your host configuration:

```nix
# In your host config (e.g., hosts/mycomputer.nix)
{
hostConfig = {
hostname = "mycomputer";
# ... other config ...

modules = {
# ... other modules ...
ai = true;  # Enable AI tools and services
};
};
}
```

You automatically get:
- **mcp-journal** - MCP server for systemd journal access (installed in user PATH)
- **mcp-chat** - CLI tool for testing MCP servers with Ollama
- **LM Studio** - Desktop app with native MCP support
- **Claude CLI** - Pre-configured with mcp-journal and other MCP servers
- **mcpo** - User service that exposes MCP servers as REST APIs
- **Ollama** - Local LLM inference server
- **OpenWebUI** - Web interface for Ollama

## Quick Start

After enabling axios AI module and running `home-manager switch`:

1. **mcp-chat** - Test MCP tools from CLI
2. **LM Studio** - Professional desktop experience

---

## 1. mcp-chat (Custom CLI) ✅ Ready

**Location:** Packaged in `pkgs/mcp-chat/`

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

**Location:** Installed via `home/ai/default.nix`

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
"command": "mcp-journal",
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
"args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp", "/home/myuser/Projects"]
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
- Ensure `mcp-journal`, `npx`, and `nix` commands are in PATH
- After `home-manager switch`, these should be available in your user PATH
- Test with: `which mcp-journal npx nix`
- Restart LM Studio after config changes

**Problem:** Command not found errors
- Make sure you've run `home-manager switch` after adding MCP servers
- Verify the binaries are in your PATH: `echo $PATH | grep -o '/home/[^:]*\.nix-profile/bin'`
- LM Studio inherits your shell's PATH, so commands should work if they work in your terminal

---

## Adding Custom MCP Servers

axios provides `mcp-journal` out of the box. To add your own MCP servers, configure them in your user file:

**Step 1: Add flake input (if needed)**

If your MCP server is a flake, add it to your `flake.nix`:
```nix
{
inputs = {
axios.url = "github:kcalvelli/axios";
nixpkgs.follows = "axios/nixpkgs";

# Add your MCP server input
my-mcp-server.url = "github:someone/my-mcp-server";
};

outputs = { self, axios, my-mcp-server, ... }: {
# Pass inputs to your user module
nixosConfigurations.myhost = axios.lib.mkSystem {
# ... your config ...
};
};
}
```

**Step 2: Install in your user file**

In your user module (e.g., `user.nix`):

```nix
{ self, config, ... }:
let
username = "myuser";
in
{
# ... user account config ...

# Home Manager configuration
home-manager.users.${username} = { pkgs, ... }: {
# ... other home config ...

# Add custom MCP servers to home.packages
home.packages = [
# Access flake input through self.inputs
self.inputs.my-mcp-server.packages.${pkgs.stdenv.hostPlatform.system}.default

# Or use packages from nixpkgs
# pkgs.some-other-mcp-server
];
};
}
```

**Step 3: Use in MCP clients**

Once installed (after `home-manager switch`), the binary will be in your PATH. Configure it in:

**LM Studio:**
```json
{
"mcpServers": {
"my-server": {
"command": "my-mcp-server-binary",
"args": []
}
}
}
```

**Claude CLI:** Create `.mcp.json` in your project directory or configure user-scoped with `claude mcp add`

**Example:** See a complete user configuration example in the [axios examples directory](https://github.com/kcalvelli/axios/tree/master/examples/minimal-flake).

**Pattern**: Install MCP servers as user packages (via `home.packages` in your user module) so they're available in PATH for all MCP clients.

---

## What's included in axios

### NixOS Module (`nixosModules.ai`)
- Ollama service configuration
- OpenWebUI with Tailscale integration
- System-level AI packages (whisper-cpp, claude-code, copilot-cli)
- Systemd journal access for mcp-journal

### Home-Manager Module (`homeModules.ai`)
- **mcp-journal** - Systemd journal MCP server (in your PATH)
- **mcp-chat** - Custom CLI for testing MCP+Ollama integration
- **LM Studio** - Desktop app with MCP support
- **Claude CLI** - Pre-configured MCP servers
- **mcpo** - User service exposing MCP servers as REST APIs

All MCP servers provided by axios are automatically available in your PATH after importing the module.

---

## Next Steps

1. **Enable axios AI module in your host configuration:**

In your host config file (e.g., `hosts/mycomputer.nix`):
```nix
{
hostConfig = {
hostname = "mycomputer";
system = "x86_64-linux";
formFactor = "desktop"; # or "laptop"

modules = {
system = true;
desktop = true;
# ... other modules ...
ai = true;  # Enable AI module
};

homeProfile = "workstation";  # or "laptop"
userModulePath = self.outPath + "/user.nix";
diskConfigPath = ./disks.nix;
};
}
```

2. **Rebuild your system:**
```bash
sudo nixos-rebuild switch --flake /path/to/your/config
```

3. **Try mcp-chat** (quickest to test):
```bash
mcp-chat
# Ask: "Search NixOS packages for python"
# Ask: "Show me recent systemd logs"
```

4. **Launch LM Studio** for the best desktop experience:
```bash
lmstudio
```
Then configure MCP servers in Settings → Developer → MCP Servers (use example config above)

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
