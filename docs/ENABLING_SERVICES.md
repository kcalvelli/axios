# Enabling Services in axiOS

Services are enabled in your host configuration file (`~/.config/nixos_config/hosts/yourhost.nix`).

## Quick Reference

### AI Services (OpenWebUI + Ollama + Claude CLI)

**In your host config:**
```nix
modules = {
  ai = true;  # Enable AI module
  # ... other modules
};

# Configure your Tailscale domain for web access
extraConfig = {
  networking.tailscale.domain = "tail1234ab.ts.net";  # Your Tailscale domain
};
```

**What you get:**
- OpenWebUI: `http://yourhost.tail1234ab.ts.net/` (web interface via Tailscale)
- Ollama API: `http://localhost:11434/` (local access)
- Local models auto-downloaded: `qwen2.5-coder:7b`, `llama3.1:8b`
- AI CLI tools: `claude`, `copilot`, `whisper-cli`
- 5 MCP servers configured for Claude CLI

**Note:** Find your Tailscale domain in the Tailscale admin console under DNS settings (e.g., `tail1234ab.ts.net`).

**Using Ollama:**
```bash
# Direct Ollama CLI (no API key needed!)
ollama run qwen2.5-coder:7b
ollama run llama3.1:8b

# Or use OpenWebUI at http://yourhost.tail1234ab.ts.net/ (if Tailscale domain configured)
```

**Using Claude CLI with MCP servers:**
```bash
# After first rebuild, run setup script once:
~/scripts/setup-claude-mcp-user

# Then use Claude from any directory!
claude

# Verify servers are available
claude mcp list
```

**MCP Servers Available:**
- journal - System log access
- mcp-nixos - NixOS package search
- sequential-thinking - Enhanced reasoning
- context7 - Context management
- filesystem - File operations

**Note:** Run `~/scripts/setup-claude-mcp-user` once after enabling the AI module. The script is idempotent and safe to re-run.

---

### Home Assistant

**In your host config:**
```nix
extraConfig = {
  services.hass.enable = true;
};
```

**Access:**
- `http://localhost:8123/` (local)
- `http://yourhost.tail1234ab.ts.net:8123/` (via Tailscale, if configured)

**Features:**
- Voice support ready (Wyoming containers disabled by default)
- Matter/Thread support
- Google integrations
- Smart home device support (TP-Link, SmartThings, Tuya, etc.)

---

### ntopng (Network Monitoring)

**In your host config:**
```nix
extraConfig = {
  services.ntop.enable = true;
};
```

**Access:**
- `http://localhost:3000/` (local)
- `http://yourhost.tail1234ab.ts.net:3000/` (via Tailscale, if configured)

**What it does:**
- Network traffic monitoring
- Protocol analysis
- Top talkers and hosts
- Historical data

---

### MQTT Broker

**In your host config:**
```nix
extraConfig = {
  services.mqtt.enable = true;
};
```

**Access:**
- Localhost only: `127.0.0.1:1883`
- Not exposed to network (security)

**Use for:**
- Home automation
- IoT device communication
- Smart home integrations

---

## Complete Example

Here's a full host config with all services enabled:

```nix
# hosts/edge.nix
{ lib, userModulePath, ... }:
{
  hostConfig = {
    hostname = "edge";
    system = "x86_64-linux";
    formFactor = "desktop";
    
    hardware = {
      vendor = "msi";
      cpu = "amd";
      gpu = "amd";
      hasSSD = true;
      isLaptop = false;
    };
    
    # Enable module groups
    modules = {
      system = true;
      desktop = true;
      development = true;
      services = true;      # Required for service modules
      graphics = true;
      networking = true;
      users = true;
      virt = true;
      gaming = true;
      ai = true;            # AI services (OpenWebUI, Ollama, Claude)
    };
    
    # Virtualization
    virt = {
      libvirt.enable = true;
      containers.enable = true;
    };
    
    homeProfile = "workstation";
    userModulePath = userModulePath;
    
    # Enable individual services
    extraConfig = {
      # Home automation
      services.hass.enable = true;
      
      # Network monitoring
      services.ntop.enable = true;
      
      # MQTT broker
      services.mqtt.enable = true;
      
      # System settings
      time.hardwareClockInLocalTime = true;
      boot.lanzaboote.enableSecureBoot = true;
    };
    
    diskConfigPath = ./edge/disks.nix;
  };
}
```

## Applying Changes

After editing your host config:

```bash
cd ~/.config/nixos_config
nix flake update axios  # Pull latest changes
rebuild-switch          # Apply configuration
```

## Checking Service Status

```bash
# Check if a service is running
systemctl status open-webui
systemctl status home-assistant
systemctl status ntopng
systemctl status ollama

# View service logs
journalctl -u open-webui -f
journalctl -u home-assistant -f
```

## Service Port Reference

All services use port-based access for simplicity and compatibility with Tailscale.

### Current Service Ports

| Service | Port | URL | Notes |
|---------|------|-----|-------|
| **OpenWebUI** | 8080 | `http://yourhost.tail1234ab.ts.net/` | Main domain via Caddy |
| **Ollama** | 11434 | `http://yourhost.tail1234ab.ts.net:11434/` | Direct API access |
| **Home Assistant** | 8123 | `http://yourhost.tail1234ab.ts.net:8123/` | When enabled |
| **ntopng** | 3000 | `http://yourhost.tail1234ab.ts.net:3000/` | When enabled |
| **MQTT** | 1883 | N/A | Localhost only |

### Why Port-Based Access?

✅ **Simple** - No path rewriting or subdomain DNS issues
✅ **Compatible** - Works with all applications regardless of base path support
✅ **Tailscale-friendly** - No MagicDNS limitations
✅ **Secure** - Tailscale handles authentication and encryption
✅ **Flexible** - Each service is independent

### Adding New Services

1. Configure service to listen on localhost or 0.0.0.0
2. Open firewall port if needed
3. Document port in this section
4. Access via `http://yourhost.tail1234ab.ts.net:PORT/`

**Exception:** Services that don't support base paths and need clean URLs can use Caddy on the main domain (like OpenWebUI currently does).

## Module Requirements

- **AI services** require `modules.ai = true`
- **Other services** require `modules.services = true`
- **Services are configured in** `extraConfig` section
