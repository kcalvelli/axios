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
```

**What you get:**
- OpenWebUI: `http://edge.taile0fb4.ts.net/` (web interface)
- Ollama API: `http://edge.taile0fb4.ts.net:11434/`
- Local models auto-downloaded: `qwen2.5-coder:7b`, `llama3.1:8b`
- AI CLI tools: `claude`, `copilot`, `whisper-cli`
- 5 MCP servers configured for Claude CLI

**Using Ollama:**
```bash
# Direct Ollama CLI (no API key needed!)
ollama run qwen2.5-coder:7b
ollama run llama3.1:8b

# Or use OpenWebUI at http://edge.taile0fb4.ts.net/
```

**Using Claude CLI with MCP servers:**
```bash
# MCP servers automatically configured system-wide!
# No setup needed - just run claude from any directory
claude

# Verify servers are available
claude mcp list -s user
```

**MCP Servers Automatically Available:**
- journal - System log access
- mcp-nixos - NixOS package search
- sequential-thinking - Enhanced reasoning
- context7 - Context management
- filesystem - File operations

**Note:** MCP servers are configured automatically during Home Manager rebuild. You can use Claude from any directory!

---

### Home Assistant

**In your host config:**
```nix
extraConfig = {
  services.hass.enable = true;
};
```

**Access:**
- `http://edge.taile0fb4.ts.net:8123/`

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
- `http://edge.taile0fb4.ts.net:3000/`

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

## Port Reference

See [SERVICE_PORTS.md](./SERVICE_PORTS.md) for complete port listing.

## Module Requirements

- **AI services** require `modules.ai = true`
- **Other services** require `modules.services = true`
- **Services are configured in** `extraConfig` section
